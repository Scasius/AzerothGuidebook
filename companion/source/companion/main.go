package main

import (
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"
)

var version = "dev"
var defaultFeedURL = ""

const protocolVersion = 1
const requestPrefix = "AGBREFRESH1"

//go:embed seed/manifest.json seed/packs/*/*.json
var seedFS embed.FS

type Config struct {
	SchemaVersion int    `json:"schema_version"`
	AddonDir      string `json:"addon_dir"`
	RetailDir     string `json:"retail_dir"`
	FeedURL       string `json:"feed_url"`
	PollSeconds   int    `json:"poll_seconds"`
	InstalledAt   string `json:"installed_at"`
}

type Request struct {
	RequestID    string
	Scope        string
	SpecID       int
	SourceID     string
	ContextKey   string
	GuideTab     string
	AddonVersion string
	Raw          string
}

type Manifest struct {
	SchemaVersion int             `json:"schema_version"`
	GeneratedAt   string          `json:"generated_at"`
	PackCount     int             `json:"pack_count"`
	Packs         []ManifestEntry `json:"packs"`
}

type ManifestEntry struct {
	SourceID      string `json:"source_id"`
	SpecID        int    `json:"spec_id"`
	PackID        string `json:"pack_id"`
	File          string `json:"file"`
	SHA256        string `json:"sha256"`
	ContentSHA256 string `json:"content_sha256"`
	GeneratedAt   string `json:"generated_at"`
	ReviewState   string `json:"review_state"`
}

type Pack struct {
	SchemaVersion        int    `json:"schema_version"`
	PackID               string `json:"pack_id"`
	SourceID             string `json:"source_id"`
	SpecID               int    `json:"spec_id"`
	ReviewState          string `json:"review_state"`
	GeneratedAt          string `json:"generated_at"`
	BaselineAddonVersion string `json:"baseline_addon_version"`
	ContentSHA256        string `json:"content_sha256"`
	LuaChunk             string `json:"lua_chunk"`
	SeedOnly             bool   `json:"seed_only"`
}

type EntryState struct {
	State           string `json:"state"`
	UpdatedAt       string `json:"updated_at"`
	RequestID       string `json:"request_id"`
	Details         string `json:"details"`
	PackID          string `json:"pack_id,omitempty"`
	PackGeneratedAt string `json:"pack_generated_at,omitempty"`
	FeedMode        string `json:"feed_mode,omitempty"`
	ContentSHA256   string `json:"content_sha256,omitempty"`
}

type AppliedPack struct {
	SourceID        string `json:"source_id"`
	SpecID          int    `json:"spec_id"`
	PackID          string `json:"pack_id"`
	ContentSHA256   string `json:"content_sha256"`
	LuaChunk        string `json:"lua_chunk"`
	AppliedAt       string `json:"applied_at"`
	PackGeneratedAt string `json:"pack_generated_at,omitempty"`
}

type LastRun struct {
	RequestID   string `json:"request_id"`
	State       string `json:"state"`
	CompletedAt string `json:"completed_at"`
	Summary     string `json:"summary"`
}

type State struct {
	SchemaVersion     int                    `json:"schema_version"`
	HandledRequestIDs []string               `json:"handled_request_ids"`
	Entries           map[string]EntryState  `json:"entries"`
	AppliedPacks      map[string]AppliedPack `json:"applied_packs"`
	LastRun           *LastRun               `json:"last_run,omitempty"`
	History           []RunHistory           `json:"history,omitempty"`
}

type Feed struct {
	Mode       string
	Manifest   Manifest
	Index      map[string]ManifestEntry
	BaseURL    *url.URL
	RemoteGood bool
}

var requestRE = regexp.MustCompile(`\["sourceRefreshRequest"\]\s*=\s*"([^"\r\n]*)"`)

func utcNow() string                     { return time.Now().UTC().Truncate(time.Second).Format(time.RFC3339) }
func key(source string, spec int) string { return fmt.Sprintf("%s:%d", source, spec) }
func hashBytes(b []byte) string          { h := sha256.Sum256(b); return hex.EncodeToString(h[:]) }

