# Azeroth Guidebook v3.16.0

A Retail World of Warcraft addon that keeps concise PvE guide reference data in-game while preserving source provenance and fail-closed behavior.


## v3.16.0 Activity Profiles

v3.16.0 adds user-defined **Raid**, **Mythic+**, and **Delves** profiles for each specialization. Profiles do not prescribe which guide source to use. Configure the guide exactly the way you want, then choose **Save as Raid**, **Save as Mythic+**, or **Save as Delves**.

A profile remembers the selected source for every guide domain, U.GG content context, talent category and source-specific build selections, Wowhead gear set, and Rotation context/preset. Selecting a saved profile restores all of those choices at once, so **My Character** and the **Character Action Plan** immediately recalculate against the chosen activity setup.

If you change a source/build/context while a saved profile is active, the profile is labeled **Modified**. Use **Save Changes to <profile>** to update it, or click the modified profile button to restore its last saved configuration. Profiles are independent per specialization.

Saving captures the current setup exactly; Azeroth Guidebook never chooses a source on the player's behalf. If a previously saved source is no longer available, profile application fails closed for that selection and leaves the current source unchanged.

Live validation confirmed separate Raid, Mythic+, and Delves profiles can be saved and switched in both directions, manual changes correctly mark the active profile as **Modified**, **Save Changes** updates the saved profile, reselecting a modified profile restores its saved state, and profiles remain isolated per specialization.


## v3.15.0 Refresh Change Intelligence

v3.15.0 makes a completed source refresh explain **what actually changed** instead of reporting only Applied / No change. The Sources tab now includes **What's New Since Last Refresh?** plus a compact five-run history.

- Companion v1.1.0-rc1 records per-source/spec refresh history for the last five completed runs.
- For source packs with a verifiable pre-refresh snapshot, each guide domain is classified as **Changed**, **No change**, or **Source date advanced**.
- Talent changes count changed source builds; Gear/BiS reports changed equipment slots; Consumables reports added/removed recommendations; Enchants & Gems, Stats, and Rotation report source-domain changes without inventing recommendations.
- Source-date-only updates are separated from recommendation changes, so an editorial timestamp advancing does not falsely look like a gearing/talent change.
- Changed/date-only rows expose **View Updated Guide**, which opens the affected specialization, source, and guide domain directly.
- **Refresh All Sources** stays compact: unchanged packs are summarized instead of dumping all 120 rows. Current Source / Current Spec refreshes show their available domain detail.
- The most recent five refresh runs are retained locally. Release ZIPs still ship with a clean/no-history `SourceRefreshState.generated.lua`.
- Older companion state remains compatible; if the installed companion has not produced schema-v2 history yet, the Sources tab simply explains that detailed history begins with the next v1.1+ refresh.

The diff engine is deliberately fail-closed. If an older local source pack has only a content fingerprint and no retained Lua snapshot, Azeroth Guidebook reports that detailed before/after information is unavailable instead of comparing against the wrong baseline. Existing v3.14.0 Character Action Plan behavior and all reviewed guide datasets remain unchanged.


## v3.14.0 Character Action Plan

v3.14.0 makes **My Character** action-oriented without changing any reviewed guide recommendation. The new default **Action Plan** view consolidates the character audit into one source-aware to-do list based only on the guide source, content context, and build choices the player already selected.

- **Talents:** exact matches are complete; differences are counted individually and open directly in the existing source-specific node comparison.
- **Gear:** equipped rows are complete, items already owned in bags are surfaced as remaining because they are not equipped, and missing/not-owned rows retain direct **View in Guide** navigation. U.GG wording remains observational rather than being relabeled as editorial BiS; its `Crafted Items` popularity group is reference-only so it is not double-counted against real equipment slots, and its three observed trinket options are treated as alternatives for the character's two actual trinket slots.
- **Enchants:** recommended detected/equipped enchants are complete; different, missing, and no-item states become direct action rows. Gem alternatives remain informational rather than being scored as missing requirements.
- **Consumables:** source-listed alternatives are grouped by recognizable consumable type. Explicit alternate labels such as `Alt. Flask` collapse into the same Flask requirement, and Feast/Personal Food aliases collapse into Food. Owning any listed option completes that category, avoiding the old trap of making every alternative look like a separate required purchase; source items with no reliable category are shown individually by name instead of as duplicate generic `Consumable` rows.
- **Stats and Rotation:** remain guide references rather than pass/fail checks, with direct buttons to the currently selected source. Rotation is also added to **Open Selected Guide** from My Character.
- **Completed / Remaining:** completed rows are hidden by default and can be revealed with **Show Completed**. The preference persists in SavedVariables.
- The plan refreshes through the existing live character event system when talents, equipment, enchants, bags, or stats change. Characters below the level-90 guide target keep endgame action classification deferred.

The existing Overview, domain details, Needs Attention filters, source/context preservation, direct row highlighting, level-aware behavior, source refresh workflow, minimap launcher, and `/agb` behavior are preserved. No Talents, Rotation, BiS, Consumables, Enchants/Gems, Stats, or source-pack recommendation data changed in this release.

Live validation confirmed the finalized Action Plan behavior on Elemental Shaman: source alternatives collapse correctly, U.GG crafted/trinket references are not over-counted, **Show Completed** renders the expected completed rows without disrupting navigation, and Talent/Gear/Enchant/Consumable/Stats/Rotation actions all preserve the selected source/context and highlight the intended guide target.


## v3.13.0 validated one-click refresh production release

v3.13.0 promotes the fully live-validated source-refresh workflow from the v3.12.0 development cycle into the production baseline. The addon remains a normal Retail addon with all reviewed guide data bundled locally; automatic refresh is an optional enhancement provided by the separately installed **Azeroth Guidebook Companion v1.0.0-rc5**.

The in-game **Sources** tab keeps the same three one-click actions:

- **Refresh Current Source** refreshes the selected source for the active specialization.
- **Refresh Current Spec** refreshes Wowhead, Icy Veins, and U.GG for the active specialization.
- **Refresh All Sources** refreshes all three supported sources across all 40 Retail specializations.

Live end-to-end refresh validation completed successfully:

- **Refresh Current Source:** Elemental Shaman / Talents / Icy Veins completed as **No change** with `0 applied | 1 no change | 0 review required | 0 failed`.
- **Refresh Current Spec:** Elemental Shaman completed as **No change** with `0 applied | 3 no change | 0 review required | 0 failed`.
- **Refresh All Sources:** all **40 specs x 3 sources = 120 packs** completed as **No change** with `0 applied | 120 no change | 0 review required | 0 failed`.
- Windows completion notifications appeared, the final `/reload` reconciled results correctly, submitted requests cleared automatically, and the companion remained healthy through completed runs.

Companion lifecycle validation also completed successfully through several hardening iterations. The accepted **v1.0.0-rc5** companion preserves the validated refresh behavior and adds the final Windows lifecycle fixes: reliable Installed Apps registration, fail-closed uninstall metadata verification, immediate addon status reset on uninstall, graceful local stop requests, and native Windows process enumeration/termination without `tasklist.exe` or `taskkill.exe`. This native process path was validated after Norton CyberCapture interfered with the external command path used by an earlier candidate.

The final clean lifecycle test passed in both directions: rc5 appeared normally in **Windows Settings > Apps > Installed apps**, WoW reported **Companion: Ready | v1.0.0-rc5 | Feed: bundled**, uninstall removed the Windows app entry, and the next `/reload` immediately returned the Sources tab to **Companion: Not installed** with all three refresh buttons disabled.

