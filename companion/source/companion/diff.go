package main

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

type DomainChange struct {
	Domain        string `json:"domain"`
	State         string `json:"state"`
	Summary       string `json:"summary"`
	BeforeUpdated string `json:"before_updated,omitempty"`
	AfterUpdated  string `json:"after_updated,omitempty"`
}

type PackChange struct {
	SourceID string         `json:"source_id"`
	SpecID   int            `json:"spec_id"`
	State    string         `json:"state"`
	Summary  string         `json:"summary"`
	Domains  []DomainChange `json:"domains,omitempty"`
}

type RunHistory struct {
	RequestID   string       `json:"request_id"`
	Scope       string       `json:"scope"`
	SpecID      int          `json:"spec_id"`
	SourceID    string       `json:"source_id"`
	GuideTab    string       `json:"guide_tab"`
	State       string       `json:"state"`
	CompletedAt string       `json:"completed_at"`
	Summary     string       `json:"summary"`
	Packs       []PackChange `json:"packs"`
}

var refreshDomainOrder = []string{"talents", "bis", "consumables", "enchants", "stats", "rotation"}

var sourceUpdatedRE = regexp.MustCompile(`sourceUpdated\s*=\s*"([^"]*)"`)
var metadataLineRE = regexp.MustCompile(`(?m)^\s*(sourceURL|sourceUpdated|capturedAt|status)\s*=\s*[^\n]*\n?`)
var whitespaceRE = regexp.MustCompile(`\s+`)
var buildPairRE = regexp.MustCompile(`(?s)\{\s*name\s*=\s*"([^"]+)"\s*,\s*importString\s*=\s*"([^"]*)"`)
var slotItemRE = regexp.MustCompile(`(?s)slot\s*=\s*"([^"]+)"\s*,\s*id\s*=\s*([0-9]+)`)
var entityRE = regexp.MustCompile(`(?s)kind\s*=\s*"(item|spell)"\s*,\s*id\s*=\s*([0-9]+)\s*,\s*name\s*=\s*"([^"]+)"`)

func pushRunHistory(old []RunHistory, run RunHistory, limit int) []RunHistory {
	if limit <= 0 {
		return nil
	}
	out := make([]RunHistory, 0, limit)
	out = append(out, run)
	for _, prev := range old {
		if prev.RequestID == "" || prev.RequestID == run.RequestID {
			continue
		}
		out = append(out, prev)
		if len(out) >= limit {
			break
		}
	}
	return out
}

func analyzePackChange(source string, specID int, state, beforeChunk, afterChunk string) PackChange {
	out := PackChange{SourceID: source, SpecID: specID, State: state}
	beforeChunk = strings.TrimSpace(beforeChunk)
	afterChunk = strings.TrimSpace(afterChunk)

	if beforeChunk == "" || afterChunk == "" {
		if state == "no_change" {
			out.Summary = "No content change; detailed domain snapshot is unavailable for this baseline."
		} else {
			out.Summary = "Validated source pack changed; detailed pre-refresh domain snapshot is unavailable for this baseline."
		}
		return out
	}

	changed := 0
	dateOnly := 0
	available := 0
	for _, domain := range refreshDomainOrder {
		before := extractDomainSnapshot(beforeChunk, domain)
		after := extractDomainSnapshot(afterChunk, domain)
		if before == "" && after == "" {
			continue
		}
		available++
		dc := compareDomain(domain, before, after)
		if dc.State == "changed" {
			changed++
		} else if dc.State == "date_only" {
			dateOnly++
		}
		out.Domains = append(out.Domains, dc)
	}

	switch {
	case available == 0 && state == "no_change":
		out.Summary = "No content change; this source pack does not expose domain snapshots."
	case available == 0:
		out.Summary = "Validated source pack changed; domain-level details are unavailable."
	case changed > 0 && dateOnly > 0:
		out.Summary = fmt.Sprintf("%d guide domain(s) changed; %d additional source date(s) advanced.", changed, dateOnly)
	case changed > 0:
		out.Summary = fmt.Sprintf("%d guide domain(s) changed.", changed)
	case dateOnly > 0:
		out.Summary = fmt.Sprintf("Recommendations unchanged; %d source date(s) advanced.", dateOnly)
	default:
		out.Summary = "No recommendation changes detected."
	}
	return out
}