func main() {
	configPath := flag.String("config", "", "path to companion config.json")
	once := flag.Bool("once", false, "process pending requests once, then exit")
	flag.Bool("background", false, "background mode (accepted for startup registration)")
	flag.Parse()

	exe, _ := os.Executable()
	base := filepath.Dir(exe)
	if *configPath == "" {
		*configPath = filepath.Join(base, "config.json")
	}
	cfg, err := loadConfig(*configPath)
	if err != nil {
		fatalToFile(base, fmt.Errorf("load config: %w", err))
	}
	if strings.TrimSpace(cfg.FeedURL) == "" && strings.TrimSpace(defaultFeedURL) != "" {
		cfg.FeedURL = strings.TrimSpace(defaultFeedURL)
	}
	if cfg.PollSeconds <= 0 {
		cfg.PollSeconds = 2
	}

	if err := os.MkdirAll(base, 0755); err != nil {
		fatalToFile(base, err)
	}
	lf, err := os.OpenFile(filepath.Join(base, "companion.log"), os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		panic(err)
	}
	defer lf.Close()
	log.SetOutput(lf)
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)
	log.Printf("Azeroth Guidebook Companion %s starting; addon=%s retail=%s", version, cfg.AddonDir, cfg.RetailDir)

	if err := validateConfig(cfg); err != nil {
		_ = writeCompanionStatus(cfg, "error", "", err.Error())
		log.Fatal(err)
	}

	releaseLock, err := acquireLock(base)
	if err != nil {
		log.Printf("companion already running or lock unavailable: %v", err)
		return
	}
	defer releaseLock()

	statePath := filepath.Join(base, "state.json")
	st, err := loadState(statePath)
	if err != nil {
		log.Printf("state reset after read error: %v", err)
		st = newState()
	}
	if err := rebuildOverrides(cfg.AddonDir, st); err != nil {
		log.Printf("override hydration failed: %v", err)
	}
	if err := writeRuntimeState(cfg.AddonDir, st); err != nil {
		log.Printf("runtime state hydration failed: %v", err)
	}

	feedMode := "bundled"
	_ = writeCompanionStatus(cfg, "running", feedMode, "")
	lastHeartbeat := time.Now()

	stopPath := filepath.Join(base, "stop.request")
	for {
		if _, err := os.Stat(stopPath); err == nil {
			log.Printf("stop request detected; shutting down cleanly")
			_ = os.Remove(stopPath)
			break
		}
		if time.Since(lastHeartbeat) >= 20*time.Second {
			_ = writeCompanionStatus(cfg, "running", feedMode, "")
			_ = touchLock(base)
			lastHeartbeat = time.Now()
		}

		requests, err := scanRequests(cfg.RetailDir, handledSet(st.HandledRequestIDs))
		if err != nil {
			log.Printf("scan requests: %v", err)
		}
		for _, req := range requests {
			log.Printf("processing request %s scope=%s spec=%d source=%s", req.RequestID, req.Scope, req.SpecID, req.SourceID)
			mode, err := processRequest(cfg, &st, req)
			if mode != "" {
				feedMode = mode
			}
			if err != nil {
				log.Printf("request %s failed: %v", req.RequestID, err)
				now := utcNow()
				st.LastRun = &LastRun{RequestID: req.RequestID, State: "failed", CompletedAt: now, Summary: "refresh processing failed; accepted data retained"}
				st.HandledRequestIDs = appendLimited(st.HandledRequestIDs, req.RequestID, 200)
				_ = saveState(statePath, st)
				_ = writeRuntimeState(cfg.AddonDir, st)
				_ = writeCompanionStatus(cfg, "running", feedMode, err.Error())
				if nerr := notify("Refresh failed; accepted data was retained. Open Sources after /reload for status."); nerr != nil {
					log.Printf("notification launch failed: %v", nerr)
				}
				continue
			}
			if st.LastRun != nil {
				log.Printf("request %s completed state=%s summary=%s feed=%s", req.RequestID, st.LastRun.State, st.LastRun.Summary, feedMode)
			}
			_ = writeCompanionStatus(cfg, "running", feedMode, "")
		}

		if *once {
			break
		}
		time.Sleep(time.Duration(cfg.PollSeconds) * time.Second)
	}
}