This release intentionally does **not** change reviewed Talents, Rotation, BiS, Consumables, Enchants/Gems, Stats, My Character calculations, source selections, or the 2026-09-29 bundled data snapshot. v3.13.0 is the packaging/promotion milestone for the validated end-user refresh architecture plus the previously accepted minimap and `/agb` startup fixes. Refresh protocol remains `1`.

The current companion build is unsigned, so Windows SmartScreen or third-party reputation systems may warn or scan the installer on first use. Code signing is deferred; this does not change the companion's fail-closed refresh validation or addon behavior.

## v3.12.0 Source refresh workflow

v3.12.0 adds a CurseForge-friendly automatic source-refresh architecture while preserving WoW's sandbox limits. The addon itself remains a normal Retail addon and works immediately from its bundled reviewed guide data. Automatic refresh is an optional enhancement provided by the separately installed **Azeroth Guidebook Companion**.

The **Sources** tab exposes exactly three steady-state actions:

- **Refresh Current Source** checks the selected source for the active specialization.
- **Refresh Current Spec** checks Wowhead, Icy Veins, and U.GG for the active specialization.
- **Refresh All Sources** checks all supported sources across all 40 Retail specializations.

The public companion is a self-contained native Windows executable. End-user PCs do **not** need Python, Playwright, PowerShell scripts, browser automation, or direct scraping of Wowhead/Icy Veins/U.GG. Source capture/review remains a maintainer-side workflow; player PCs consume only Azeroth Guidebook-validated source packs.

For CurseForge rollout, the distribution is intentionally split:

1. `AzerothGuidebook-<version>.zip` is installed/updated normally by CurseForge.
2. `AzerothGuidebookCompanionSetup-<version>.exe` is downloaded once from the companion release link on the CurseForge project page.
3. The installer auto-detects common Retail WoW locations, installs per-user under `%LOCALAPPDATA%\AzerothGuidebook\Companion`, registers current-user startup plus a Windows uninstall entry, and starts the companion immediately. No Administrator rights are required.
4. CurseForge addon updates do not remove the companion because it lives outside `Interface\AddOns`.

The addon loads `CompanionStatus.generated.lua` and verifies companion state, heartbeat, and refresh protocol. If the companion is missing, stale, stopped, or incompatible, the three Refresh buttons are disabled while all bundled guide functionality remains available. The in-game UI never exposes setup commands.

Clicking a Refresh button queues a compact SavedVariables request and immediately performs the submission `/reload`. The hidden companion detects the request, verifies source/spec identity and SHA-256 integrity, and writes only validated non-destructive overrides to `GuideRefreshOverrides.lua`. `SourceRefreshState.generated.lua` records `Applied`, `No change`, `Review required`, or `Failed`. Accepted bundled `Guide*.lua` data is never overwritten. A final `/reload` is still required only when WoW needs to load a newly written result/status.

The companion supports a project-controlled HTTPS manifest and safely falls back to its embedded validated seed feed. The seed covers Wowhead, Icy Veins, and U.GG for all 40 supported specs so the client workflow is fully testable before a public feed is published; the seed intentionally reports **No change** against the matching bundled snapshot. Newer guide content becomes available only after the maintainer capture/review pipeline publishes a validated pack.

The companion and addon communicate through refresh protocol `1`, allowing their versions to evolve independently until a protocol change requires both sides to update.

`GuideRefreshOverrides.lua`, `CompanionStatus.generated.lua`, and `SourceRefreshState.generated.lua` ship as clean placeholders in the CurseForge addon ZIP. Machine-specific state remains under `%LOCALAPPDATA%` and is never included in addon releases.

Live validation completed for v3.15.0: Current Source, Current Spec, and All Sources history all reconciled correctly with Companion v1.1.0-rc1; the all-sources run compacted 120 unchanged packs; the five-run history rendered correctly; and a controlled change-presentation test verified Changed, No change, and Source date advanced states plus direct **View Updated Guide** navigation for Talents, Gear/BiS, Enchants & Gems, and Stats. After the test overlay, a real Current Source refresh restored genuine companion-generated history. Automated validation also includes **172/172** existing Python addon/tool regressions plus **6/6** native Go companion/setup tests; the Windows binaries cross-compile cleanly as x86-64 PE executables with no external runtime dependency.

## v3.11.0 Actionable issue navigation

v3.11.0 builds on the accepted v3.10.0 Needs Attention workflow by making individual issue rows actionable. Missing/not-owned Gear, Enchant issues, and absent Consumables now expose **View in Guide** actions that preserve the selected source/context, open the matching guide domain, highlight the exact source recommendation when it can be resolved, and scroll that row into view.

Talent issues now use the already-computed My Character comparison object to open the selected source directly in its node-level **Compare** view instead of requiring another manual Compare to Mine click. Exact issue navigation remains fail-closed: no source recommendation is rewritten, no source/context is changed, and a focus target that cannot be resolved simply opens the selected guide normally.

The v3.10.0 Overview, View Details, Needs Attention filters, scroll preservation, level-aware behavior, source-aware audit semantics, and All Details view remain unchanged. Reviewed guide datasets and Character audit calculations are unchanged; v3.11.0 changes navigation/presentation only.

Regression coverage: **200/200 passing**.

## v3.10.0 My Character issue focus

v3.10.0 adds a compact **Needs Attention** layer to the accepted v3.9.0 My Character dashboard. After live layout validation, the controls now sit below **Open Selected Guide** and **View Details** so an issue-only result renders immediately beneath the buttons that selected it. The block surfaces only auditable domains with current gaps: talent differences, missing/not-owned gear, enchant problems, and absent source-listed consumable items. Stats remain informational and are never turned into an issue score.

Each Needs Attention button opens an issue-only detail view that hides successful rows while keeping the existing source/context provenance and direct guide jump. U.GG gear gaps remain explicitly descriptive observed-player reference gaps rather than editorial Best-in-Slot failures. Gem alternatives are not classified as missing issues because reviewed source gem lists can contain alternatives rather than requirements. Consumable absence remains a factual bag check and does not imply every source-listed alternative must be owned.

Characters below the level-90 guide target do not receive urgent endgame issue classification; the Needs Attention area explains that those guide gaps are informational until the target level while the normal factual audit remains available. Existing Overview, domain detail filters, Open Selected Guide actions, and All Details remain unchanged.

No reviewed guide recommendation data or Character audit semantics change in v3.10.0.

Regression coverage: **196/196 passing**.

## v3.9.0 Actionable My Character navigation

v3.9.0 builds on the accepted v3.8.0 compact My Character dashboard by adding direct navigation from audit results to the matching guide domain. The Overview now includes an **Open Selected Guide** action row for Talents, Gear/BiS, Enchants & Gems, Consumables, and Stats, with the currently selected source shown in each button label.

Each detail view also includes its own **Open ... Guide** action. These jumps return Browse Guides to the active character specialization and open the target domain without changing the saved guide source, U.GG Raid/Mythic+ context, or selected source build. Returning to My Character retains the current session's detail filter.

No reviewed guide recommendation data or Character audit semantics change in v3.9.0.

## v3.8.0 My Character usability

v3.8.0 keeps the accepted v3.7.0 source-aware and level-aware audit logic intact while making the **My Character** tab substantially easier to scan. My Character now opens to a compact **Audit Overview** instead of immediately rendering every row from every domain. The overview summarizes Talents, Gear, Enchants & Gems, Consumables, and live Stats together with each domain's currently selected source/context.

