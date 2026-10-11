package main

import (
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"testing"
)

func TestParseRequest(t *testing.T) {
	r, err := parseRequest("AGBREFRESH1|1790-1|source|262|icy-veins||Talents|3.12.0")
	if err != nil {
		t.Fatal(err)
	}
	if r.SpecID != 262 || r.SourceID != "icy-veins" || r.Scope != "source" {
		t.Fatalf("bad request: %#v", r)
	}
}

func TestSeedFeedCoversAllSourcesAndSpecs(t *testing.T) {
	f, err := loadSeedFeed()
	if err != nil {
		t.Fatal(err)
	}
	specs := map[int]bool{}
	sources := map[string]int{}
	for _, e := range f.Manifest.Packs {
		specs[e.SpecID] = true
		sources[e.SourceID]++
	}
	if len(specs) != 40 {
		t.Fatalf("expected 40 specs, got %d", len(specs))
	}
	for _, s := range []string{"wowhead", "icy-veins", "ugg"} {
		if sources[s] != 40 {
			t.Fatalf("%s packs=%d", s, sources[s])
		}
	}
	if f.Manifest.PackCount != 120 {
		t.Fatalf("pack count=%d", f.Manifest.PackCount)
	}
}

func TestAllSeedPacksValidate(t *testing.T) {
	f, err := loadSeedFeed()
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range f.Manifest.Packs {
		p, err := loadPack(f, e)
		if err != nil {
			t.Fatalf("%s:%d: %v", e.SourceID, e.SpecID, err)
		}
		h := sha256.Sum256([]byte(p.LuaChunk))
		if hex.EncodeToString(h[:]) != p.ContentSHA256 {
			t.Fatalf("content hash mismatch")
		}
	}
}

func TestLuaQuote(t *testing.T) {
	got := luaQuote("a\\b\n\"c\"")
	if got != "\"a\\\\b\\n\\\"c\\\"\"" {
		t.Fatalf("got %s", got)
	}
}

func TestReadLockPID(t *testing.T) {
	p := filepath.Join(t.TempDir(), "companion.lock")
	if err := os.WriteFile(p, []byte("9428\n"), 0644); err != nil {
		t.Fatal(err)
	}
	if got := readLockPID(p); got != 9428 {
		t.Fatalf("got %d", got)
	}
}