func loadConfig(path string) (Config, error) {
	var c Config
	b, err := os.ReadFile(path)
	if err != nil {
		return c, err
	}
	if err := json.Unmarshal(b, &c); err != nil {
		return c, err
	}
	c.AddonDir, _ = filepath.Abs(c.AddonDir)
	c.RetailDir, _ = filepath.Abs(c.RetailDir)
	return c, nil
}

func validateConfig(c Config) error {
	if _, err := os.Stat(filepath.Join(c.AddonDir, "AzerothGuidebook.toc")); err != nil {
		return fmt.Errorf("addon not found at %s", c.AddonDir)
	}
	if _, err := os.Stat(filepath.Join(c.RetailDir, "WTF")); err != nil {
		return fmt.Errorf("Retail WTF folder not found at %s", c.RetailDir)
	}
	return nil
}

func fatalToFile(base string, err error) {
	_ = os.MkdirAll(base, 0755)
	_ = os.WriteFile(filepath.Join(base, "companion-startup-error.txt"), []byte(err.Error()+"\n"), 0644)
	os.Exit(2)
}

func acquireLock(base string) (func(), error) {
	p := filepath.Join(base, "companion.lock")
	if info, err := os.Stat(p); err == nil && time.Since(info.ModTime()) < 90*time.Second {
		pid := readLockPID(p)
		if pid > 0 && companionPIDRunning(pid) {
			return nil, errors.New("active lock exists")
		}
		// The lock is fresh but its process is gone (for example after setup
		// force-replaces a running build). Recover immediately instead of
		// waiting for the 90-second stale-lock window.
		_ = os.Remove(p)
	} else {
		_ = os.Remove(p)
	}
	f, err := os.OpenFile(p, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0644)
	if err != nil {
		return nil, err
	}
	_, _ = fmt.Fprintf(f, "%d\n", os.Getpid())
	_ = f.Close()
	return func() { _ = os.Remove(p) }, nil
}

func readLockPID(path string) int {
	b, err := os.ReadFile(path)
	if err != nil {
		return 0
	}
	pid, _ := strconv.Atoi(strings.TrimSpace(string(b)))
	return pid
}

func companionPIDRunning(pid int) bool {
	if pid <= 0 {
		return false
	}
	running, err := processPIDMatchesName(pid, "AzerothGuidebookCompanion.exe")
	if err != nil {
		// Lock acquisition is deliberately conservative if process enumeration
		// itself fails: do not start a second background instance.
		return true
	}
	return running
}
func touchLock(base string) error {
	now := time.Now()
	return os.Chtimes(filepath.Join(base, "companion.lock"), now, now)
}

func newState() State {
	return State{SchemaVersion: 2, Entries: map[string]EntryState{}, AppliedPacks: map[string]AppliedPack{}, History: []RunHistory{}}
}
func loadState(path string) (State, error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return newState(), nil
	}
	var st State
	b, err := os.ReadFile(path)
	if err != nil {
		return st, err
	}
	if err := json.Unmarshal(b, &st); err != nil {
		return st, err
	}
	if st.Entries == nil {
		st.Entries = map[string]EntryState{}
	}
	if st.AppliedPacks == nil {
		st.AppliedPacks = map[string]AppliedPack{}
	}
	st.SchemaVersion = 2
	if st.History == nil {
		st.History = []RunHistory{}
	}
	return st, nil
}
func saveState(path string, st State) error {
	b, _ := json.MarshalIndent(st, "", "  ")
	b = append(b, '\n')
	return atomicWrite(path, b)
}
func appendLimited(in []string, v string, n int) []string {
	out := make([]string, 0, len(in)+1)
	seen := map[string]bool{}
	for _, x := range in {
		if x != "" && !seen[x] {
			seen[x] = true
			out = append(out, x)
		}
	}
	if !seen[v] {
		out = append(out, v)
	}
	if len(out) > n {
		out = out[len(out)-n:]
	}
	return out
}
func handledSet(in []string) map[string]bool {
	m := map[string]bool{}
	for _, v := range in {
		m[v] = true
	}
	return m
}