A new **View Details** filter provides `Overview`, `Talents`, `Gear`, `Enchants & Gems`, `Consumables`, `Stats`, and `All Details` views. Selecting one domain renders only that detailed audit, reducing scroll length while preserving the original full audit under **All Details**. The selected view is retained for the current session and does not change any guide-source selection.

No reviewed guide recommendation data changes in v3.8.0. Talent comparisons, U.GG observed semantics, Equipped/Owned/Not owned inventory states, permanent-enchant verification, gem detection, consumable bag auditing, live stats, and the level-90 informational guidance model all remain unchanged.

Regression coverage: **192/192 passing** in stable file-level/chunked runs.

## v3.7.0 source-aware My Character

v3.7.0 extends the live **My Character** dashboard so every auditable guide domain follows that specialization's currently selected reviewed source instead of only Talents doing so. Talent comparison behavior from v3.5 remains unchanged.

- **Best in Slot / Gear** follows the selected BiS source. Wowhead and Icy Veins remain editorial Best-in-Slot audits. U.GG is shown separately as **Observed Gear** with Raid/Mythic+ context and factual Equipped / Owned / Not owned inventory states; observed popularity is never relabeled editorial BiS.
- **Consumables** follows the selected available Consumables source and audits exact item entries in the character's bags. Non-item source references are kept out of bag ownership counts rather than being reported missing.
- **Enchants & Gems** follows the selected source. Icy Veins uses its reviewed editorial alternatives; U.GG uses observed enchant/gem selections and is explicitly labeled observed player data. Existing permanent-enchantment tooltip/effect-ID verification remains fail-closed.
- **Current Stats** still reports the live character percentages, while its reference priority now follows the selected Stats source and U.GG content context. U.GG priority is labeled descriptive observed player data rather than an editorial recommendation.
- Cross-source slot aliases were expanded for Helm/Back/Bracers/Main Hand/Trinket/Rings/Wrist so Icy Veins and U.GG ownership/enchant audits map cleanly to live WoW equipment slots.

No reviewed guide recommendation dataset changed in v3.7.0; this release changes only which already-reviewed source My Character audits and how source semantics are labeled.

Regression coverage: **188/188 passing** in stable file-level/chunked runs.

## v3.6.0 rich Icy Veins Rotation

Generic source-authored guidance rows that do not name an exact linked spell/item use a neutral note icon; source ordered lists stay numbered and source unordered lists stay bulleted.

v3.6.0 promotes the reviewed Icy Veins rotation expansion into production for **all 40 Retail specializations**. The dedicated rotation-only review completed **40/40 captured, 0 partial, 0 errors** and produced **162 source-declared Hero/build presets, 1,127 structured rotation blocks, and 6,757 source-visible actions**.

The browser collector treats Icy Veins' own interactive rotation UI as the authority. For each source Hero/build preset it snapshots only rows made visible by that preset, preserving ordered vs. bulleted lists, subsection/lead text, recommended/source-selected state, and exact linked spell/item references. Hidden optional rows are not inferred or blended across presets.

The reviewed data is bundled in `GuideIcyRotations.lua`. In-game Icy Veins Rotation now renders the same rich interaction style as Wowhead: explicit Hero/source and build-context selectors, `[Selected]` state, numbered or bulleted priority rows, spell/item icons, WoW tooltips, source notes, and the original Icy Veins source URL. Healing-spec priority lists are supported alongside DPS/tank openers and rotations.

The accepted v3.5.0 Talent, BiS, Consumables, Enchants/Gems, Stats, U.GG, My Character, and Wowhead datasets remain unchanged. v3.6.0 changes only the reviewed Icy Veins Rotation presentation/data pack plus release metadata.

The accepted review audit is retained at `tools/reviewed_icy_rotations_v360/MERGE_AUDIT.json`; raw capture HTML is intentionally excluded from the installable addon.

Regression coverage: **185/185 passing** in stable file-level/chunked runs.

## v3.5.0 unified source presentation

v3.5.0 keeps the accepted v3.4.0 all-spec source data intact while unifying how Wowhead, Icy Veins, and U.GG are presented inside the Guide Browser. The same guide domain now uses the same visual language regardless of provider: shared domain titles, consistent metadata placement, item rows, build selectors, source controls, tooltips, and copy/import actions. Source semantics remain explicit and are never blended.

- **Icy Veins** now uses the same domain-level structure as Wowhead for Talent Builds, Rotation & Cooldowns, Best in Slot, Consumables, Enchants & Gems, and Stat Priority. Exact Icy Veins talent captures can be viewed as the normal in-game talent tree, compared to the active character by decoded node selection, copied directly, and submitted unchanged to WoW's native loadout importer when the matching specialization is active. WoW performs the final loadout validation.
- **U.GG** keeps its Raid/Mythic+ observed-player context and metrics, but Talent Builds, observed Gear, Enchants/Gems, and Stat Priority now use the same card/row conventions as the editorial sources. Exact U.GG talent captures use the same preview/compare/copy/import workflow while U.GG continues to be labeled observed player data rather than editorial recommendations. When a U.GG transport omits automatically granted starter ranks, Azeroth Guidebook restores only ranks that the live Retail tree explicitly marks with a met Blizzard `Granted` condition; optional/choice talents are never inferred.
- **Talent utilities are now source-consistent:** Wowhead, Icy Veins, and U.GG expose Paste / Preview Build and Preview My Build in addition to each source's exact-build actions. Fail-closed source/context rows with no exact captured build still do not gain View/Compare/Import/Copy Build actions.
- Icy Veins consumables are categorized into familiar Flask, Potion, Food/Feast, Weapon Buff, and Augment Rune rows when the captured item name supports that classification. No recommendation is inferred when a category cannot be determined.
- Icy Veins Rotation remains review-conservative: the accepted production capture stores source subsection names and structured step counts, so v3.5.0 presents those subsections in the unified rotation-card layout without inventing individual priority actions or variant labels that were not review-mapped.
- The three accepted fail-closed U.GG talent contexts remain unchanged: Holy Paladin Mythic+, Balance Druid Raid, and Discipline Priest Mythic+. U.GG domains without a source-reported update time show their captured snapshot date instead of `unknown at capture`.

The underlying v3.4.0 reviewed multi-source datasets and fail-closed decisions are unchanged. My Character talent auditing is now source-aware: it follows the currently selected Talents source/build for the active specialization and shows the source/context in the dashboard instead of silently reverting to Wowhead. U.GG builds are normalized at runtime only for deterministic Blizzard-granted starter ranks; if the level-90 build is still incomplete after that normalization, it remains previewable/comparable/copyable but is not offered to WoW's native loadout importer.

Regression coverage: **178/178 passing** in stable file-level/chunked runs.

## v3.4.0 all-spec multi-source expansion

v3.4.0 expands the reviewed multi-source Guide Browser from the original five-spec proof to **all 40 Retail specializations**. Wowhead remains the existing bundled production quick-reference dataset; Icy Veins and U.GG stay explicitly separate rather than being blended into one recommendation.

Source semantics remain distinct:

- **Wowhead** remains the existing production quick-reference dataset and the source used by My Character.
- **Icy Veins** is treated as editorial guide guidance. All 40 specs now expose reviewed Icy Veins Talents, BiS, Consumables, Enchants/Gems, Stats, and concise Rotation evidence.
- **U.GG** is treated as observed player data. All 40 specs now expose Raid/Mythic+ Talents, observed Gear, Enchants/Gems, Stats, and source-relative population/update context. U.GG Consumables and Rotation are not inferred from another source.

