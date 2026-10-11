package main

import (
	"bufio"
	"embed"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

var version = "dev"

//go:embed payload/AzerothGuidebookCompanion.exe
var payloadFS embed.FS

type Config struct {
	SchemaVersion int    `json:"schema_version"`
	AddonDir      string `json:"addon_dir"`
	RetailDir     string `json:"retail_dir"`
	FeedURL       string `json:"feed_url"`
	PollSeconds   int    `json:"poll_seconds"`
	InstalledAt   string `json:"installed_at"`
}

func main() {
	addonArg := flag.String("addon-dir", "", "AzerothGuidebook addon folder")
	feedArg := flag.String("feed-url", "", "validated pack feed manifest URL")
	uninstall := flag.Bool("uninstall", false, "uninstall companion")
	quiet := flag.Bool("quiet", false, "minimal output")
	flag.Parse()

	if runtime.GOOS != "windows" {
		fmt.Println("This setup program is intended for Windows.")
	}

	local := os.Getenv("LOCALAPPDATA")
	if strings.TrimSpace(local) == "" {
		fatal("LOCALAPPDATA is unavailable.")
	}
	installDir := filepath.Join(local, "AzerothGuidebook", "Companion")
	if *uninstall {
		if err := doUninstall(installDir, *quiet); err != nil {
			fatal(err.Error())
		}
		return
	}

	addonDir := strings.TrimSpace(*addonArg)
	if addonDir == "" {
		addonDir = strings.TrimSpace(os.Getenv("AZEROTH_GUIDEBOOK_ADDON_DIR"))
	}
	if addonDir == "" {
		addonDir = detectAddonDir()
	}
	if addonDir == "" && !*quiet {
		fmt.Println("Azeroth Guidebook was not found in a common World of Warcraft location.")
		fmt.Println("Paste the full AzerothGuidebook addon folder path, then press Enter:")
		fmt.Print("> ")
		line, _ := bufio.NewReader(os.Stdin).ReadString('\n')
		addonDir = strings.Trim(strings.TrimSpace(line), "\"")
	}
	if addonDir == "" {
		fatal("AzerothGuidebook addon folder was not found. Re-run setup with --addon-dir \"<path>\".")
	}
	abs, err := filepath.Abs(addonDir)
	if err != nil {
		fatal(err.Error())
	}
	addonDir = abs
	if _, err := os.Stat(filepath.Join(addonDir, "AzerothGuidebook.toc")); err != nil {
		fatal("AzerothGuidebook.toc was not found under: " + addonDir)
	}
	retailDir, err := retailFromAddon(addonDir)
	if err != nil {
		fatal(err.Error())
	}

	if !*quiet {
		fmt.Println("Azeroth Guidebook Companion Setup", version)
		fmt.Println("Addon:", addonDir)
		fmt.Println("Retail:", retailDir)
		fmt.Println("Install:", installDir)
	}

	if err := os.MkdirAll(installDir, 0755); err != nil {
		fatal(err.Error())
	}
	cleanupLegacyCompanion()
	bestEffortKill(installDir)
	// A forced stop cannot run the companion's deferred lock cleanup. Remove
	// that orphaned lock before launching the replacement; otherwise the new
	// process can exit for up to 90 seconds while setup mistakenly sees the
	// previous heartbeat as healthy.
	_ = os.Remove(filepath.Join(installDir, "companion.lock"))

	companionBytes, err := payloadFS.ReadFile("payload/AzerothGuidebookCompanion.exe")
	if err != nil {
		fatal(err.Error())
	}
	companionPath := filepath.Join(installDir, "AzerothGuidebookCompanion.exe")
	if err := atomicWrite(companionPath, companionBytes); err != nil {
		fatal("Could not install companion executable: " + err.Error())
	}

	self, _ := os.Executable()
	setupCopy := filepath.Join(installDir, "AzerothGuidebookCompanionSetup.exe")
	if self != "" && !samePath(self, setupCopy) {
		if err := copyFile(self, setupCopy); err != nil {
			fatal("Could not install uninstaller: " + err.Error())
		}
	}

	feedURL := strings.TrimSpace(*feedArg)
	if feedURL == "" {
		feedURL = strings.TrimSpace(os.Getenv("AZEROTH_GUIDEBOOK_PACK_FEED_URL"))
	}
	cfg := Config{SchemaVersion: 1, AddonDir: addonDir, RetailDir: retailDir, FeedURL: feedURL, PollSeconds: 2, InstalledAt: time.Now().UTC().Truncate(time.Second).Format(time.RFC3339)}
	raw, _ := json.MarshalIndent(cfg, "", "  ")
	raw = append(raw, '\n')
	if err := atomicWrite(filepath.Join(installDir, "config.json"), raw); err != nil {
		fatal(err.Error())
	}

	runKey := `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
	runCommand := quoteWindows(companionPath) + " --background"
	if err := regAdd(runKey, `AzerothGuidebookCompanion`, runCommand, "REG_SZ"); err != nil {
		fatal("Could not register Windows startup entry: " + err.Error())
	}
	uninstallKey := `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\AzerothGuidebookCompanion`
	if err := registerUninstallEntry(uninstallKey, setupCopy, installDir); err != nil {
		// Do not leave a half-installed background application that cannot be
		// removed through Windows Settings. The addon continues to work with
		// bundled data when setup fails here.
		_ = regDeleteValue(runKey, `AzerothGuidebookCompanion`)
		_ = regDeleteKey(uninstallKey)
		fatal("Could not register Windows Installed apps entry: " + err.Error())
	}

	launchEpoch := time.Now().Unix()
	cmd := exec.Command(companionPath, "--background")
	if err := cmd.Start(); err != nil {
		fatal("Companion installed but could not start: " + err.Error())
	}

	statusPath := filepath.Join(addonDir, "CompanionStatus.generated.lua")
	ready := false
	for i := 0; i < 30; i++ {
		b, er := os.ReadFile(statusPath)
		if er == nil {
			text := string(b)
			if strings.Contains(text, `state = "running"`) && strings.Contains(text, version) && heartbeatEpoch(text) >= launchEpoch {
				ready = true
				break
			}
		}
		time.Sleep(200 * time.Millisecond)
	}
	if !ready {
		fmt.Println("Installed, but the running heartbeat has not appeared yet. Launch WoW and /reload after a few seconds; if unavailable, inspect companion.log under", installDir)
	} else if !*quiet {
		fmt.Println("Companion installed and running. Automatic source refresh is ready.")
	}
	if !*quiet {
		fmt.Println("Future addon updates through CurseForge will not remove this companion.")
	}
}

func heartbeatEpoch(text string) int64 {
	const marker = "heartbeatEpoch = "
	i := strings.Index(text, marker)
	if i < 0 {
		return 0
	}
	rest := text[i+len(marker):]
	if end := strings.IndexAny(rest, ",\r\n"); end >= 0 {
		rest = rest[:end]
	}
	v, _ := strconv.ParseInt(strings.TrimSpace(rest), 10, 64)
	return v
}

func detectAddonDir() string {
	envRoots := []string{os.Getenv("ProgramFiles(x86)"), os.Getenv("ProgramFiles"), os.Getenv("SystemDrive")}
	seen := map[string]bool{}
	candidates := []string{}
	add := func(p string) {
		if p == "" {
			return
		}
		p = filepath.Clean(p)
		if !seen[strings.ToLower(p)] {
			seen[strings.ToLower(p)] = true
			candidates = append(candidates, p)
		}
	}
	for _, root := range envRoots {
		if root == "" {
			continue
		}
		add(filepath.Join(root, "World of Warcraft", "_retail_", "Interface", "AddOns", "AzerothGuidebook"))
		add(filepath.Join(root, "Games", "World of Warcraft", "_retail_", "Interface", "AddOns", "AzerothGuidebook"))
		add(filepath.Join(root, "Battle.net", "World of Warcraft", "_retail_", "Interface", "AddOns", "AzerothGuidebook"))
		add(filepath.Join(root, "Blizzard", "World of Warcraft", "_retail_", "Interface", "AddOns", "AzerothGuidebook"))
	}
	for drive := 'C'; drive <= 'Z'; drive++ {
		d := fmt.Sprintf("%c:\\", drive)
		for _, base := range []string{"World of Warcraft", filepath.Join("Games", "World of Warcraft"), filepath.Join("Battle.net", "World of Warcraft"), filepath.Join("Blizzard", "World of Warcraft")} {
			add(filepath.Join(d, base, "_retail_", "Interface", "AddOns", "AzerothGuidebook"))
		}
	}
	cwd, _ := os.Getwd()
	add(cwd)
	for _, p := range candidates {
		if _, err := os.Stat(filepath.Join(p, "AzerothGuidebook.toc")); err == nil {
			return p
		}
	}
	return ""
}

func retailFromAddon(addon string) (string, error) {
	p := filepath.Clean(addon)
	addOns := filepath.Dir(p)
	if !strings.EqualFold(filepath.Base(addOns), "AddOns") {
		return "", errors.New("addon folder is not inside Interface\\AddOns")
	}
	iface := filepath.Dir(addOns)
	if !strings.EqualFold(filepath.Base(iface), "Interface") {
		return "", errors.New("addon folder is not inside _retail_\\Interface\\AddOns")
	}
	retail := filepath.Dir(iface)
	if _, err := os.Stat(filepath.Join(retail, "WTF")); err != nil {
		return "", errors.New("Retail WTF folder was not found next to Interface")
	}
	return retail, nil
}

func cleanupLegacyCompanion() {
	// v3.12 development builds used a PowerShell companion under this older Run value.
	_ = regDeleteValue(`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, `AzerothGuidebookSourceRefreshCompanion`)
	_ = exec.Command("schtasks.exe", "/Delete", "/TN", "AzerothGuidebookSourceRefreshCompanion", "/F").Run()
	script := `Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -and $_.CommandLine -like '*Start-SourceRefreshCompanion.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }`
	_ = exec.Command("powershell.exe", "-NoProfile", "-WindowStyle", "Hidden", "-Command", script).Run()
}