func parseRequest(payload string) (Request, error) {
	var r Request
	parts := strings.Split(payload, "|")
	if len(parts) != 8 || parts[0] != requestPrefix {
		return r, errors.New("unsupported refresh request")
	}
	sid, err := strconv.Atoi(parts[3])
	if err != nil {
		return r, fmt.Errorf("invalid spec id")
	}
	r = Request{RequestID: parts[1], Scope: parts[2], SpecID: sid, SourceID: parts[4], ContextKey: parts[5], GuideTab: parts[6], AddonVersion: parts[7], Raw: payload}
	if r.Scope != "source" && r.Scope != "spec" && r.Scope != "all" {
		return r, errors.New("invalid scope")
	}
	if r.Scope == "source" && r.SourceID != "wowhead" && r.SourceID != "icy-veins" && r.SourceID != "ugg" {
		return r, errors.New("invalid source")
	}
	if r.Scope != "source" && r.SourceID != "all" {
		return r, errors.New("invalid all-source marker")
	}
	if r.Scope == "all" && r.SpecID != 0 {
		return r, errors.New("all scope requires spec 0")
	}
	if r.Scope != "all" && r.SpecID <= 0 {
		return r, errors.New("spec/source scope requires spec id")
	}
	return r, nil
}

type reqAtPath struct {
	Req   Request
	Path  string
	Stamp int64
	Mtime time.Time
}

func scanRequests(retail string, handled map[string]bool) ([]Request, error) {
	paths, err := filepath.Glob(filepath.Join(retail, "WTF", "Account", "*", "SavedVariables", "AzerothGuidebook.lua"))
	if err != nil {
		return nil, err
	}
	rows := []reqAtPath{}
	for _, p := range paths {
		b, err := os.ReadFile(p)
		if err != nil {
			continue
		}
		m := requestRE.FindSubmatch(b)
		if len(m) != 2 {
			continue
		}
		r, err := parseRequest(string(m[1]))
		if err != nil || handled[r.RequestID] {
			continue
		}
		stamp, _ := strconv.ParseInt(strings.SplitN(r.RequestID, "-", 2)[0], 10, 64)
		info, _ := os.Stat(p)
		var mt time.Time
		if info != nil {
			mt = info.ModTime()
		}
		rows = append(rows, reqAtPath{r, p, stamp, mt})
	}
	sort.Slice(rows, func(i, j int) bool {
		if rows[i].Stamp == rows[j].Stamp {
			return rows[i].Mtime.Before(rows[j].Mtime)
		}
		return rows[i].Stamp < rows[j].Stamp
	})
	out := make([]Request, len(rows))
	for i, row := range rows {
		out[i] = row.Req
	}
	return out, nil
}

func loadSeedFeed() (Feed, error) {
	b, err := seedFS.ReadFile("seed/manifest.json")
	if err != nil {
		return Feed{}, err
	}
	var m Manifest
	if err := json.Unmarshal(b, &m); err != nil {
		return Feed{}, err
	}
	f := Feed{Mode: "bundled", Manifest: m, Index: map[string]ManifestEntry{}}
	for _, e := range m.Packs {
		f.Index[key(e.SourceID, e.SpecID)] = e
	}
	return f, nil
}