The 35-spec expansion capture completed **487/490 captured, 3 partial, 0 errors**. Review resolved the Holy Priest Icy Veins Enchants partial directly from the captured `Slot / Best / Alternative` source table: all 14 recommendation names mapped exactly to captured item IDs. Two new U.GG Talent contexts remain deliberately fail-closed because no exact Blizzard import string was present in the captured source evidence: **Balance Druid Raid** and **Discipline Priest Mythic+**. The existing **Holy Paladin Mythic+** U.GG Talent limitation from v3.3.0 remains fail-closed as well. Observed metrics remain available for those contexts; no build is borrowed from another source or context.

The Guide Source selector remains stored per specialization and guide domain. U.GG keeps a separate Raid/Mythic+ context selector. Selected sources display both an explicit **Current source** line and a **[Selected]** marker. The U.GG content-context selector and Rotation Hero/source selector now use the same explicit state treatment with **Current context** / **Current hero/source** text and **[Selected]** labels, avoiding WoW's disabled-button gray styling being mistaken for an inactive choice. The underlying source/context mapping is unchanged. My Character continues to audit the validated Wowhead production baseline; source-aware character auditing remains a separate future feature.

The accepted expansion evidence is retained under `tools/reviewed_multisource_expansion_v340`, with a production review audit and a deterministic `build_multisource_production.py` generator for future reviewed rebuilds. Raw HTML is intentionally not bundled with the addon package.

Regression coverage: **176 tests collected; all 176 passed in stable file-level/chunked runs**.



## v3.2.0 selective refresh automation

v3.2.0 adds a review-only selective refresh orchestrator on top of the validated 240-entry freshness baseline. `Run-SelectiveRefresh.ps1` accepts a current `FreshnessReviewBundle.zip`, validates its baseline version and source URLs against the installed toolset, groups only entries explicitly marked `changed`, and runs the appropriate Talent, BiS, Consumables, Enchants/Gems, Stats, or Rotation collectors for exactly those specialization IDs.

The workflow never auto-merges generated Lua. `source_older`, `baseline_missing`, `unknown`, and `error` remain manual-review states. Collector output is assembled under one `SelectiveRefreshReviewBundle.zip` with the original freshness summary, production baseline snapshot, per-domain capture artifacts, a machine-readable plan/summary, and a human-readable report. Playwright setup is performed once per selective-refresh run.

A stale freshness bundle is rejected by default when its baseline version or source URLs do not match the current production baseline. The v3.2.0 baseline still covers all **40 Retail specs x 6 domains = 240 entries** with reviewed source dates. No validated in-game guide recommendation changes in this release. Automated regression suite: **146/146 passing**.


## v3.1.0 freshness workflow

v3.1.0 promotes the validated source-freshness checker into the maintained toolset. The baseline covers all 40 Retail specs across Talents, BiS, Consumables, Enchants/Gems, Stats, and Rotation (240 checks). A newer Wowhead guide date flags that spec/domain for selective review; it never auto-replaces production recommendations.

The first selective review found Havoc Talents editorially newer but recommendation-identical, so only its reviewed source metadata advanced to 2026-09-24. Elemental Shaman Stats had lacked historical date metadata and the fresh capture also exposed an outdated native priority; Elemental now uses the exact reviewed Farseer/Stormbringer priorities from the current guide.

Selective-capture manifests for BiS, Consumables, Enchants/Gems, and Stats now include all 40 specs, including the six native Shaman/Demon Hunter packs. Automated regression suite: **139/139 passing**.

## My Character

v3.0.6 includes the read-only **My Character** dashboard for the active Retail specialization. It audits the live character against the already-reviewed guide data without assigning a score or modifying any guide recommendation.

The dashboard currently includes:

- exact talent comparison when the selected guide build has a validated bundled import transport;
- slot-family-aware BiS status (`Equipped`, `Owned`, or `Missing`), including interchangeable ring/trinket slots;
- exact recommended gem detection from equipped item links;
- permanent-enchantment name validation from WoW's typed equipped-item tooltip data, with crafted quality/rank ambiguity kept fail-closed;
- bag counts for source-listed consumables; and
- a live Critical Strike / Haste / Mastery / Versatility snapshot beside the source-listed stat priority.

### v3.0.6 current runtime and talent-source status

The enchant audit follows source slot semantics literally. A generic `Weapon` recommendation audits the main hand only; source-explicit `Main Hand`, `Off Hand`, and `Both Weapons` labels remain independently supported. The client-provided permanent-enchantment line is compared against all source-listed alternatives for that slot. Spell/runeforge recommendations can be reported as an exact equipped recommendation by name; crafted item enchant matches are shown as recommended while quality/rank remains unverified unless the client exposes uniquely distinguishing evidence. Unknown enchant text remains fail-closed.

v3.0.6 also introduces a deliberately small source-verified permanent-enchant effect mapping layer. Effect **7935** is tied to item **240133 Sunfire Silk Spellthread** (the 41 Intellect / 115 Stamina application), allowing that exact reviewed leg enchant to verify even when WoW exposes only stat text instead of its name. Unmapped effects still use the existing fail-closed name/tooltip path.

Single-option Talent guide rows now use the same normal 298px button width as each column of a multi-option row instead of stretching a lone Farseer/Wildstalker-style button across the full content pane.

Live Best-in-Slot ownership/equipped validation is confirmed in-game: source-listed items correctly report Equipped, Owned in bags, or Missing.

Talent-source reconciliation remains complete at **269 exact builds / 0 Pending variants**. The false Elemental Stormbringer Raid and Restoration Druid Keeper of the Grove Delves duplicate source rows remain excluded rather than being relabeled under the wrong Hero tree.

The My Character view refreshes while open when equipment, bags, talents, trait configuration, or combat ratings change. Choosing **My Character** always returns Browse Guides to the active character specialization.

Automated regression suite: **128/128 passing**.

---

# Azeroth Guidebook v2.9.1

A Retail World of Warcraft addon that keeps concise PvE guide reference data in-game so common Wowhead lookups do not require alt-tabbing.



## v2.9.1 - All-spec Rotation & Cooldowns coverage

v2.9.1 completes the reviewed **Rotation & Cooldowns** rollout across all **40 Retail specializations**. The 35-spec expansion contributes **302 exact structured blocks / 2,529 ordered actions / 0 Pending blocks**; combined with the unchanged five-spec v2.9.0 proof set, production now contains **357 exact structured blocks / 2,943 ordered actions**.

Expansion review kept source structure fail-closed instead of forcing every guide into one template. Arcane's Hero-tree-specific generic Priority layout and Fury's plural Single Target Rotations layout are recognized directly; healer guides can preserve source-defined Raid, Mythic+, Hero-tree, and Healing/Damage priority sections. Arms and Balance are no longer required to expose a separate ordered opener when the source does not publish one. Havoc's source AoE block is classified correctly, while Destruction's unresolved long-form cooldown fragment remains excluded rather than being promoted as exact data.

The Rotation collector and 40-spec manifest are hardened around those reviewed layouts for future refreshes. The original five proof reports remain unchanged, and validated Talent, BiS, Consumables, Enchants/Gems, and Stats recommendation data are unchanged. The automated regression suite passes **109/109 tests**.


## v2.9.0 - Reviewed Rotation & Cooldowns proof merge