func doUninstall(installDir string, quiet bool) error {
	var cfg Config
	b, readErr := os.ReadFile(filepath.Join(installDir, "config.json"))
	if readErr == nil {
		_ = json.Unmarshal(b, &cfg)
	}

	// Remove the startup hook first so a logon/session transition cannot launch
	// another copy while uninstall is shutting the current one down.
	_ = regDeleteValue(`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, `AzerothGuidebookCompanion`)

	if err := stopCompanionAndWait(installDir); err != nil {
		return fmt.Errorf("could not stop the running companion: %w", err)
	}
	cleanupLegacyCompanion()
	_ = os.Remove(filepath.Join(installDir, "companion.lock"))

	addonDir := strings.TrimSpace(cfg.AddonDir)
	if addonDir == "" || !fileExists(filepath.Join(addonDir, "AzerothGuidebook.toc")) {
		addonDir = detectAddonDir()
	}
	if addonDir == "" {
		return errors.New("could not locate the AzerothGuidebook addon folder to reset companion status")
	}
	if err := writeNotInstalledStatus(addonDir); err != nil {
		return fmt.Errorf("could not reset addon companion status: %w", err)
	}

	// Only remove the Installed apps registration after shutdown and the addon
	// status reset have both been verified. If either fails, the uninstall entry
	// remains available so the user can retry instead of being left half-removed.
	_ = regDeleteKey(`HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\AzerothGuidebookCompanion`)

	if !quiet {
		fmt.Println("Azeroth Guidebook Companion uninstalled.")
	}
	cmd := exec.Command("cmd.exe", "/C", "timeout /T 2 /NOBREAK >NUL & rmdir /S /Q "+quoteWindows(installDir))
	_ = cmd.Start()
	return nil
}

func companionStatusPlaceholder() string {
	return "local addonName, AGB = ...\n\nAGB.CompanionStatus = {\n    schemaVersion = 1,\n    companionVersion = nil,\n    protocolVersion = 1,\n    state = \"not_installed\",\n    heartbeatEpoch = 0,\n    heartbeatAt = nil,\n    feedMode = nil,\n    remoteFeedConfigured = false,\n    lastError = nil,\n}\n"
}

func writeNotInstalledStatus(addonDir string) error {
	statusPath := filepath.Join(addonDir, "CompanionStatus.generated.lua")
	if err := atomicWrite(statusPath, []byte(companionStatusPlaceholder())); err != nil {
		return err
	}
	b, err := os.ReadFile(statusPath)
	if err != nil {
		return err
	}
	if !strings.Contains(string(b), `state = "not_installed"`) || !strings.Contains(string(b), "heartbeatEpoch = 0") {
		return errors.New("status verification failed")
	}
	return nil
}

func stopCompanionAndWait(installDir string) error {
	// Ask current rc5+ companions to exit cleanly first. Older builds ignore the
	// request, so setup falls back to native Windows process termination below.
	stopPath := filepath.Join(installDir, "stop.request")
	_ = os.WriteFile(stopPath, []byte(time.Now().UTC().Format(time.RFC3339Nano)+"\n"), 0644)
	defer os.Remove(stopPath)

	for i := 0; i < 30; i++ {
		running, err := companionProcessRunning()
		if err != nil {
			return err
		}
		if !running {
			return nil
		}
		time.Sleep(100 * time.Millisecond)
	}

	// Do not rely on taskkill/tasklist. Security products can virtualize or
	// restrict those command-line tools even for a normal per-user process.
	if err := terminateProcessesByName("AzerothGuidebookCompanion.exe"); err != nil {
		return err
	}
	for i := 0; i < 50; i++ {
		running, err := companionProcessRunning()
		if err != nil {
			return err
		}
		if !running {
			return nil
		}
		time.Sleep(100 * time.Millisecond)
	}
	return errors.New("AzerothGuidebookCompanion.exe is still running after native termination")
}

func companionProcessRunning() (bool, error) {
	pids, err := processesByName("AzerothGuidebookCompanion.exe")
	if err != nil {
		return false, err
	}
	return len(pids) > 0, nil
}

func bestEffortKill(installDir string) {
	_ = stopCompanionAndWait(installDir)
	_ = os.Remove(filepath.Join(installDir, "stop.request"))
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
func registerUninstallEntry(key, setupCopy, installDir string) error {
	installDate := time.Now().Format("20060102")
	values := []struct {
		name  string
		value string
		typ   string
	}{
		{"DisplayName", "Azeroth Guidebook Companion", "REG_SZ"},
		{"DisplayVersion", version, "REG_SZ"},
		{"Publisher", "Azeroth Guidebook", "REG_SZ"},
		{"InstallLocation", installDir, "REG_SZ"},
		{"InstallDate", installDate, "REG_SZ"},
		{"DisplayIcon", setupCopy + ",0", "REG_SZ"},
		{"UninstallString", quoteWindows(setupCopy) + " --uninstall", "REG_SZ"},
		{"QuietUninstallString", quoteWindows(setupCopy) + " --uninstall --quiet", "REG_SZ"},
		{"NoModify", "1", "REG_DWORD"},
		{"NoRepair", "1", "REG_DWORD"},
		{"SystemComponent", "0", "REG_DWORD"},
	}
	for _, item := range values {
		if err := regAdd(key, item.name, item.value, item.typ); err != nil {
			return fmt.Errorf("write %s: %w", item.name, err)
		}
	}
	// Windows Settings/Installed apps depends on this registration. Verify the
	// same 64-bit current-user registry view we wrote instead of silently
	// accepting a partial registration as rc2 did.
	for _, name := range []string{"DisplayName", "DisplayVersion", "UninstallString"} {
		if err := regQueryValue(key, name); err != nil {
			return fmt.Errorf("verify %s: %w", name, err)
		}
	}
	return nil
}

func regAdd(key, name, value, typ string) error {
	cmd := exec.Command("reg.exe", "add", key, "/v", name, "/t", typ, "/d", value, "/f", "/reg:64")
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("reg add failed: %w (%s)", err, strings.TrimSpace(string(out)))
	}
	return nil
}
func regQueryValue(key, name string) error {
	cmd := exec.Command("reg.exe", "query", key, "/v", name, "/reg:64")
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("reg query failed: %w (%s)", err, strings.TrimSpace(string(out)))
	}
	return nil
}
func regDeleteValue(key, name string) error {
	cmd := exec.Command("reg.exe", "delete", key, "/v", name, "/f", "/reg:64")
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("reg delete value failed: %w (%s)", err, strings.TrimSpace(string(out)))
	}
	return nil
}
func regDeleteKey(key string) error {
	cmd := exec.Command("reg.exe", "delete", key, "/f", "/reg:64")
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("reg delete key failed: %w (%s)", err, strings.TrimSpace(string(out)))
	}
	return nil
}
func quoteWindows(s string) string { return `"` + strings.ReplaceAll(s, `"`, `\"`) + `"` }
func samePath(a, b string) bool {
	aa, _ := filepath.Abs(a)
	bb, _ := filepath.Abs(b)
	return strings.EqualFold(filepath.Clean(aa), filepath.Clean(bb))
}
func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	tmp := dst + ".tmp"
	out, err := os.Create(tmp)
	if err != nil {
		return err
	}
	_, err = io.Copy(out, in)
	cerr := out.Close()
	if err != nil {
		return err
	}
	if cerr != nil {
		return cerr
	}
	_ = os.Remove(dst)
	return os.Rename(tmp, dst)
}
func atomicWrite(path string, b []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0755); err != nil {
		return err
	}
	_ = os.Remove(path)
	return os.Rename(tmp, path)
}
func fatal(msg string) {
	fmt.Fprintln(os.Stderr, "Setup failed:", msg)
	fmt.Println("Press Enter to close.")
	_, _ = bufio.NewReader(os.Stdin).ReadString('\n')
	os.Exit(1)
}