func loadRemoteFeed(feedURL string) (Feed, error) {
	u, err := url.Parse(feedURL)
	if err != nil {
		return Feed{}, err
	}
	client := &http.Client{Timeout: 12 * time.Second}
	req, _ := http.NewRequest("GET", u.String(), nil)
	req.Header.Set("User-Agent", "AzerothGuidebookCompanion/"+version)
	resp, err := client.Do(req)
	if err != nil {
		return Feed{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return Feed{}, fmt.Errorf("manifest HTTP %d", resp.StatusCode)
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return Feed{}, err
	}
	var m Manifest
	if err := json.Unmarshal(b, &m); err != nil {
		return Feed{}, err
	}
	f := Feed{Mode: "remote", Manifest: m, Index: map[string]ManifestEntry{}, BaseURL: u, RemoteGood: true}
	for _, e := range m.Packs {
		f.Index[key(e.SourceID, e.SpecID)] = e
	}
	return f, nil
}

func loadPack(f Feed, e ManifestEntry) (Pack, error) {
	var raw []byte
	var err error
	if f.Mode == "bundled" {
		raw, err = seedFS.ReadFile(filepath.ToSlash(filepath.Join("seed", e.File)))
	} else {
		ref, er := url.Parse(e.File)
		if er != nil {
			return Pack{}, er
		}
		u := f.BaseURL.ResolveReference(ref)
		client := &http.Client{Timeout: 20 * time.Second}
		req, _ := http.NewRequest("GET", u.String(), nil)
		req.Header.Set("User-Agent", "AzerothGuidebookCompanion/"+version)
		resp, er := client.Do(req)
		if er != nil {
			return Pack{}, er
		}
		defer resp.Body.Close()
		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			return Pack{}, fmt.Errorf("pack HTTP %d", resp.StatusCode)
		}
		raw, err = io.ReadAll(io.LimitReader(resp.Body, 32<<20))
	}
	if err != nil {
		return Pack{}, err
	}
	if e.SHA256 != "" && !strings.EqualFold(hashBytes(raw), e.SHA256) {
		return Pack{}, errors.New("pack file sha256 mismatch")
	}
	var p Pack
	if err := json.Unmarshal(raw, &p); err != nil {
		return Pack{}, err
	}
	if p.SourceID != e.SourceID || p.SpecID != e.SpecID || p.PackID != e.PackID {
		return Pack{}, errors.New("pack identity mismatch")
	}
	if p.ReviewState != "validated" || e.ReviewState != "validated" {
		return Pack{}, errors.New("pack is not validated")
	}
	if !strings.EqualFold(hashBytes([]byte(p.LuaChunk)), p.ContentSHA256) {
		return Pack{}, errors.New("pack content sha256 mismatch")
	}
	return p, nil
}