v2.9.0 begins the reviewed **Rotation & Cooldowns** rollout. The first five production specs are **Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue**, contributing **55 exact structured blocks / 414 ordered actions / 0 Pending blocks**. Exact linked spell/item IDs are retained for normal WoW tooltips and Shift-click chat linking.

Proof review removed source-rendering artifacts without changing recommendation order: Blood Death Knight expandable explanation bodies are no longer appended to priority actions; Frost preserves Spellslinger/Frostfire and a separate Pre-Combat block; Brewmaster preserves Shado-Pan/Master of Harmony; and Subtlety preserves Deathstalker/Trickster while splitting the source-concatenated single-target/AoE opener sequences. Source-valid one-line cooldown notes are accepted inside the Major Cooldowns scope.

The new **Rotation** tab is context-aware and displays only the selected Hero/source context plus generic blocks. The 40-spec capture manifest is now split into the five reviewed `proof` specs and **35 `expansion` specs**. Existing Talent, BiS, Consumables, Enchants/Gems, and Stats recommendation data are unchanged. The automated regression suite passes **104/104 tests**.


## v2.8.1 - All-spec Stats coverage

v2.8.1 completes the reviewed progressive **Stats** rollout. The 29-spec expansion contributes **63 exact source-listed variants / 0 Pending variants**; combined with the five v2.8.0 proof specs, `GuideStats.lua` now contains **34 progressive specs / 75 exact structured variants**. The six existing native Shaman and Demon Hunter Stats references remain intact, bringing Stats coverage to **all 40 Retail specializations**.

Review preserved meaningful source context instead of flattening duplicate labels. Beast Mastery keeps Pack Leader All Situations plus Dark Ranger Single-Target/AoE priorities; Discipline and Holy Priest retain Raid vs. Dungeons/Mythic+ scopes; and the stray source-rendering `?` before Feral Wildstalker is sanitized without changing its ordered priority. The collector now preserves these context qualifiers automatically for future captures.

Reviewed expansion artifacts, original/reviewed summaries, source-evidence notes, and a merge audit are retained under `tools/reviewed_stats_expansion`. No validated Talent, BiS, Consumables, or Enchants/Gems recommendation data changed. The automated regression suite passes **86/86 tests**.

## v2.7.1 - Reviewed Enchants & Gems expansion merge

v2.7.1 completes the reviewed Enchants & Gems rollout for all **34 progressive specialization packs**. The 29-spec expansion contributes **304 exact source-linked recommendations / 0 Pending rows**; combined with the five v2.7.0 proof specs, the generated pack now contains **359 exact recommendations across 34/34 progressive specs**. The six existing Shaman and Demon Hunter native packs remain unchanged, bringing Enchants & Gems coverage to **all 40 Retail specializations**.

The expansion review also hardens the collector for Wowhead layout differences discovered during capture. Unholy Death Knight uses a dedicated **Best ... Enchants** table followed by a separate Gems section, so the collector now has a tightly scoped split-layout fallback that still requires exact linked item/spell IDs. Diamond labels such as `Algari Diamond` and `Diamond (one of)` are classified as gems, and mixed generic `Gems` rows are separated into the one-per-character Eversong Diamond and normal socket gems without changing their captured entity IDs.

Talent, BiS, and Consumables data remain unchanged from v2.7.0. The automated regression suite passes **67/67 tests**. Stats are the next progressive data phase.

## v2.7.0 - Reviewed Enchants & Gems proof merge

v2.7.0 begins the reviewed Enchants & Gems rollout for the 34 progressive specialization packs. The first five exact proof specs are **Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue**. Their live Wowhead Best Gems and Enchants tables contribute **55 exact source-linked recommendations / 0 Pending rows** after correcting two collector edge cases discovered by the proof run.

The collector now recognizes both `Diamond` and `Eversong Diamond` source labels as gem rows, normalizes explicit main-hand/off-hand labels, and preserves repeated identical item/spell IDs when Wowhead lists the same recommendation more than once with different contexts. This is required for Blood Death Knight, where Rune of Sanguination is source-listed separately for Deathbringer single-target and San'layn. The UI now displays captured enchant/gem context labels instead of discarding them.

The reviewed proof reports and source-table evidence are retained under `tools/reviewed_enchants_proof`. No validated Talent import string, BiS item selection, or Consumables recommendation was replaced by this merge.

## v2.6.2 - All-spec Consumables coverage

v2.6.2 completes the Consumables phase across **all 40 Retail specializations**. The targeted Evoker retry resolved Preservation directly from its source table plus exact Flask subsection fallback, and Augmentation from exact item-linked type-specific consumables subsections captured in the live Wowhead DOM when its visible summary did not hydrate as a literal HTML table. No item or spell IDs were invented.

The generated non-Shaman/Demon Hunter Consumables layer now contains **34 specs / 268 exact recommendations / 0 Pending rows**. Shaman and Demon Hunter retain their existing native packs, so the Consumables tab is available across the full 40-spec Guide Browser. Augmentation preserves separate `(feast)` and `(personal)` food context from the source section.

The collector now has a conservative section-only recovery path: it accepts only recognized Flask/Potion/Weapon Buff/Augment Rune/Food/Tea subsection headings, requires exact linked Wowhead item or spell IDs, ignores Enchants/Gems headings, and still fails closed when fewer than the required consumable categories can be recovered.

## v2.6.1 - Reviewed bulk Consumables merge

v2.6.1 reviews the 29-spec Consumables expansion capture and promotes the **27 exact specs** into production. Combined with the five validated proof specs, the generated non-Shaman/Demon Hunter layer now contains **32 specializations and 253 exact item/spell recommendations**. Shaman and Demon Hunter retain their existing native packs, bringing in-game Consumables coverage to **38 of 40 Retail specializations**.

Two Evoker specs remain intentionally fail-closed: **Preservation** exposed a `Flask = See Below` placeholder whose exact alternatives live in the following Flask subsection, and **Augmentation** did not hydrate its otherwise source-published consumables table during the first Chromium pass. v2.6.1 adds row-scoped subsection fallback for placeholder recommendations plus a progressive deep-scroll hydration retry. Target only those two specs from `AzerothGuidebook\tools` with:

```powershell
.\Capture-WowheadConsumables.ps1 -ShowBrowser -AllowPending -ExpansionOnly -SpecID 1468,1473 -OutputDirectory ".\capture-consumables-evoker-retry"
```

The review also keeps the Consumables tab cleanly separated from the future Enchants & Gems pack: Unholy Death Knight's source-table `Diamond` and `Other Gems` rows are retained in diagnostics but not emitted as consumables. Bulk category aliases now normalize Feast/Personal Food/Invisibility Potion labels, and source qualifiers such as `(Raid)`, `(Mythic+)`, `(Preferred)`, `(Situational)`, `(feast)`, and `(personal)` are preserved when they can be isolated exactly.

## v2.6.0 - Full Consumables expansion collector

v2.6.0 expands the build-time Consumables source manifest from the five reviewed proof specs to all **34 non-Shaman/Demon Hunter specializations**. The five validated v2.5.1 specs remain tagged `proof`; the remaining **29 specs** are tagged `expansion` for the next bulk source capture.

Run only the unreviewed expansion group from `AzerothGuidebook\tools`:

```powershell
.\Capture-WowheadConsumables.ps1 -ShowBrowser -AllowPending -ExpansionOnly -OutputDirectory ".\capture-consumables-expansion"
```