func compareDomain(domain, before, after string) DomainChange {
	dc := DomainChange{Domain: domain}
	dc.BeforeUpdated = sourceUpdated(before)
	dc.AfterUpdated = sourceUpdated(after)

	beforeNorm := normalizeDomain(before)
	afterNorm := normalizeDomain(after)
	if beforeNorm == afterNorm {
		if dc.BeforeUpdated != dc.AfterUpdated && (dc.BeforeUpdated != "" || dc.AfterUpdated != "") {
			dc.State = "date_only"
			dc.Summary = "Recommendations unchanged; source date advanced."
		} else {
			dc.State = "unchanged"
			dc.Summary = "No recommendation change."
		}
		return dc
	}

	dc.State = "changed"
	dc.Summary = domainChangeSummary(domain, before, after)
	return dc
}

func sourceUpdated(table string) string {
	seen := map[string]bool{}
	values := []string{}
	for _, m := range sourceUpdatedRE.FindAllStringSubmatch(table, -1) {
		if len(m) != 2 || m[1] == "" || seen[m[1]] {
			continue
		}
		seen[m[1]] = true
		values = append(values, m[1])
	}
	sort.Strings(values)
	return strings.Join(values, " / ")
}

func normalizeDomain(table string) string {
	table = metadataLineRE.ReplaceAllString(table, "")
	table = whitespaceRE.ReplaceAllString(table, "")
	return table
}

func domainChangeSummary(domain, before, after string) string {
	switch domain {
	case "talents":
		n := changedMapKeys(extractBuilds(before), extractBuilds(after))
		if n > 0 {
			return fmt.Sprintf("%d talent build(s) changed.", n)
		}
		return "Talent recommendations changed."
	case "bis":
		n := changedMapKeys(extractSlots(before), extractSlots(after))
		if n > 0 {
			return fmt.Sprintf("%d gear slot(s) changed.", n)
		}
		return "Gear recommendations changed."
	case "consumables":
		b := extractEntities(before)
		a := extractEntities(after)
		added, removed := setDelta(b, a)
		if added > 0 || removed > 0 {
			return fmt.Sprintf("%d recommendation(s) added | %d removed.", added, removed)
		}
		return "Consumable recommendations changed."
	case "enchants":
		return "Enchant or gem recommendations changed."
	case "stats":
		return "Stat priority changed."
	case "rotation":
		return "Rotation guidance changed."
	default:
		return "Guide recommendations changed."
	}
}

func extractBuilds(table string) map[string]string {
	out := map[string]string{}
	for _, m := range buildPairRE.FindAllStringSubmatch(table, -1) {
		if len(m) == 3 {
			out[m[1]] = m[2]
		}
	}
	return out
}

func extractSlots(table string) map[string]string {
	out := map[string]string{}
	for _, m := range slotItemRE.FindAllStringSubmatch(table, -1) {
		if len(m) == 3 {
			out[m[1]] = m[2]
		}
	}
	return out
}

func extractEntities(table string) map[string]bool {
	out := map[string]bool{}
	for _, m := range entityRE.FindAllStringSubmatch(table, -1) {
		if len(m) == 4 {
			out[m[1]+":"+m[2]+":"+m[3]] = true
		}
	}
	// Some source domains omit kind/name and use simple id fields. Keep a
	// conservative numeric fallback only when the structured matcher found
	// nothing, so nested metadata IDs do not inflate normal diffs.
	if len(out) == 0 {
		idRE := regexp.MustCompile(`\bid\s*=\s*([0-9]+)`)
		for _, m := range idRE.FindAllStringSubmatch(table, -1) {
			if len(m) == 2 {
				out["id:"+m[1]] = true
			}
		}
	}
	return out
}

func changedMapKeys(a, b map[string]string) int {
	keys := map[string]bool{}
	for k := range a {
		keys[k] = true
	}
	for k := range b {
		keys[k] = true
	}
	n := 0
	for k := range keys {
		if a[k] != b[k] {
			n++
		}
	}
	return n
}

func setDelta(before, after map[string]bool) (added, removed int) {
	for k := range after {
		if !before[k] {
			added++
		}
	}
	for k := range before {
		if !after[k] {
			removed++
		}
	}
	return
}

func extractDomainSnapshot(chunk, name string) string {
	domainBlocks := extractAllLuaTables(chunk, "domains")
	snapshots := []string{}
	for _, domains := range domainBlocks {
		matches := extractShallowNamedTables(domains, name)
		snapshots = append(snapshots, matches...)
	}
	if len(snapshots) == 0 {
		// Some future pack formats may store one domain directly rather than
		// under a `domains` container. Retain the conservative single-table
		// fallback for those packs.
		if table := extractLuaTable(chunk, name); table != "" {
			snapshots = append(snapshots, table)
		}
	}
	return strings.Join(snapshots, "\n-- AGB CONTEXT --\n")
}