func processRequest(cfg Config, st *State, req Request) (string, error) {
	seed, err := loadSeedFeed()
	if err != nil {
		return "bundled", err
	}
	chosen := seed
	remoteErr := ""
	if strings.TrimSpace(cfg.FeedURL) != "" {
		if r, er := loadRemoteFeed(cfg.FeedURL); er == nil {
			chosen = r
		} else {
			remoteErr = er.Error()
			log.Printf("remote feed unavailable; using bundled seed: %v", er)
		}
	}
	specIDs := selectedSpecs(req, seed.Manifest)
	sources := selectedSources(req)
	counts := map[string]int{"applied": 0, "no_change": 0, "review_required": 0, "failed": 0}
	now := utcNow()
	packChanges := make([]PackChange, 0, len(specIDs)*len(sources))
	for _, sid := range specIDs {
		for _, src := range sources {
			k := key(src, sid)
			seedEntry, ok := seed.Index[k]
			if !ok {
				details := "no bundled baseline pack for source/spec"
				st.Entries[k] = EntryState{State: "failed", UpdatedAt: now, RequestID: req.RequestID, Details: details}
				counts["failed"]++
				packChanges = append(packChanges, PackChange{SourceID: src, SpecID: sid, State: "failed", Summary: details})
				continue
			}
			seedPack, er := loadPack(seed, seedEntry)
			if er != nil {
				details := "bundled baseline pack invalid: " + er.Error()
				st.Entries[k] = EntryState{State: "failed", UpdatedAt: now, RequestID: req.RequestID, Details: details}
				counts["failed"]++
				packChanges = append(packChanges, PackChange{SourceID: src, SpecID: sid, State: "failed", Summary: details})
				continue
			}
			currentHash := seedPack.ContentSHA256
			beforeChunk := seedPack.LuaChunk
			if prev, ok := st.Entries[k]; ok && prev.ContentSHA256 != "" {
				currentHash = prev.ContentSHA256
			}
			if applied, ok := st.AppliedPacks[k]; ok && strings.TrimSpace(applied.LuaChunk) != "" && strings.EqualFold(applied.ContentSHA256, currentHash) {
				beforeChunk = applied.LuaChunk
			} else if !strings.EqualFold(currentHash, seedPack.ContentSHA256) {
				// We know a newer local fingerprint exists, but an older state file may
				// not contain its Lua chunk. Keep the diff fail-closed rather than
				// comparing the new pack against an unrelated bundled baseline.
				beforeChunk = ""
			}

			candidateFeed := chosen
			candidateEntry, ok := chosen.Index[k]
			if !ok {
				candidateFeed = seed
				candidateEntry = seedEntry
			}
			candidate, er := loadPack(candidateFeed, candidateEntry)
			if er != nil {
				details := "validated pack rejected; accepted data retained: " + er.Error()
				st.Entries[k] = EntryState{State: "review_required", UpdatedAt: now, RequestID: req.RequestID, Details: details, FeedMode: candidateFeed.Mode, ContentSHA256: currentHash}
				counts["review_required"]++
				packChanges = append(packChanges, PackChange{SourceID: src, SpecID: sid, State: "review_required", Summary: details})
				continue
			}

			if candidateFeed.Mode == "bundled" && currentHash != seedPack.ContentSHA256 {
				details := "remote feed unavailable or did not publish this pack; retained newer validated local pack"
				if remoteErr != "" {
					details += " (" + remoteErr + ")"
				}
				st.Entries[k] = EntryState{State: "no_change", UpdatedAt: now, RequestID: req.RequestID, Details: details, PackID: st.Entries[k].PackID, FeedMode: "bundled-fallback", ContentSHA256: currentHash}
				counts["no_change"]++
				packChanges = append(packChanges, PackChange{SourceID: src, SpecID: sid, State: "no_change", Summary: "Newer validated local pack retained; published replacement unavailable."})
				continue
			}
			if strings.EqualFold(candidate.ContentSHA256, currentHash) {
				details := "validated source pack checked; no content change"
				if candidateFeed.Mode == "bundled" {
					details += " (bundled seed feed)"
				}
				st.Entries[k] = EntryState{State: "no_change", UpdatedAt: now, RequestID: req.RequestID, Details: details, PackID: candidate.PackID, PackGeneratedAt: candidate.GeneratedAt, FeedMode: candidateFeed.Mode, ContentSHA256: currentHash}
				counts["no_change"]++
				packChanges = append(packChanges, analyzePackChange(src, sid, "no_change", beforeChunk, candidate.LuaChunk))
				continue
			}
			if strings.TrimSpace(candidate.LuaChunk) == "" {
				details := "new validated pack has no installable Lua override; accepted data retained"
				st.Entries[k] = EntryState{State: "review_required", UpdatedAt: now, RequestID: req.RequestID, Details: details, PackID: candidate.PackID, PackGeneratedAt: candidate.GeneratedAt, FeedMode: candidateFeed.Mode, ContentSHA256: currentHash}
				counts["review_required"]++
				packChanges = append(packChanges, PackChange{SourceID: src, SpecID: sid, State: "review_required", Summary: details})
				continue
			}
			st.AppliedPacks[k] = AppliedPack{SourceID: src, SpecID: sid, PackID: candidate.PackID, ContentSHA256: candidate.ContentSHA256, LuaChunk: candidate.LuaChunk, AppliedAt: now, PackGeneratedAt: candidate.GeneratedAt}
			st.Entries[k] = EntryState{State: "applied", UpdatedAt: now, RequestID: req.RequestID, Details: "validated source pack applied; /reload required", PackID: candidate.PackID, PackGeneratedAt: candidate.GeneratedAt, FeedMode: candidateFeed.Mode, ContentSHA256: candidate.ContentSHA256}
			counts["applied"]++
			packChanges = append(packChanges, analyzePackChange(src, sid, "applied", beforeChunk, candidate.LuaChunk))
		}
	}
	if counts["applied"] > 0 {
		if err := rebuildOverrides(cfg.AddonDir, *st); err != nil {
			return chosen.Mode, err
		}
	}
	overall := "no_change"
	if counts["failed"] > 0 {
		overall = "failed"
	} else if counts["review_required"] > 0 {
		overall = "review_required"
	} else if counts["applied"] > 0 {
		overall = "applied"
	}
	summary := fmt.Sprintf("%d source pack(s) applied | %d no change | %d review required | %d failed", counts["applied"], counts["no_change"], counts["review_required"], counts["failed"])
	st.LastRun = &LastRun{RequestID: req.RequestID, State: overall, CompletedAt: now, Summary: summary}
	if req.Scope == "all" {
		packChanges = compactAllSourceChanges(packChanges)
	}
	run := RunHistory{
		RequestID:   req.RequestID,
		Scope:       req.Scope,
		SpecID:      req.SpecID,
		SourceID:    req.SourceID,
		GuideTab:    req.GuideTab,
		State:       overall,
		CompletedAt: now,
		Summary:     summary,
		Packs:       packChanges,
	}
	st.History = pushRunHistory(st.History, run, 5)
	st.HandledRequestIDs = appendLimited(st.HandledRequestIDs, req.RequestID, 200)
	statePath := filepath.Join(filepath.Dir(os.Args[0]), "state.json")
	if exe, er := os.Executable(); er == nil {
		statePath = filepath.Join(filepath.Dir(exe), "state.json")
	}
	if err := saveState(statePath, *st); err != nil {
		return chosen.Mode, err
	}
	if err := writeRuntimeState(cfg.AddonDir, *st); err != nil {
		return chosen.Mode, err
	}
	if err := notify(summary); err != nil {
		log.Printf("notification launch failed: %v", err)
	}
	return chosen.Mode, nil
}