The run writes `ConsumablesReviewBundle.zip`, containing the selected manifest snapshot, summary, generated Lua, and every per-spec diagnostic report. Partial specs remain diagnostic-only and are not emitted into generated in-game data. The installed v2.5.1 Consumables proof dataset is unchanged in this collector release.

## v2.5.1 - Reviewed Consumables proof data merged

v2.5.1 promotes the first reviewed automated Consumables capture into the live addon for **Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue**. The proof bundle contained **33 exact source rows / 46 exact recommendations / 0 Pending rows**, including one exact spell-linked recommendation (Holy Paladin Lightsmith `Rite of Sanctification`) alongside item-linked consumables.

The five specs now expose the **Consumables** tab in-game. Multiple source-listed alternatives remain separate rows with their captured context labels (for example `best`, `alternative`, `default`, Hero-tree context, or feast/personal food choices). Item and spell entries retain normal WoW tooltips and Shift-click chat linking.

The reviewed reports, summary, and manifest snapshot are retained under `tools/reviewed_consumables_proof`. No Talent import string or BiS item ID changed from v2.5.0.

## v2.5.0 - Automated Consumables pipeline proof set

v2.5.0 begins the next progressive data-pack phase without changing the reviewed all-spec Talent or BiS item selections. A new build-time Playwright collector targets the live Wowhead **Enchants & Consumables** pages for five proof specializations: **Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue**.

The collector locates the source-listed **Best ... Consumables** table, preserves its visible type labels, and requires every recommendation row to expose one or more exact Wowhead-linked entities. Normal consumables are captured by item ID. Source-listed class abilities used as consumable-equivalent recommendations are also supported by exact spell ID, allowing cases such as a class-specific weapon buff to remain source-faithful instead of being converted into an invented item. Rows without an exact linked item/spell remain Pending, and any specialization with a Pending row is omitted from the generated in-game data map.

Run the proof set from `AzerothGuidebook\tools` with:

```powershell
.\Capture-WowheadConsumables.ps1 -ShowBrowser -AllowPending -OutputDirectory ".\capture-consumables-proof"
```

The run creates `ConsumablesReviewBundle.zip`, containing the summary, selected manifest snapshot, generated Lua, and all five per-spec diagnostics. Upload that one ZIP for review. Until reviewed capture data is merged, the five proof specs keep their existing tab availability and v2.5.0 does not enable any new Consumables tabs.

The generic item-row renderer now also supports exact spell-linked recommendations with normal WoW spell tooltips and Shift-click chat links. v2.5.0 also applies the small BiS text sanitation identified during the v2.4.0 visual review: compact `|` source delimiters are displayed with readable separators and stray trailing `Explanation` artifacts are removed from captured crafting text. No Talent import string or BiS item ID is changed.

## v2.4.0 - Reviewed BiS coverage across all Retail specializations

The 29-spec bulk BiS expansion has been reviewed and merged. Together with the five previously validated proof specs, the generated BiS layer now contains **34 non-Shaman/Demon Hunter specializations, 36 gear sets, and 570 exact source-backed gear rows with 0 Pending rows**. Existing Shaman and Demon Hunter BiS packs remain intact, so the Guide Browser now has Best-in-Slot coverage for **all 40 Retail specializations**.

The live expansion capture was exact for 27 of 29 specs. The two partial reports were source-valid slot-label edge cases only: Brewmaster Monk used `Weapons (1h)`, and Subtlety Rogue used hyphenated `Main-Hand` / `Off-Hand`. All three affected rows already contained valid Wowhead item IDs, names, and sources, so they were promoted only after adding explicit slot aliases. No item was guessed or substituted.

Mistweaver Monk correctly retains separate **Raid** and **Mythic+** BiS gear sets from its two source tables. The collector remains fail-closed for missing item IDs, ambiguous multi-table headings, and unknown slot labels.

Reviewed expansion diagnostics are retained under `tools/reviewed_bis_expansion` so future refreshes can be compared against the accepted production state.

The complete **268 exact / 3 Pending talent dataset** remains unchanged. BiS, Consumables, and Enchants/Gems are populated across all 40 Retail specializations. Stats are progressive: the six native Shaman/Demon Hunter packs plus the five reviewed v2.8.0 proof specs are enabled, while the remaining 29 progressive specs stay fail-closed pending review.

## v2.3.0 - Bulk BiS expansion collector

The reviewed v2.2.1 BiS proof packs remain unchanged in-game while the build-time collector expands from five proof specs to **all 34 non-Shaman/Demon Hunter specializations**. The manifest now marks the five reviewed specs as `proof` and the remaining **29 specs** as `expansion`, so the next live run can skip already reviewed pages with `-ExpansionOnly`.

The bulk collector also hardens unknown multi-table pages: a single Best-in-Slot table still becomes the stable `Overall` set, while multiple tables without predeclared variants must expose a source heading from which a distinct set name can be inferred. If a multi-table page cannot be classified cleanly, that specialization remains diagnostic-only instead of bundling ambiguous `Overall` duplicates. Slot normalization now also accepts additional source labels such as 2H weapons, amulets, and pants.

Each bulk run now creates `BiSReviewBundle.zip`, containing the summary, selected-source manifest snapshot, generated Lua, and every per-spec JSON report. This reduces the review handoff for the 29-spec expansion to a single upload.

Run only the remaining 29 specs from `AzerothGuidebook\tools` with:

```powershell
.\Capture-WowheadBiS.ps1 -ShowBrowser -AllowPending -ExpansionOnly -OutputDirectory ".\capture-bis-expansion"
```

The installed v2.2.1 reviewed BiS data (95 exact rows / 6 gear sets) and the complete talent dataset are preserved unchanged in v2.3.0.

## v2.2.1 - First reviewed automated BiS packs

