package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRetailFromAddon(t *testing.T) {
	root := t.TempDir()
	addon := filepath.Join(root, "_retail_", "Interface", "AddOns", "AzerothGuidebook")
	if err := os.MkdirAll(filepath.Join(root, "_retail_", "WTF"), 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(addon, 0755); err != nil {
		t.Fatal(err)
	}
	got, err := retailFromAddon(addon)
	if err != nil {
		t.Fatal(err)
	}
	want := filepath.Join(root, "_retail_")
	if filepath.Clean(got) != filepath.Clean(want) {
		t.Fatalf("got %s want %s", got, want)
	}
}

func TestQuoteWindows(t *testing.T) {
	if quoteWindows(`C:\\A B\\c.exe`) != `"C:\\A B\\c.exe"` {
		t.Fatal("quote")
	}
}

func TestHeartbeatEpoch(t *testing.T) {
	got := heartbeatEpoch("AGB.CompanionStatus = {\n    heartbeatEpoch = 1791129001,\n}\n")
	if got != 1791129001 {
		t.Fatalf("got %d", got)
	}
}

func TestCompanionStatusPlaceholder(t *testing.T) {
	text := companionStatusPlaceholder()
	if !strings.Contains(text, `state = "not_installed"`) {
		t.Fatal("missing not_installed state")
	}
	if !strings.Contains(text, "heartbeatEpoch = 0") {
		t.Fatal("missing zero heartbeat")
	}
}

func TestWriteNotInstalledStatus(t *testing.T) {
	dir := t.TempDir()
	if err := writeNotInstalledStatus(dir); err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile(filepath.Join(dir, "CompanionStatus.generated.lua"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(b), `state = "not_installed"`) {
		t.Fatal("status not reset")
	}
}