func selectedSpecs(r Request, m Manifest) []int {
	if r.Scope != "all" {
		return []int{r.SpecID}
	}
	set := map[int]bool{}
	for _, e := range m.Packs {
		set[e.SpecID] = true
	}
	out := make([]int, 0, len(set))
	for v := range set {
		out = append(out, v)
	}
	sort.Ints(out)
	return out
}
func selectedSources(r Request) []string {
	if r.Scope == "source" {
		return []string{r.SourceID}
	}
	return []string{"wowhead", "icy-veins", "ugg"}
}

func rebuildOverrides(addon string, st State) error {
	keys := make([]string, 0, len(st.AppliedPacks))
	for k := range st.AppliedPacks {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	var b strings.Builder
	b.WriteString("local addonName, AGB = ...\n\n-- AUTO-GENERATED VALIDATED SOURCE OVERRIDES.\n-- Bundled guide data remains the fail-closed baseline.\n\n")
	for _, k := range keys {
		p := st.AppliedPacks[k]
		b.WriteString(p.LuaChunk)
		if !strings.HasSuffix(p.LuaChunk, "\n") {
			b.WriteByte('\n')
		}
		b.WriteByte('\n')
	}
	b.WriteString("AGB.LocalRefreshPack = {\n    schemaVersion = 1,\n    generatedAt = " + luaQuote(utcNow()) + ",\n    appliedPacks = " + strconv.Itoa(len(keys)) + ",\n}\n")
	return atomicWrite(filepath.Join(addon, "GuideRefreshOverrides.lua"), []byte(b.String()))
}

func writeRuntimeState(addon string, st State) error {
	var b strings.Builder
	b.WriteString("local addonName, AGB = ...\n\n-- Generated by Azeroth Guidebook Companion.\nAGB.SourceRefreshState = {\n    schemaVersion = 2,\n    generatedAt = " + luaQuote(utcNow()) + ",\n")
	if st.LastRun != nil {
		b.WriteString("    lastRun = { requestID = " + luaQuote(st.LastRun.RequestID) + ", state = " + luaQuote(st.LastRun.State) + ", completedAt = " + luaQuote(st.LastRun.CompletedAt) + ", summary = " + luaQuote(st.LastRun.Summary) + " },\n")
	} else {
		b.WriteString("    lastRun = nil,\n")
	}
	b.WriteString("    history = {\n")
	for _, run := range st.History {
		b.WriteString("        { requestID = " + luaQuote(run.RequestID) + ", scope = " + luaQuote(run.Scope) + ", specID = " + strconv.Itoa(run.SpecID) + ", sourceID = " + luaQuote(run.SourceID) + ", guideTab = " + luaQuote(run.GuideTab) + ", state = " + luaQuote(run.State) + ", completedAt = " + luaQuote(run.CompletedAt) + ", summary = " + luaQuote(run.Summary) + ", packs = {\n")
		for _, pack := range run.Packs {
			b.WriteString("            { sourceID = " + luaQuote(pack.SourceID) + ", specID = " + strconv.Itoa(pack.SpecID) + ", state = " + luaQuote(pack.State) + ", summary = " + luaQuote(pack.Summary) + ", domains = {\n")
			for _, domain := range pack.Domains {
				b.WriteString("                { domain = " + luaQuote(domain.Domain) + ", state = " + luaQuote(domain.State) + ", summary = " + luaQuote(domain.Summary))
				if domain.BeforeUpdated != "" {
					b.WriteString(", beforeUpdated = " + luaQuote(domain.BeforeUpdated))
				}
				if domain.AfterUpdated != "" {
					b.WriteString(", afterUpdated = " + luaQuote(domain.AfterUpdated))
				}
				b.WriteString(" },\n")
			}
			b.WriteString("            } },\n")
		}
		b.WriteString("        } },\n")
	}
	b.WriteString("    },\n")
	b.WriteString("    entries = {\n")
	keys := make([]string, 0, len(st.Entries))
	for k := range st.Entries {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		e := st.Entries[k]
		b.WriteString("        [" + luaQuote(k) + "] = { state = " + luaQuote(e.State) + ", updatedAt = " + luaQuote(e.UpdatedAt) + ", requestID = " + luaQuote(e.RequestID) + ", details = " + luaQuote(e.Details))
		if e.PackID != "" {
			b.WriteString(", packID = " + luaQuote(e.PackID))
		}
		if e.PackGeneratedAt != "" {
			b.WriteString(", packGeneratedAt = " + luaQuote(e.PackGeneratedAt))
		}
		if e.FeedMode != "" {
			b.WriteString(", feedMode = " + luaQuote(e.FeedMode))
		}
		if e.ContentSHA256 != "" {
			b.WriteString(", contentSHA256 = " + luaQuote(e.ContentSHA256))
		}
		b.WriteString(" },\n")
	}
	b.WriteString("    },\n}\n")
	return atomicWrite(filepath.Join(addon, "SourceRefreshState.generated.lua"), []byte(b.String()))
}

func writeCompanionStatus(cfg Config, state, feedMode, lastErr string) error {
	epoch := time.Now().Unix()
	text := "local addonName, AGB = ...\n\n-- Generated by Azeroth Guidebook Companion.\nAGB.CompanionStatus = {\n" +
		"    schemaVersion = 1,\n    companionVersion = " + luaQuote(version) + ",\n    protocolVersion = " + strconv.Itoa(protocolVersion) + ",\n    state = " + luaQuote(state) + ",\n    heartbeatEpoch = " + strconv.FormatInt(epoch, 10) + ",\n    heartbeatAt = " + luaQuote(utcNow()) + ",\n    feedMode = " + luaQuote(feedMode) + ",\n    remoteFeedConfigured = " + map[bool]string{true: "true", false: "false"}[strings.TrimSpace(cfg.FeedURL) != ""] + ",\n    lastError = " + luaQuote(lastErr) + ",\n}\n"
	return atomicWrite(filepath.Join(cfg.AddonDir, "CompanionStatus.generated.lua"), []byte(text))
}

func luaQuote(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	s = strings.ReplaceAll(s, "\r", "")
	s = strings.ReplaceAll(s, "\n", "\\n")
	return "\"" + s + "\""
}
func atomicWrite(path string, b []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0644); err != nil {
		return err
	}
	_ = os.Remove(path)
	return os.Rename(tmp, path)
}

func notify(summary string) error {
	if runtime.GOOS != "windows" {
		return nil
	}
	safe := strings.ReplaceAll(summary, "'", "''")
	script := "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $n=New-Object System.Windows.Forms.NotifyIcon; $n.Icon=[System.Drawing.SystemIcons]::Information; $n.BalloonTipTitle='Azeroth Guidebook'; $n.BalloonTipText='Source refresh complete. " + safe + ". Return to WoW and /reload to load the result.'; $n.Visible=$true; $n.ShowBalloonTip(10000); Start-Sleep -Seconds 12; $n.Dispose();"
	cmd := exec.Command("powershell.exe", "-NoProfile", "-WindowStyle", "Hidden", "-Command", script)
	return cmd.Start()
}