The five-spec proof capture has been reviewed and promoted into the addon. **Blood Death Knight, Restoration Druid, Frost Mage, Holy Paladin, and Arms Warrior** now have source-backed BiS tabs populated from the captured Wowhead tables. The reviewed pack contains **95 exact gear rows across 6 gear sets** (Blood exposes separate Deathbringer and San'layn sets).

The proof run exposed two collector edge cases rather than bad source data: Wowhead uses the visible slot label `Boots`, which was not matching the original singular `boot` alias, and the Arms Warrior table includes a trailing blank column that caused the naive source fallback to miss the actual third-column source. v2.2.1 fixes both collector behaviors and repairs the already captured proof data without changing any item IDs or item names.

The existing **268 exact / 3 Pending** talent dataset is unchanged. Other non-Shaman/Demon Hunter specializations remain talent-only until their BiS pages are captured and reviewed.

## v2.2.0 - Automated Best-in-Slot pipeline proof set

v2.2.0 begins the next data-expansion phase without changing the validated talent dataset. The addon can now enable guide tabs independently per specialization instead of treating every non-Shaman/Demon Hunter pack as all-or-nothing talent-only data. A generated BiS pack can therefore enable **BiS** for one spec while Consumables, Enchants/Gems, and Stats remain disabled until their own reviewed data is available.

The new build-time BiS collector targets an initial five-spec proof set: **Blood Death Knight, Restoration Druid, Frost Mage, Holy Paladin, and Arms Warrior**. It reads the source-listed Wowhead Best-in-Slot table(s), requires an exact Wowhead item ID for every required row, records the visible source/update date, captures the first recommended crafting-order list when available, and emits reviewable per-spec JSON plus a fail-closed `GuideBiS.generated.lua`. Partial specs are omitted from the generated in-game data map rather than being filled with guessed items.

BiS data now supports multiple complete gear sets when the source publishes them. This is needed for guides such as Blood Death Knight, where the page can list separate Hero-tree BiS tables. The BiS tab remembers the selected gear set per specialization. Existing hand-authored Shaman/Demon Hunter BiS data continues to use the original single-set format unchanged.

Run the proof collector from `AzerothGuidebook\tools` with:

```powershell
.\Capture-WowheadBiS.ps1 -ShowBrowser -AllowPending -OutputDirectory ".\capture-bis-proof"
```

After review, exact proof specs can be merged by replacing the empty `GuideBiS.lua` scaffold with the generated data.

## v2.1.1 - Recommendation metadata correctness patch

- Recognizes Wowhead `(Recommended)` markers in addition to `(Best)` when choosing the current guide recommendation.
- Corrects Holy Paladin Delves to default to **Lightsmith** and Windwalker Delves to default to **Conduit of the Celestials** when those source rows are marked Recommended.
- Preserves all 268 exact Blizzard import strings from v2.1.0 unchanged.
- Compacts long selector labels while retaining the complete source label in the hover tooltip.
- Keeps all existing Pending/fail-closed safeguards unchanged.

## v2.1.0 - Exact talent builds across all 40 Retail specializations

The automated expansion capture populated the 34 talent-only specializations added in v2.0.0. Across those new specs, the collector accepted **225 exact source-validated builds** and kept **2 Druid Restoration Delves variants Pending** because the capture attributed the same Blizzard export to both Keeper of the Grove and Wildstalker.

Combined with the already validated Shaman and Demon Hunter data, the bundled talent dataset now contains **268 exact builds / 3 Pending variants across all 40 Retail specializations**. The remaining Pending variants are:

- Elemental Shaman - Stormbringer - Raid
- Restoration Druid - Keeper of the Grove - Delves
- Restoration Druid - Wildstalker - Delves (Best)

All exact variants remain subject to live in-game specialization, active Hero-tree completeness, expected Hero-tree, and import round-trip validation before View / Compare / Import actions are allowed. The 34 non-Shaman/Demon Hunter specs remain talent-only for now; their BiS, Consumables, Enchants/Gems, and Stats tabs will be populated separately.

The Talent page now prefers the captured guide build's source update date, so newly populated specs show the actual Wowhead guide date instead of the generic `live source` placeholder when that metadata is available.

## v2.0.0 - All Retail specializations

The Guide Browser now lists all 40 Retail specializations. Shaman and Demon Hunter keep their full reference packs; every other class begins with a talent-only pack so exact Wowhead Raid, Mythic+, and Delves builds can be captured and merged without waiting for BiS/consumable/enchant/stat data.

The browser-backed collector manifest now covers every spec and includes the expected Hero Talent trees for fail-closed classification. `Capture-WowheadBuilds.ps1 -NewClassesOnly` captures only the 34 newly supported specs. The collector also auto-detects Wowhead's visible guide update date when the manifest does not pin one.

## v1.9.8 scope - direct Build-link validation and final source conflict

v1.9.8 advances the production dataset to **43 exact builds / 1 Pending build**. Two Vengeance Raid variants are now sourced directly from their row-scoped Wowhead `/talent-calc/blizzard/` Build URLs after Blizzard header/spec validation. The collector prefers those exact URLs without navigating through Wowhead's calculator, which avoids ad/redirect interference.

The sole remaining Pending variant is **Elemental Stormbringer Raid**. Wowhead currently exposes the exact same Blizzard export for that Stormbringer row as for **Farseer Raid**, so Azeroth Guidebook intentionally keeps Stormbringer Raid fail-closed rather than assigning a cross-Hero duplicate.

Installed build status:

- Elemental: 5 exact / 1 pending
- Enhancement: 8 exact / 0 pending
- Restoration: 6 exact / 0 pending
- Havoc: 6 exact / 0 pending
- Vengeance: 10 exact / 0 pending
- Devourer: 8 exact / 0 pending

The collector also ignores embedded calculator **Export Talents** controls when enumerating guide-table Copy rows, uses explicit Copy wording such as **Copy Cleave** and **Copy Council** to distinguish named variants, and still refuses cross-Hero duplicate exports.

No previously validated exact string was changed in v1.9.8; two previously Pending Vengeance rows became exact.

## v1.9.3 scope - scalable variant UI and targeted pending-capture retries

v1.9.3 keeps the v1.9.2 production build dataset unchanged while improving how larger variant sets are presented and how unresolved Wowhead rows are recaptured. Guide variants now use a compact two-column selector instead of the old three-across layout, preventing long names such as Single Target, Raid Cleave, and Raid Council from visually colliding. Hovering a variant shows its full source label, Hero tree, recommendation state, and exact/pending status.

Older talent-description text that told users to manually paste live exports has been removed where the addon now owns exact or fail-closed variant data. The collector also adds a delayed, source-scoped fallback that can read an import value from the clicked row or its explicitly linked popover/dialog without returning to unsafe page-wide input scanning. Bulk capture can now target selected specialization IDs for faster retries of the remaining Pending rows.

The installed exact/Pending data itself is intentionally unchanged from v1.9.2.

## v1.9.2 scope - first production automated build dataset

v1.9.2 promotes the safe portion of the hardened browser capture into the addon. The 2026-09-25 run produced **29 automatically captured exact builds** and **14 fail-closed pending variants** across the six supported specializations. The previously hand-validated Elemental Farseer Raid build is preserved, bringing the installed dataset to **30 exact builds** and **13 pending variants**.

Current capture status:

- Elemental: 5 exact / 1 pending after preserving the validated Farseer Raid build
- Enhancement: 4 exact / 3 pending
- Restoration: 6 exact / 0 pending
- Havoc: 6 exact / 0 pending
- Vengeance: 4 exact / 6 pending
- Devourer: 5 exact / 3 pending

Pending entries remain visible but do not expose View / Compare / Import / Copy actions until a later automated capture produces an unambiguous, spec-valid Blizzard export. No pending value is guessed.

## v1.9.1 scope - hardened automated exact-build collection

v1.9.1 adds a **browser-backed Wowhead build collector** so exact guide strings do not need to be copied by hand as the normal development workflow. The collector drives the live guide with Chromium/Playwright, clicks source Copy controls, captures Wowhead's exact clipboard value, validates the Blizzard export header and expected specialization ID, and emits schema-v2 build data.

v1.9.1 hardens that collector against duplicate/utility Copy widgets: only expected Hero-tree names are accepted, source-row content wins over stale heading context, DOM fallback is dialog-scoped, repeated rows are reconciled, and contradictory cross-Hero exports fail closed instead of being promoted.

The v1.8.0 multi-build model remains in place: Azeroth Guidebook preserves the meaningful variants the source guide actually publishes inside Raid, Mythic+, and Delves rather than generating every mathematically possible legal talent permutation. For current Elemental data, the already validated Farseer Raid/Mythic+/Delves builds remain exact; Stormbringer stays visibly **Pending** until the automated live collector can obtain and validate its exact source values. No alternate string is guessed or reconstructed merely to fill the slot.

When a selected guide variant contains an exact source-validated Wowhead import string, the Talent tab exposes direct actions:

- **View Guide Build**
- **Compare to Mine**
- **Import as Loadout**
- **Copy Build String**

Bundling an import string is not enough by itself. Before a direct guide build is used, Azeroth Guidebook decodes it through the current Retail talent APIs and validates the specialization, current tree compatibility, max-level Hero-tree completeness, expected Hero tree when supplied, and a WoW import-string round trip when that API result is available.

If an exact current guide transport is not available, the addon deliberately does **not** invent one. **Paste / Preview Build** remains the fallback.

### Elemental variant status at v1.9.1

- Raid: **Farseer [Best]** exact; **Stormbringer** source-listed and pending exact Copy capture.
- Mythic+: **Farseer [Best]** exact; **Stormbringer** source-listed and pending exact Copy capture.
- Delves: **Farseer [Best]** exact; **Stormbringer** source-listed and pending exact Copy capture.

The selected variant is remembered independently for each specialization and content category. Pending variants remain visible but cannot use View / Compare / Import / Copy until an exact source string is bundled.

## Bundled guide coverage

Talent-guide coverage now includes **all 40 Retail specializations**. Shaman and Demon Hunter retain the full reference packs with Talent guidance, Best in Slot gear, Consumables, Enchants & Gems, Stat Priority, and source/update information.

The other 34 specializations use progressive packs backed by the same exact/Pending talent pipeline. Their additional tabs are data-driven: BiS, Consumables, Enchants & Gems, and Stats become available independently when reviewed structured data is merged. v2.2.0 adds the BiS collector/scaffold but does not yet bundle new-class BiS results.

The shared talent system includes live build reading, Blizzard/Wowhead import-string decoding, visual Class/Spec/Hero trees, Guide/Target vs My Build comparison, Differences Only, mismatch navigation, and Blizzard loadout import.

## Guide browser

The top-right button is a two-stage class/spec browser:

1. Choose **Use Current Spec** or any supported Retail class.
2. Select one of that class's specializations.

All 40 current Retail specializations are available. When your active character spec has bundled data and no manual override is selected, Azeroth Guidebook automatically follows your current specialization. Changing the character's active spec clears an old talent preview/comparison so the displayed live tree stays aligned.

The minimap book button can be **dragged around the minimap edge**; its position is saved per account. Click it to toggle the guide.

Slash commands:

- `/agb` to toggle the guide
- `/agb elemental` or `/agb ele`
- `/agb enhancement` or `/agb enh`
- `/agb restoration` or `/agb resto`
- `/agb havoc`
- `/agb vengeance` or `/agb veng`
- `/agb devourer` or `/agb dev`
- `/agb current` or `/agb auto`
- `/agb minimap`

## Talent features

- Raid, Mythic+, and Delve guide categories
- Multiple guide-listed variants inside each content category
- Per-spec/category remembered variant selection
- Visible fail-closed Pending variants when a source build is known but its exact Copy value is not yet bundled
- Direct View / Compare / Import / Copy controls when the selected variant has an exact bundled build
- Paste and decode compatible Blizzard/Wowhead talent import strings
- **Preview My Build** reads the active WoW talent configuration directly
- Visual **Class**, **Specialization**, and active **Hero** talent trees
- WoW-native talent positions, edges, icons, ranks, choice nodes, and spell tooltips
- **Target Build**, **My Build**, and **Compare** views
- **Differences Only** filter
- **Previous Difference / Next Difference** mismatch navigation
- Plain-English difference list
- Copy Target and My Build strings
- **Import Target as Loadout** through Blizzard's talent-loadout API
- Level-90 active-Hero-tree completeness checks
- Serialization/tree-hash compatibility checks when available
- Cross-class/spec validation so an import cannot be shown under the wrong guide

**Preview My Build** and live comparison are enabled only when the displayed guide matches your character's active class and specialization. You can still browse another bundled class/spec and preview a compatible target string for that spec.

## Build/update-time Wowhead collector

The preferred development path is `tools/wowhead_browser_capture.py`. It is an external Chromium/Playwright utility and is **not** run by WoW. It discovers guide Copy controls, captures the exact Blizzard export that Wowhead writes, infers source labels/Hero headings/recommendation markers, and can emit both a reviewable JSON report and schema-v2 Lua.

`tools/wowhead_bulk_capture.py` applies the same fail-closed capture across every spec listed in `tools/supported_build_sources.json`, so future guide refreshes can be collected in batches instead of asking a person to copy each string.

`tools/wowhead_build_data.py` remains the static/manual fallback. Both collectors decode the Blizzard export header and require the configured specialization ID. The shorter `talent-calc/<class>/<spec>/<state>` route state is discovery evidence only and cannot be promoted just because it looks like a base64 string.

See `tools/README.md` for the collection workflow and safety rules.

## Gear and consumable features

Each bundled spec includes:

- Best-in-slot slot list with normal WoW item tooltips
- Equipped / bag ownership indicators
- Shift-click item linking to chat
- Crafted-item priorities
- Flasks, potions, food, augment runes, and applicable weapon buffs
- Enchants and gem recommendations
- General stat priority plus a reminder to use the appropriate character-specific optimization tool for final gearing decisions
- Source URLs and guide update dates

## Installation

1. Extract the ZIP.
2. Copy the `AzerothGuidebook` folder into:
   `World of Warcraft/_retail_/Interface/AddOns/`
3. Replace the previous AzerothGuidebook folder if upgrading.
4. Restart WoW or run `/reload`.
5. Open the addon with the minimap book icon, the AddOn Compartment, or `/agb`.

## Comparing a guide build to your character

When an exact guide build is bundled:

1. Select the matching class/spec and Raid/Mythic+/Delve category.
2. Select the desired guide variant when more than one is listed.
3. Choose **Compare to Mine**.
4. Use **Differences Only** and **Previous / Next Difference** to review mismatches.
5. If desired, choose **Import as Loadout** or **Import Target as Loadout**.

When an exact guide build is not bundled, the development collector should obtain it automatically on the next data refresh. **Paste / Preview Build** remains available as a user-side diagnostic/fallback path, but manual copying is no longer the intended population workflow.

The addon does not force-activate an imported loadout.

## Important Wowhead limitation

WoW addons cannot make arbitrary web requests while the game is running. Exact guide build data must therefore be collected outside the game, validated, and bundled with an addon update.

v1.9.3 uses that external collection path while continuing to reject guessed, ambiguous, wrong-spec, incomplete-Hero, stale-tree, or failed-round-trip exact builds.

## Source attribution

The bundled recommendations are concise structured references derived from current Wowhead guide pages, with source links and source dates displayed inside the addon. Full Wowhead article text is not bundled.

World of Warcraft is a trademark of Blizzard Entertainment. Wowhead is a third-party site and is not affiliated with this addon.

### Source-aware My Character talents

My Character now audits talents against the build selected under the active specialization's **Talents** source. If Icy Veins or U.GG is selected, the dashboard uses that source's selected exact build/context rather than silently falling back to Wowhead. Multi-source builds that are incomplete at level 90 remain available for preview/compare/copy but are blocked from native loadout import.

My Character is also level-aware. The reviewed endgame guide target is level 90; lower-level characters keep factual Equipped/Owned/Not owned, bag-count, enchant-detection, and gem-detection results, while Talent comparisons are labeled **Partial comparison** and gear/enchant/stat references are explicitly marked as level-90 guidance.

- My Character View Details and Needs Attention filters preserve the current scroll position when switching audit views.


### Minimap launcher
The launcher can be dragged around the outside edge of the minimap and its saved angle persists across reloads and logins.

### Launcher and slash command
- Drag the Azeroth Guidebook minimap icon around the outside rim; its angle persists across reloads/logins.
- `/agb` and `/azerothguidebook` toggle the guide. v3.12.0 refreshes WoW's slash-command lookup during startup so the command is available on the first login without requiring an extra `/reload`.