func extractShallowNamedTables(parent, name string) []string {
	out := []string{}
	if len(parent) == 0 || parent[0] != '{' {
		return out
	}
	depth := 0
	var quote byte
	escaped := false
	for i := 0; i < len(parent); i++ {
		c := parent[i]
		if quote != 0 {
			if escaped {
				escaped = false
				continue
			}
			if c == '\\' {
				escaped = true
				continue
			}
			if c == quote {
				quote = 0
			}
			continue
		}
		if c == '"' || c == '\'' {
			quote = c
			continue
		}
		if c == '{' {
			depth++
			continue
		}
		if c == '}' {
			depth--
			continue
		}
		if depth != 1 || !isIdentStart(c) {
			continue
		}
		j := i + 1
		for j < len(parent) && isIdentPart(parent[j]) {
			j++
		}
		if parent[i:j] != name {
			i = j - 1
			continue
		}
		k := j
		for k < len(parent) && isLuaSpace(parent[k]) {
			k++
		}
		if k >= len(parent) || parent[k] != '=' {
			i = j - 1
			continue
		}
		k++
		for k < len(parent) && isLuaSpace(parent[k]) {
			k++
		}
		if k >= len(parent) || parent[k] != '{' {
			i = j - 1
			continue
		}
		if table := extractLuaTableAt(parent, k); table != "" {
			out = append(out, table)
			i = k + len(table) - 1
		}
	}
	return out
}

func extractAllLuaTables(chunk, name string) []string {
	out := []string{}
	var quote byte
	escaped := false
	for i := 0; i < len(chunk); i++ {
		c := chunk[i]
		if quote != 0 {
			if escaped {
				escaped = false
				continue
			}
			if c == '\\' {
				escaped = true
				continue
			}
			if c == quote {
				quote = 0
			}
			continue
		}
		if c == '"' || c == '\'' {
			quote = c
			continue
		}
		if !isIdentStart(c) {
			continue
		}
		j := i + 1
		for j < len(chunk) && isIdentPart(chunk[j]) {
			j++
		}
		if chunk[i:j] != name {
			i = j - 1
			continue
		}
		k := j
		for k < len(chunk) && isLuaSpace(chunk[k]) {
			k++
		}
		if k >= len(chunk) || chunk[k] != '=' {
			i = j - 1
			continue
		}
		k++
		for k < len(chunk) && isLuaSpace(chunk[k]) {
			k++
		}
		if k >= len(chunk) || chunk[k] != '{' {
			i = j - 1
			continue
		}
		if table := extractLuaTableAt(chunk, k); table != "" {
			out = append(out, table)
			i = k + len(table) - 1
		}
	}
	return out
}

func isIdentStart(c byte) bool { return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_' }
func isIdentPart(c byte) bool  { return isIdentStart(c) || (c >= '0' && c <= '9') }
func isLuaSpace(c byte) bool   { return c == ' ' || c == '\t' || c == '\r' || c == '\n' }

func extractLuaTable(chunk, name string) string {
	needleRE := regexp.MustCompile(`(?m)^\s*` + regexp.QuoteMeta(name) + `\s*=\s*\{`)
	loc := needleRE.FindStringIndex(chunk)
	if loc == nil {
		return ""
	}
	openRel := strings.Index(chunk[loc[0]:loc[1]], "{")
	if openRel < 0 {
		return ""
	}
	return extractLuaTableAt(chunk, loc[0]+openRel)
}

func extractLuaTableAt(chunk string, start int) string {
	if start < 0 || start >= len(chunk) || chunk[start] != '{' {
		return ""
	}
	depth := 0
	var quote byte
	escaped := false
	for i := start; i < len(chunk); i++ {
		c := chunk[i]
		if quote != 0 {
			if escaped {
				escaped = false
				continue
			}
			if c == '\\' {
				escaped = true
				continue
			}
			if c == quote {
				quote = 0
			}
			continue
		}
		if c == '"' || c == '\'' {
			quote = c
			continue
		}
		if c == '{' {
			depth++
		} else if c == '}' {
			depth--
			if depth == 0 {
				return chunk[start : i+1]
			}
		}
	}
	return ""
}

func sortedKeys(m map[string]string) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func atoi(s string) int {
	n, _ := strconv.Atoi(s)
	return n
}

func compactAllSourceChanges(in []PackChange) []PackChange {
	out := make([]PackChange, len(in))
	copy(out, in)
	for i := range out {
		if out[i].State != "no_change" {
			continue
		}
		notable := false
		for _, d := range out[i].Domains {
			if d.State == "changed" || d.State == "date_only" {
				notable = true
				break
			}
		}
		if !notable {
			out[i].Domains = nil
		}
	}
	return out
}
