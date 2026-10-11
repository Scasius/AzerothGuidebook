package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func wrapDomains(body string) string {
	return `do
        domains = {
` + body + `
        }
    end`
}

func TestAnalyzePackChangeNoRecommendationChange(t *testing.T) {
	before := wrapDomains(`
            talents = {
                sourceUpdated = "2026-08-01",
                capturedAt = "old",
                builds = { { name = "Raid", importString = "AAA" }, },
            },`)
	after := strings.ReplaceAll(before, `capturedAt = "old"`, `capturedAt = "new"`)
	got := analyzePackChange("icy-veins", 262, "no_change", before, after)
	if len(got.Domains) != 1 || got.Domains[0].State != "unchanged" {
		t.Fatalf("expected unchanged talents domain, got %#v", got)
	}
}

func TestAnalyzePackChangeDateOnly(t *testing.T) {
	before := wrapDomains(`
            stats = {
                sourceUpdated = "2026-08-01",
                variants = { { stats = { "Haste", "Mastery" } } },
            },`)
	after := strings.ReplaceAll(before, `2026-08-01`, `2026-10-04`)
	got := analyzePackChange("icy-veins", 262, "applied", before, after)
	if len(got.Domains) != 1 || got.Domains[0].State != "date_only" {
		t.Fatalf("expected date_only stats, got %#v", got)
	}
	if got.Domains[0].BeforeUpdated != "2026-08-01" || got.Domains[0].AfterUpdated != "2026-10-04" {
		t.Fatalf("unexpected dates: %#v", got.Domains[0])
	}
}

func TestAnalyzePackChangeTalentBuild(t *testing.T) {
	before := wrapDomains(`
            talents = {
                sourceUpdated = "2026-08-01",
                builds = {
                    { name = "Raid", importString = "AAA" },
                    { name = "Mythic+", importString = "BBB" },
                },
            },`)
	after := strings.ReplaceAll(before, `importString = "BBB"`, `importString = "CCC"`)
	got := analyzePackChange("icy-veins", 262, "applied", before, after)
	if len(got.Domains) != 1 || got.Domains[0].State != "changed" {
		t.Fatalf("expected changed talents, got %#v", got)
	}
	if !strings.Contains(got.Domains[0].Summary, "1 talent build") {
		t.Fatalf("unexpected summary: %q", got.Domains[0].Summary)
	}
}

func TestAnalyzePackChangeBisSlots(t *testing.T) {
	before := wrapDomains(`
            bis = {
                sourceUpdated = "2026-08-01",
                items = {
                    { slot = "Head", id = 100, name = "A" },
                    { slot = "Chest", id = 200, name = "B" },
                },
            },`)
	after := strings.ReplaceAll(before, `slot = "Chest", id = 200`, `slot = "Chest", id = 201`)
	got := analyzePackChange("icy-veins", 262, "applied", before, after)
	if !strings.Contains(got.Domains[0].Summary, "1 gear slot") {
		t.Fatalf("unexpected summary: %q", got.Domains[0].Summary)
	}
}

func TestAnalyzePackChangeConsumableDelta(t *testing.T) {
	before := wrapDomains(`
            consumables = {
                items = {
                    { kind = "item", id = 100, name = "Flask A" },
                },
            },`)
	after := wrapDomains(`
            consumables = {
                items = {
                    { kind = "item", id = 100, name = "Flask A" },
                    { kind = "item", id = 200, name = "Potion B" },
                },
            },`)
	got := analyzePackChange("icy-veins", 262, "applied", before, after)
	if !strings.Contains(got.Domains[0].Summary, "1 recommendation(s) added | 0 removed") {
		t.Fatalf("unexpected summary: %q", got.Domains[0].Summary)
	}
}

func TestPushRunHistoryNewestFirstAndLimited(t *testing.T) {
	old := []RunHistory{{RequestID: "b"}, {RequestID: "a"}}
	out := pushRunHistory(old, RunHistory{RequestID: "c"}, 2)
	if len(out) != 2 || out[0].RequestID != "c" || out[1].RequestID != "b" {
		t.Fatalf("unexpected history %#v", out)
	}
}

func TestAnalyzePackChangeAcrossMultipleContexts(t *testing.T) {
	before := `do
        contexts = {
            raid = { domains = {
                stats = { sourceUpdated = "2026-08-01", variants = { { stats = { "Haste", "Mastery" } } } },
            } },
            mythicplus = { domains = {
                stats = { sourceUpdated = "2026-08-02", variants = { { stats = { "Crit", "Haste" } } } },
            } },
        }
    end`
	after := strings.ReplaceAll(before, `{ "Crit", "Haste" }`, `{ "Mastery", "Haste" }`)
	got := analyzePackChange("ugg", 262, "applied", before, after)
	if len(got.Domains) != 1 || got.Domains[0].State != "changed" {
		t.Fatalf("expected U.GG multi-context stats change, got %#v", got)
	}
}

func TestWriteRuntimeStateIncludesHistory(t *testing.T) {
	dir := t.TempDir()
	st := newState()
	st.LastRun = &LastRun{RequestID: "r1", State: "applied", CompletedAt: "2026-10-04T18:00:00Z", Summary: "1 applied"}
	st.History = []RunHistory{{
		RequestID: "r1", Scope: "source", SpecID: 262, SourceID: "icy-veins", GuideTab: "Talents", State: "applied", CompletedAt: "2026-10-04T18:00:00Z", Summary: "1 applied",
		Packs: []PackChange{{SourceID: "icy-veins", SpecID: 262, State: "applied", Summary: "1 guide domain changed.", Domains: []DomainChange{{Domain: "talents", State: "changed", Summary: "1 talent build changed.", BeforeUpdated: "2026-08-01", AfterUpdated: "2026-10-04"}}}},
	}}
	if err := writeRuntimeState(dir, st); err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile(filepath.Join(dir, "SourceRefreshState.generated.lua"))
	if err != nil {
		t.Fatal(err)
	}
	text := string(raw)
	for _, want := range []string{`schemaVersion = 2`, `scope = "source"`, `domain = "talents"`, `beforeUpdated = "2026-08-01"`, `afterUpdated = "2026-10-04"`} {
		if !strings.Contains(text, want) {
			t.Fatalf("runtime state missing %q:\n%s", want, text)
		}
	}
}

func TestCompactAllSourceChangesDropsOnlyUnchangedDetail(t *testing.T) {
	in := []PackChange{
		{SourceID: "icy-veins", State: "no_change", Domains: []DomainChange{{Domain: "talents", State: "unchanged"}}},
		{SourceID: "wowhead", State: "applied", Domains: []DomainChange{{Domain: "bis", State: "changed"}}},
		{SourceID: "ugg", State: "no_change", Domains: []DomainChange{{Domain: "stats", State: "date_only"}}},
	}
	out := compactAllSourceChanges(in)
	if len(out[0].Domains) != 0 {
		t.Fatalf("expected unchanged details compacted")
	}
	if len(out[1].Domains) != 1 || len(out[2].Domains) != 1 {
		t.Fatalf("notable details should remain: %#v", out)
	}
}
