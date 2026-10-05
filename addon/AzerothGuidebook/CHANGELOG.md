# Changelog

## 3.16.0 - Activity Profiles

- Added specialization-specific **Raid**, **Mythic+**, and **Delves** activity profiles.
- Profiles are explicitly user-defined: **Save as Raid / Mythic+ / Delves** captures the current guide configuration exactly instead of Azeroth Guidebook choosing a preferred source.
- A saved profile remembers the selected source for Talents, Rotation, BiS, Consumables, Enchants & Gems, and Stats; U.GG Raid/Mythic+ context; the current Wowhead talent activity/category and per-category talent variants; selected Icy Veins/U.GG talent builds; Wowhead gear set; and Wowhead/Icy Veins Rotation context/preset.
- Selecting a saved profile reapplies the complete configuration at once and immediately recalculates My Character / Character Action Plan against that activity setup.
- Manual guide changes while a profile is active are shown as **Modified** rather than silently overwriting the saved profile. **Save Changes to <profile>** explicitly updates it; reselecting the modified profile restores the saved configuration.
- Profiles are stored independently per specialization, so Raid/Mythic+/Delves configurations for one spec do not overwrite another spec's profiles.
- Unavailable source selections fail closed during profile application: the unavailable setting is left unchanged rather than silently substituting another source.
- Preserves the accepted v3.15.0 Refresh Change Intelligence, v3.14.0 Character Action Plan, companion protocol/history behavior, and all reviewed guide recommendation datasets unchanged.
- Live validation passed for Raid/Mythic+/Delves profile save behavior, bidirectional Raid <-> Mythic+ switching, Modified-state detection, Save Changes behavior, restoring an unsaved modified profile, Delves switching, and specialization isolation; Elemental profiles did not carry into Restoration.

## 3.15.0 - Refresh Change Intelligence

- Added **What's New Since Last Refresh?** to Sources, backed by schema-v2 companion refresh history.
- Records the latest five refresh runs with per source/spec change summaries.
- Separates recommendation changes from source-date-only metadata updates.
- Adds domain-level change reporting for Talents, Gear/BiS, Consumables, Enchants & Gems, Stats, and Rotation when a verifiable before/after pack snapshot is available.
- Adds direct **View Updated Guide** navigation from changed/date-only domains to the affected specialization/source/tab.
- Keeps Refresh All Sources compact by omitting unchanged pack detail while preserving aggregate counts.
- Fails closed when a pre-v3.15 baseline has only a fingerprint and no retained Lua snapshot; no false before/after claims are generated.
- Requires Companion v1.1.0+ to create new detailed history; older companion state remains readable and all bundled guide functionality remains available.
- Preserves the accepted v3.14.0 Character Action Plan and all reviewed recommendation datasets unchanged.
- Live validation passed for **Refresh Current Source**, **Refresh Current Spec**, and **Refresh All Sources** with Companion v1.1.0-rc1, including legacy fail-closed baseline messages, detailed six-domain Icy Veins no-change history, compact 120-pack all-sources history, and five-run Recent Refresh History.
- Controlled change-presentation validation passed for Changed Talents, Gear/BiS, and Enchants & Gems; source-date-only Stats; unchanged Consumables/Rotation; and **View Updated Guide** navigation for every actionable changed/date-only row.
- After the synthetic presentation check, a real Current Source refresh restored genuine companion-generated history.



## 3.14.0 - Character Action Plan

- Live validation completed: **Show Completed** displayed the expected completed talent/gear/enchant/consumable rows, and direct navigation for Talent comparison, Gear, Enchants, Consumables, Stats, and Rotation all preserved source/context and highlighted/opened the correct guide target.
- Final live Action Plan count on the validation character was `24 adjustment(s) remaining across 3 domain(s) | Gear 13 | Enchants 6 | Consumables 5`, with the selected Wowhead talent build reporting an exact match.

- Follow-up Action Plan refinement: U.GG `Crafted Items` is now reference-only so crafted popularity rows are not double-counted alongside real equipment slots; U.GG trinket alternatives are grouped into the two actual trinket slots instead of requiring all three observed options; uncategorized consumables now display their item names instead of duplicate generic `Consumable` labels; explicit alternate consumable labels such as `Alt. Flask` now collapse into the same requirement and list the available source options together.

- Added a new **Action Plan** view to My Character and made it the default My Character view for a fresh UI session.
- Consolidated selected-source character adjustments into one live to-do list without blending or comparing guide sources.
- Talent differences are counted individually and can open the existing exact selected-source comparison directly.
- Gear rows now distinguish complete equipped items from remaining items already owned in bags and items still missing/not-owned, with direct guide-row navigation preserved.
- Enchant mismatches/missing states become direct action rows; verified/detected recommended enchants can appear under Completed.
- Consumables are grouped by source category/type so owning one source-listed alternative completes that category instead of treating every alternative as separately required.
- Gem alternatives, Stats, Rotation, and fail-closed/unverifiable states remain informational rather than being turned into a score.
- Added selected-source **Rotation** navigation to the My Character Open Selected Guide row and to Action Plan Guide References.
- Added persistent **Show Completed / Hide Completed** control; completed rows are hidden by default.
- Preserved v3.13.0 companion/source-refresh behavior, v3.11 direct issue navigation, v3.10 Needs Attention filters, source/context semantics, and the accepted 2026-09-29 guide data snapshot.

## 3.13.0 - Validated One-Click Refresh Production Release

- Promoted the v3.12.0 source-refresh architecture to the production baseline after live end-to-end validation of all three in-game refresh scopes.
- **Refresh Current Source** passed on Elemental Shaman / Talents / Icy Veins with `0 applied | 1 no change | 0 review required | 0 failed`.
- **Refresh Current Spec** passed on Elemental Shaman across Wowhead, Icy Veins, and U.GG with `0 applied | 3 no change | 0 review required | 0 failed`.
- **Refresh All Sources** passed across all **40 Retail specs x 3 sources = 120 packs** with `0 applied | 120 no change | 0 review required | 0 failed`.
- Validated Windows completion notifications, final `/reload` reconciliation, automatic clearing of submitted requests, and persistent healthy companion state during completed runs.
- Accepted **Azeroth Guidebook Companion v1.0.0-rc5** as the production companion baseline for v3.13.0 after clean install, Installed Apps registration, Ready-state, uninstall, and immediate addon status-reset validation all passed.
- rc2 fixed the rc1 reinstall/restart failure by removing orphaned locks, waiting for a heartbeat from the newly launched process, and recovering from locks whose recorded process no longer exists.
- rc3 made Windows uninstall registration fail-closed and verifiable so the companion appears normally under **Settings > Apps > Installed apps**.
- rc4 hardened uninstall so shutdown and addon-facing `not_installed` status reset are verified before removing the Windows uninstall entry.
- rc5 removed `tasklist.exe` / `taskkill.exe` dependencies after Norton CyberCapture interfered with that process-management path. The companion now accepts a local graceful stop request and uses native Windows process enumeration/termination as fallback.
- rc5 source passes `go test ./...`; the Windows companion and setup executables compile successfully as self-contained x86-64 PE binaries.
- Preserved the accepted v3.12.0 minimap launcher placement, drag-angle persistence, immediate `/agb` availability on fresh login, source-refresh protocol `1`, and fail-closed companion health checks.
- No reviewed guide recommendation, My Character audit calculation, source selection, or bundled data snapshot changed; `Data refreshed 2026-09-29` remains intentionally unchanged.
- The companion remains unsigned for this release, so Windows SmartScreen or third-party reputation products may warn or scan new installer builds.

## 3.12.0 - Source Refresh Workflow
- Minimap launcher positioning now derives its orbit radius from the live minimap dimensions plus an exterior offset, keeping the draggable icon outside the minimap across UI scales/sizes while preserving its saved angle.

- Post-validation usability fix: the minimap launcher can now be dragged around the minimap edge and remembers its position across sessions.
- Hardened `/agb` slash-command registration by registering at file load, addon initialization, and `PLAYER_LOGIN`, with SavedVariables initialization guarded inside the command handler.
- Added one-click **Refresh Current Source**, **Refresh Current Spec**, and **Refresh All Sources** actions in the Sources tab.
- Added `SourceRefresh.lua` SavedVariables request handoff plus fail-closed `GuideRefreshOverrides.lua` and `SourceRefreshState.generated.lua` runtime layers; accepted bundled guide data is never destructively rewritten.
- Replaced the development PowerShell/Python end-user companion path with a self-contained native Windows companion and one-time `AzerothGuidebookCompanionSetup.exe` installer intended for CurseForge rollout.
- The companion installs per-user under `%LOCALAPPDATA%\AzerothGuidebook\Companion`, registers current-user Windows startup and uninstall metadata, starts hidden, and requires no Administrator rights. CurseForge addon updates do not remove it.
- Added `CompanionStatus.generated.lua` plus addon-side heartbeat/protocol health detection. Refresh buttons are enabled only when a compatible running companion was detected at addon load; missing/stale/incompatible companions never affect bundled guide availability.
- End-user refresh is feed-only for **Wowhead, Icy Veins, and U.GG**. Player PCs do not require Python, Playwright, browser automation, Cloudflare interaction, or direct source-site scraping. Capture/review remains a maintainer-side workflow.
- Added an embedded 120-pack seed feed covering all three supported sources across all 40 specs. The seed matches the accepted bundled snapshot and intentionally reports **No change**; newer content is installable only from project-validated published packs.
- Added remote HTTPS manifest support with source/spec identity checks, SHA-256 verification, no-downgrade fallback behavior, and atomic non-destructive override writes.
- Added companion protocol version `1` so addon and companion releases can be versioned independently while remaining compatibility-aware.
- Simplified the steady-state in-game UX to the three Refresh buttons plus status text; no setup/run-now/PowerShell controls are shown in-game.
- Preserved all accepted v3.11.0 My Character behavior and all reviewed guide datasets unchanged.
- Validation: **228/228** Python addon/tool regressions plus **6/6** native Go companion/setup tests pass; both public Windows binaries remain unchanged by this usability fix.

## 3.11.0 - Actionable Issue Navigation

- Added per-row **View in Guide** actions for My Character Gear, Enchant, and Consumable issue-only views.
- Issue actions preserve the selected source and U.GG context, open the matching guide domain, highlight the exact item/spell recommendation when resolvable, and scroll it into view.
- Talent issues now open the selected Wowhead/Icy Veins/U.GG build directly in the existing node-level comparison view using the comparison already computed by My Character.
- Exact navigation is presentation-only: no guide recommendation, source selection, content context, or Character audit calculation is changed.
- Preserved v3.10.0 Needs Attention layout and internal scroll-position behavior.
- Regression coverage: **200/200 passing**.

## 3.10.0 - My Character Issue Focus

- Added a compact **Needs Attention** block; post-validation layout cleanup places it below **Open Selected Guide** and **View Details** so selected issue-only content begins immediately beneath its controls.
- Added issue-only drilldowns for Talent differences, Gear gaps, Enchant problems, and absent source-listed Consumables while preserving the existing normal detail views and All Details.
- U.GG observed gear gaps remain explicitly descriptive rather than editorial Best-in-Slot failures.
- Gem alternatives are not classified as missing issues, and Stats remain informational rather than scored.
- Characters below the level-90 guide target defer endgame issue classification and keep those gaps informational.
- No reviewed guide data or Character audit semantics changed.
- Regression coverage: **196/196 passing**.

## 3.9.0 - Actionable My Character Navigation

- Added a compact **Open Selected Guide** action row to the My Character overview for Talents, Gear/BiS, Enchants & Gems, Consumables, and Stats.
- Guide-jump buttons display each domain's currently selected source and open the matching guide tab on the active character specialization.
- Added domain-specific **Open ... Guide** actions inside each My Character detail view and All Details.
- Navigation preserves saved source selection, U.GG Raid/Mythic+ context, selected source build, and the session-level My Character detail filter.
- No reviewed guide data or Character audit semantics changed.
- Regression coverage: **194/194 passing** in stable file-level/chunked runs.

## 3.8.0 - My Character Usability

- Added a compact **Audit Overview** to My Character covering Talents, Gear, Enchants & Gems, Consumables, and live Stats with each domain's selected source/context.
- Added session-level My Character detail filters for **Overview, Talents, Gear, Enchants & Gems, Consumables, Stats, and All Details**.
- My Character now defaults to Overview so routine checks no longer require scrolling through every audit row.
- Preserved the complete v3.7.0 audit under **All Details** and preserved all source-aware/level-aware semantics unchanged.
- No reviewed Talent, BiS, Rotation, Consumables, Enchants/Gems, Stats, Icy Veins, U.GG, or Wowhead recommendation data changed.
- Regression coverage: **192/192 passing** in stable file-level/chunked runs.

## 3.7.0 - Source-Aware My Character

- Extended My Character source-awareness from Talents to BiS/Observed Gear, Consumables, Enchants & Gems, and Stats.
- Editorial Wowhead/Icy Veins gear remains labeled Best in Slot; U.GG gear is explicitly labeled Observed Gear with Raid/Mythic+ context and factual Equipped / Owned / Not owned states.
- Added source-aware Icy Veins and U.GG enchant/gem auditing while preserving the existing fail-closed permanent-enchantment verification model.
- Added source-aware consumable bag ownership auditing for exact item entries and intentionally excludes non-item source references from missing-item counts.
- Current Stats now pairs the live character snapshot with the currently selected source's reviewed priority; U.GG priorities remain labeled observed player data.
- Expanded live-slot aliases needed by Icy Veins/U.GG source labels, including Helm, Back, Bracers, Main Hand, Trinket(s), Rings, Wrist, and Cloak.
- Added level-aware My Character auditing: characters below the level-90 guide target get an explicit level warning, Talents become a Partial comparison, and gear/enchant/stat references are labeled informational while factual inventory/detection states remain available.
- Preserved all accepted v3.6.0 guide datasets and recommendations unchanged.
- Regression coverage: **190/190 passing** in stable file-level/chunked runs.

## 3.6.0 - Rich Icy Veins Rotation

- Promoted reviewed rich Icy Veins Rotation data into production for **all 40 Retail specializations**.
- Accepted the rotation-only review at **40/40 captured, 0 partial, 0 errors**.
- Bundled **162 source-declared Hero/build presets, 1,127 structured rotation blocks, and 6,757 source-visible actions** in `GuideIcyRotations.lua`.
- Icy Veins Rotation now renders source Hero/build selectors, explicit current/selected state, ordered or bulleted priority rows, source notes, exact spell/item icons, and WoW tooltips.
- Post-validation renderer cleanup keeps source-authored ordered lists numbered and unordered lists bulleted; generic guidance rows with no exact linked spell/item now use a neutral note icon instead of the red missing-asset question mark.
- The generator preserves only actions visible under the exact Icy Veins source preset; hidden optional/talent rows are never inferred or blended across presets.
- Retained the production review audit under `tools/reviewed_icy_rotations_v360/MERGE_AUDIT.json`; raw HTML remains excluded from the addon package.
- Advanced addon/freshness release metadata to v3.6.0 without replacing accepted v3.5.0 Talent, BiS, Consumables, Enchants/Gems, Stats, U.GG, My Character, or Wowhead recommendation data.
- Regression coverage: **185/185 passing** in stable file-level/chunked runs.

## 3.5.0 - U.GG granted-rank normalization

- U.GG talent builds now restore only starter ranks that the live Retail talent tree explicitly marks with a met `Granted` condition. This addresses source transports that omit automatically granted class/spec/Hero starter nodes without guessing any optional or choice talent.
- Repaired U.GG previews, Compare to Mine, My Character auditing, and native loadout import all use the same normalized entry list. The original captured U.GG string remains available through Copy Build String.
- Native import omits the stale source transport when deterministic granted-rank repair was required and submits the normalized Blizzard entry list instead. If the build remains incomplete after every live granted rank is restored, Import stays fail-closed.
- Best-in-Slot live ownership validation is confirmed in-game for all three states: Equipped, Owned in bags, and Missing.
- Regression coverage: **178/178 passing**.

## 3.5.0 - Source-aware My Character and safe multi-source import

- My Character talent auditing now follows the currently selected Talents source/build for the active specialization instead of always comparing against the Wowhead baseline. Icy Veins and U.GG audits retain source/context provenance in the dashboard.
- Multi-source builds with an incomplete level-90 Hero Talent tree remain previewable, comparable, and copyable but now disable Import as Loadout before the click, with a visible explanation instead of chat rejection spam.
- Exact complete source builds still hand their captured string to WoW unchanged for native import validation.
- Regression coverage: **178/178 passing** in stable file-level/chunked runs.

## 3.5.0 - Unified source presentation

- Unified Icy Veins and U.GG presentation with the established Wowhead visual language while preserving source-specific semantics.
- Added source-consistent domain headings, patch/source metadata placement, row/card layouts, and copy controls.
- Added Wowhead-style View Guide Build / Compare to Mine / Import as Loadout / Copy Build String actions for exact Icy Veins and U.GG talent captures. Compare works from decoded node selections whenever the displayed specialization is active.
- Added the source-independent Paste / Preview Build and Preview My Build controls to Icy Veins and U.GG Talents, plus the same Copy Source URL utility row used throughout the unified presentation. Pasted/current previews now render directly inside the selected multi-source Talent view.
- Updated Icy Veins/U.GG Import as Loadout to submit the exact captured source string unchanged through WoW's native loadout importer whenever the matching specialization is active. Azeroth Guidebook still validates spec/decode structure first, while WoW performs the final loadout acceptance/rejection; fail-closed contexts with no exact source string remain non-importable.
- Added explicit player-facing reasons when Compare or Import is unavailable instead of leaving a gray action unexplained.
- Replaced U.GG `Source reported unknown at capture` copy with the captured snapshot date when the source did not expose its own relative update timestamp.
- Flattened U.GG observed gear into the same item-row treatment used by the Wowhead/Icy Veins gear views while retaining popularity/sample evidence and the non-editorial warning.
- Added category-aware Icy Veins consumable labels without inferring a recommendation when the captured item name does not support a category.
- Preserved Icy Veins Best/Alternative enchant labels and U.GG observed enchant/gem semantics in the unified row layout.
- Restyled Icy Veins Rotation subsection evidence into numbered rotation-summary rows; individual source actions remain fail-closed until exact source-variant mapping is reviewable.
- Preserved all accepted v3.4.0 source data, three U.GG talent fail-closed contexts, and Wowhead recommendations unchanged. The later v3.5.0 source-aware My Character pass changes only which reviewed Talent source/build the dashboard audits.
- Regression coverage at the unified-presentation checkpoint: **177/177 passing** in stable file-level/chunked runs.

## 3.4.0 - All-spec multi-source expansion

- Expanded reviewed Icy Veins and U.GG guide data from the five-spec v3.3 proof to **all 40 Retail specializations**.
- Accepted the 35-spec expansion capture at **487/490 captured, 3 partial, 0 errors** after review.
- Resolved the Holy Priest Icy Veins Enchants partial from its captured `Slot / Best / Alternative` source table by exact recommendation-name-to-captured-item-ID matching: **7 slots / 14 exact recommendations**. Best vs. Alternative is preserved in the in-game row label.
- Kept Balance Druid Raid U.GG Talents and Discipline Priest Mythic+ U.GG Talents fail-closed because no exact Blizzard import string was captured. The existing Holy Paladin Mythic+ U.GG Talent limitation remains fail-closed. No build is borrowed across source or content context.
- Added `tools/reviewed_multisource_expansion_v340` with the accepted reports/summary/manifest and `PRODUCTION_REVIEW_AUDIT.json`. Raw HTML remains external to the addon package.
- Added deterministic `tools/build_multisource_production.py` so reviewed expansion evidence can be rebuilt without modifying the accepted five-spec proof block.
- Generalized the Sources-tab limitation notice so any fail-closed U.GG Talent context is surfaced automatically instead of special-casing Holy Paladin.
- Post-acceptance UI cleanup makes the active U.GG Raid/Mythic+ context and Rotation Hero/source context explicit with `Current context` / `Current hero/source` lines plus `[Selected]` button labels. The underlying context IDs and reviewed guide data are unchanged.
- Advanced the 240-entry Wowhead freshness baseline release version to v3.4.0 without changing its source-entry set.
- My Character remains on the validated Wowhead production baseline; multi-source character auditing is not silently enabled.
- Regression coverage: **176/176 passing** in stable file-level/chunked runs.


## 3.3.0 - Multi-source proof integration

- Added the first in-game multi-source guide framework while preserving Wowhead as the unchanged default production source.
- Added reviewed five-spec proof data for Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue from **Icy Veins** (editorial guidance) and **U.GG** (observed player data).
- Added per-spec/per-domain source selectors so editorial recommendations and observed usage data remain explicitly separate rather than blended into one recommendation.
- Added Raid/Mythic+ context switching for U.GG. U.GG gear is labeled observed/popular gear rather than editorial Best in Slot.
- Icy Veins proof coverage includes exact spec-validated Blizzard talent exports, Overall Best in Slot item IDs, source-listed consumables, Enchants/Gems, structured stat-priority widgets, and concise rotation-section evidence.
- U.GG proof coverage includes Raid/Mythic+ exact talent exports where capturable, observed gear, Enchants/Gems, stat priority, parse/key-range/popularity context, and source-relative update metadata.
- Holy Paladin Mythic+ U.GG Talents remains fail-closed because the live Copy control did not yield an exact Blizzard import string; its observed metrics remain available. No build is borrowed from Raid or another source.
- Added `GuideMultiSource.lua` and `MultiSource.lua`; My Character continues to audit the validated Wowhead production baseline in v3.3.0.
- Retained the reviewed v3.3 proof evidence under `tools/reviewed_multisource_proof_v330` and included the hardened multi-source proof collector for future expansion.
- Advanced the existing Wowhead freshness baseline to addon v3.3.0 without changing its 240 source entries.
- Post-validation cleanup disambiguates Frost Mage Icy Veins opener evidence as Frostfire vs. Spellslinger, replaces generic Rotation question-mark icons with category-aware food/flask/oil/potion fallbacks, and makes the Icy Veins Rotation explanation version-neutral.
- Clarified the Guide Source selector after live validation showed WoW's disabled-button styling could make the inactive red source look selected: the active source now displays an explicit `Current source:` line and `[Selected]` marker without changing the underlying Wowhead/Icy Veins/U.GG mapping.
- Made freshness-baseline evidence selection deterministic when accepted duplicate review snapshots have identical source metadata and capture timestamps, preserving the already-recorded release provenance regardless of filesystem ordering.
- No validated Wowhead Talent, BiS, Consumables, Enchants/Gems, Stats, Rotation, or My Character recommendation data changed.
- Automated regression suite: **166/166 passing**.


## 3.2.0 - Review-only selective refresh automation

- Added `tools/selective_refresh.py` and `tools/Run-SelectiveRefresh.ps1`.
- A current `FreshnessReviewBundle.zip` can now drive the appropriate per-domain collectors automatically for only `changed` spec/domain rows.
- Freshness baseline version and source URLs are validated before any collector runs; stale/mismatched reports fail closed.
- `source_older`, `baseline_missing`, `unknown`, and `error` are never automated into recaptures.
- Playwright/dependencies are prepared once per selective run; the orchestrator invokes the existing Python collectors directly without proof/expansion group leakage.
- Outputs are combined into `SelectiveRefreshReviewBundle.zip`; generated Lua remains review-only and is never merged automatically.
- Freshness plans now advertise the selective-refresh orchestrator.
- No validated Talent, BiS, Consumables, Enchants/Gems, Stats, Rotation, or My Character runtime data changed.
- Automated regression suite: **146/146 passing**.

## 3.1.0 - Guide freshness baseline and first selective source refresh

- Adds the validated 240-entry Wowhead freshness baseline/checker workflow to the production toolset.
- Reviews the first full freshness hit: Havoc Demon Hunter Talents now carry the live 2026-09-24 source date, while all six Blizzard import strings remain unchanged from v3.0.6.
- Corrects Elemental Shaman Stats from the older native fallback to the exact current Farseer/Stormbringer source priorities captured on 2026-09-28.
- Adds an explicit Stats source date for Elemental so all 240 freshness baseline entries are now dated.
- Expands BiS/Consumables/Enchants/Stats selective-capture manifests to all 40 specs, including the six native Shaman/Demon Hunter packs, so every freshness hit can be recaptured through the standard wrappers.
- Hardens talent recapture metadata so the live detected Wowhead Updated date overrides stale manifest metadata in new review artifacts.
- No BiS, Consumables, Enchants/Gems, Rotation recommendations, or My Character audit behavior were changed.

## 3.0.6 - Source-verified enchant effect mapping and talent copy cleanup

- Added an explicit, extensible permanent-enchant effect mapping layer used only for source-verified item/effect pairs.
- Mapped equipped enchant effect **7935** to reviewed item **240133 Sunfire Silk Spellthread**, allowing the live `+41 Intellect & +115 Stamina` leg enchant to verify exactly even when WoW omits the enchant name from the permanent-enchantment tooltip line.
- Kept every unmapped effect fail-closed; no numeric effect ID is inferred from tooltip text or recommendation names.
- Replaced the stale hard-coded `v2.7.0` Talent limitation footer with version-neutral wording so future releases do not display obsolete version copy.
- Made My Character explanatory copy version-neutral for the same reason.
- Preserved all validated Talent, BiS, Consumables, Enchants/Gems, Stats, and Rotation recommendation data unchanged.
- Automated regression suite: **128/128 passing**.

## 3.0.5 - Enchant audit validation and talent-button polish

- Added client-side permanent-enchantment tooltip inspection to My Character. The audit now compares the applied enchant name against every reviewed recommendation for the source slot instead of reporting presence only.
- Reports `Recommended enchant equipped` only when the recommendation is a spell/runeforge without crafted-rank ambiguity; crafted enchant name matches report `Recommended enchant detected` while quality/rank remains explicitly unverified.
- Reports `Different enchant detected` when the applied enchant name matches another reviewed addon enchant but not the recommendations for the current specialization/slot; unknown effects remain fail-closed as exact-comparison unavailable.
- Preserved installed enchant effect IDs in the dashboard for diagnostics.
- Changed single talent-guide variant buttons from the old 610px full-row width to the standard 298px width, left-aligned. Multi-variant rows remain the existing two-column layout.
- Preserved all validated Talent, BiS, Consumables, Enchants/Gems, Stats, and Rotation recommendation data unchanged.
- Automated regression suite: **126/126 passing**.

## 3.0.4 - Talent source-label correction

- Removed the false **Elemental Shaman - Stormbringer - Raid** alternative from the production selector after confirming its provided Blizzard import is the already-validated **Farseer - Raid (Best)** build.
- Removed the false **Restoration Druid - Keeper of the Grove - Delves** alternative after confirming its provided Blizzard import is the already-validated **Wildstalker - Delves (Best)** build.
- Talent coverage is now **269 exact / 0 Pending**. These source-label errors are not promoted as duplicate builds under the wrong Hero tree.
- Preserved the existing exact Farseer Raid and Wildstalker Delves import strings unchanged.
- Preserved all other validated Talent, BiS, Consumables, Enchants/Gems, Stats, Rotation, and My Character behavior unchanged.
- Automated regression suite: **122/122 passing**.

## 3.0.3 - Pending talent source reconciliation

- Resolved **Restoration Druid - Wildstalker - Delves (Best)** from the exact source-provided Delves export after reconciling the conflicting table rows against Wowhead's explicit Delves guidance that the Delve build uses Wildstalker.
- Talent coverage is now **269 exact / 2 Pending** across all 40 Retail specializations.
- Kept **Elemental Shaman - Stormbringer - Raid** fail-closed because the current Wowhead Stormbringer Raid row exports the same Blizzard string as Farseer Raid.
- Kept **Restoration Druid - Keeper of the Grove - Delves** fail-closed because the source row is labeled Delves but its control is `Copy Mythic+` and it exports the same string as Wildstalker Delves.
- Replaced the generic cross-Hero Pending messages on those two rows with explicit current-source conflict details.
- Preserved all other validated Talent, BiS, Consumables, Enchants/Gems, Stats, Rotation, and My Character audit behavior unchanged.
- Automated regression suite: **122/122 passing**.

## 3.0.2 - Weapon enchant audit hotfix

- Fixed My Character so a generic `Weapon` enchant recommendation audits only the main-hand weapon instead of incorrectly flagging an equipped shield/off-hand as missing an enchant.
- Added explicit runtime handling for source-labeled `Main Hand`, `Off Hand`, and `Both Weapons` enchant recommendations; two-weapon auditing now occurs only when the reviewed guide actually calls for it.
- Kept Talent comparison behavior unchanged: Pending/unbundled guide variants remain fail-closed, while validated builds continue to compare exactly.
- Left live BiS ownership/equipped validation deferred until a source-listed item is naturally available for testing.
- Preserved all validated Talent, BiS, Consumables, Enchants/Gems, Stats, and Rotation recommendation data unchanged.
- Automated regression suite: **119/119 passing**.

## 3.0.1 - My Character rendering hotfix

- Fixed a live UI error after the `Open Talents` button that stopped the My Character dashboard before Best in Slot, Enchants, Gems, Consumables, and Current Stats could render.
- Kept Talent unavailability fail-closed while allowing every independent character-audit section to continue rendering.
- Added regression coverage so action-button frame objects cannot be reused as numeric layout coordinates in the My Character path.

## 3.0.0 - My Character

- Added the new first-tab **My Character** live character audit.
- Added exact talent comparison against the selected validated guide build where a bundled transport is available.
- Added slot-family-aware BiS audit with equipped / owned-in-bags / missing states.
- Added exact equipped gem detection using item-link gem IDs.
- Added fail-closed enchant presence detection using installed enchant effect IDs; v3.0.0 does not equate those IDs with guide enchant item IDs.
- Added recommended consumable bag counts.
- Added live Critical Strike, Haste, Mastery, and Versatility snapshot with the reviewed stat-priority reference.
- Added live dashboard refresh for equipment, bag, talent/trait, and combat-rating changes.
- Added `Character.lua` as a read-only runtime audit layer; no validated Talent, BiS, Consumables, Enchants/Gems, Stats, or Rotation recommendation was replaced.
- Automated regression suite: 116/116 passing.

## 2.9.1 - 2026-09-27

- Completed reviewed Rotation & Cooldowns coverage across **all 40 Retail specializations**.
- Reviewed the 35-spec expansion as **35/35 exact specs, 302 exact structured blocks, 2,529 ordered actions, and 0 Pending blocks**.
- Combined with the unchanged five-spec v2.9.0 proof set, production now contains **357 exact structured blocks / 2,943 ordered actions**.
- Recovered source-defined core priorities for Arcane, Fury, Restoration Druid, Discipline Priest, Holy Priest, Mistweaver Monk, and Preservation Evoker without inventing missing rotations.
- Hardened source-layout handling for Arcane generic Priority blocks, Fury's plural `Single Target Rotations` heading, custom healer Raid/Mythic+/Hero priority headings, and Hero/source-context retention.
- Relaxed opener requirements for Arms and Balance because their reviewed sources do not publish a separate ordered opener list.
- Corrected Havoc AoE classification and kept Destruction's unresolved long-form cooldown fragment out of production rather than promoting it.
- Added a `General Priority` Rotation UI section for exact source blocks that are neither Single Target nor AoE-specific.
- Preserved the original five proof specs and all validated Talent, BiS, Consumables, Enchants/Gems, and Stats recommendation data unchanged.
- Automated regression suite now passes **109/109 tests**.


## 2.9.0 - 2026-09-27

- Merged the reviewed five-spec Rotation & Cooldowns proof set into production: **5/5 exact specs, 55 exact structured blocks, 414 ordered actions, 0 Pending blocks**.
- Added `GuideRotations.lua` and a context-aware **Rotation** tab with exact linked spell/item tooltips and Shift-click chat linking.
- Restored source-visible Hero contexts for Blood Death Knight, Frost Mage, Brewmaster Monk, and Subtlety Rogue; retained Holy Paladin's captured Lightsmith context.
- Hardened the collector against inline expandable-note bleed, source-valid single-action cooldown blocks, and non-H2 Pre-Combat headings.
- Expanded `supported_rotation_sources.json` to all 40 Retail specs: five reviewed `proof` specs plus **35 `expansion` specs**.
- Added `Capture-WowheadRotations.ps1 -ExpansionOnly` for the next bulk capture.
- Preserved validated Talent, BiS, Consumables, Enchants/Gems, and Stats recommendation data unchanged.
- Automated regression suite passes **104/104 tests**.


## 2.8.1 - 2026-09-27

- Reviewed the 29-spec Stats expansion and merged **29 exact specs / 63 exact variants / 0 Pending variants**.
- Combined structured Stats coverage is now **34 progressive specs / 75 exact variants**; with the six existing native Shaman/Demon Hunter Stats references, Stats are complete across **all 40 Retail specializations**.
- Preserved Beast Mastery context as Pack Leader All Situations plus Dark Ranger Single-Target/AoE.
- Preserved Discipline and Holy Priest Raid vs. Dungeons/Mythic+ scopes; restored the source-listed Discipline Dungeons Oracle row that the first collector pass deduplicated because its priority matched Raid exactly.
- Sanitized the stray leading `?` from Feral Wildstalker without changing the ordered priority.
- Hardened the Stats collector to retain short source context labels before semantic deduplication.
- Retained original/reviewed expansion summaries, source evidence, generated review Lua, and merge audit under `tools/reviewed_stats_expansion`.
- Preserved all validated Talent, BiS, Consumables, and Enchants/Gems recommendation data unchanged.
- Automated regression suite now passes **86/86 tests**.

## 2.8.0 - 2026-09-27

- Began the reviewed Stats rollout with **5 exact proof specs / 12 exact variants / 0 Pending variants**: Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue.
- Added `GuideStats.lua` as a structured progressive runtime pack and loaded it independently from the six existing native Shaman/Demon Hunter Stats fields.
- Preserved source-listed Hero-tree labels even when the priorities currently match, kept Brewmaster defensive/offensive variants separate, and retained Subtlety's `~700 Haste` breakpoint qualifier.
- Updated the Stats tab to render structured variants while retaining the legacy native `statPriority` / `statNote` path unchanged.
- Added a Stats source entry per progressive spec and a dedicated Stats-guide copy action.
- Retained reviewed proof artifacts under `tools/reviewed_stats_proof`; the remaining **29 expansion specs** stay fail-closed and are selectable with `Capture-WowheadStats.ps1 -ExpansionOnly`.
- Preserved all validated Talent, BiS, Consumables, and Enchants/Gems recommendation data unchanged.
- Automated regression suite now passes **80/80 tests**.

## 2.7.1 - 2026-09-27

- Reviewed the 29-spec Enchants & Gems expansion and merged **29 exact specs / 304 exact recommendations / 0 Pending rows**.
- Combined generated Enchants & Gems coverage is now **34 specs / 359 exact recommendations**; with the existing Shaman and Demon Hunter native packs, Enchants & Gems are complete across **all 40 Retail specializations**.
- Recovered Unholy Death Knight from its exact source-visible split layout: a dedicated Best Enchants table plus the immediately scoped Gems section; exact weapon spell and item IDs were preserved.
- Hardened the collector with a conservative split-layout fallback that still requires exact Wowhead item/spell links and does not read Consumables sections.
- Fixed gem classification for `Algari Diamond` and `Diamond (one of)` source labels.
- Split mixed generic `Gems` rows into Eversong Diamond vs. Other Gems UI types without changing captured linked entities.
- Retained the reviewed expansion reports, original/reviewed summaries, Unholy source evidence, generated pack, and merge audit under `tools/reviewed_enchants_expansion`.
- Preserved all Talent import strings, BiS item selections, and Consumables recommendations unchanged.
- Automated regression suite now passes **67/67 tests**.

## 2.7.0 - 2026-09-27

- Began the Enchants & Gems expansion with five reviewed proof specializations: Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue.
- Merged 55 exact source-linked enchant/gem recommendations with 0 Pending rows.
- Fixed gem classification for source rows labeled `Eversong Diamond`.
- Preserved repeated identical source entity IDs when they carry different contexts; Blood Death Knight now keeps both Rune of Sanguination contexts plus Rune of the Fallen Crusader.
- Normalized explicit main-hand/off-hand enchant row labels.
- Enchants & Gems UI rows now display captured context labels.
- Added reviewed proof artifacts and regression coverage.
- Talent, BiS, and Consumables datasets remain unchanged.

## 2.6.2 - 2026-09-27

- Completed Consumables coverage for **all 40 Retail specializations**.
- Promoted the targeted Preservation Evoker retry with **6 exact rows / 8 exact recommendations / 0 Pending rows**.
- Recovered Augmentation Evoker from its exact item-linked type-specific source subsections when Wowhead rendered the visible consumables summary as a non-table grid; the recovered pack contains **6 exact rows / 7 exact recommendations / 0 Pending rows**.
- Generated non-Shaman/Demon Hunter Consumables coverage is now **34 specs / 268 exact recommendations**; Shaman and Demon Hunter retain their existing native consumable packs.
- Hardened the collector with a conservative section-only fallback that accepts only recognized consumable subsection headings and exact Wowhead item/spell IDs, while continuing to ignore Enchants/Gems sections.
- Preserved Augmentation food context as `(feast)` and `(personal)` from the captured source section.
- Retained the raw retry diagnostics plus reviewed repaired reports and merge audit under `tools/reviewed_consumables_evoker_retry`.
- Preserved all Talent import strings and BiS item selections unchanged.
- Automated regression suite now passes **50/50 tests**.

## 2.6.1 - 2026-09-27

- Reviewed the 29-spec bulk Consumables expansion and merged **27 exact specs** into production.
- Generated non-native Consumables coverage is now **32 specs / 253 exact recommendations**; with the existing Shaman and Demon Hunter packs, Consumables are available for **38 of 40 Retail specs**.
- Left Preservation Evoker and Augmentation Evoker fail-closed for a targeted retry rather than guessing around source-layout/hydration edge cases.
- Excluded Unholy Death Knight `Diamond` and `Other Gems` rows from Consumables so those source entries remain reserved for the future Enchants & Gems pack.
- Normalized `Food - Feast`, `Food - Personal`, `Group Feast`, and the source typo `Invisiblity Potion` into stable in-game categories.
- Recovered exact source qualifiers where possible, including Restoration Druid potion preference/situational labels and Beast Mastery Raid/Mythic+/feast/personal context.
- Hardened the live collector with progressive deep-scroll hydration and row-scoped subsection fallback for placeholder values such as `See Below`.
- Retained the reviewed expansion reports and merge audit under `tools/reviewed_consumables_expansion`.
- Preserved all Talent import strings and BiS item selections unchanged.
- Automated regression suite now passes **48/48 tests**.

## 2.6.0 - 2026-09-27

- Expanded `supported_consumables_sources.json` from the five reviewed proof specs to all **34 non-Shaman/Demon Hunter specializations**.
- Kept the validated v2.5.1 proof specs tagged `proof` and tagged the remaining **29 specs** as `expansion`.
- Added `Capture-WowheadConsumables.ps1 -ExpansionOnly` and bulk `--group` filtering so the next live run skips already reviewed proof pages.
- Added selected-group metadata to `consumables_capture_manifest.json`; `ConsumablesReviewBundle.zip` remains the single-file review handoff containing summary, manifest snapshot, generated Lua, and every per-spec report.
- Added manifest regression coverage for all 34 spec IDs, exact 5/29 proof-expansion grouping, and role-specific Wowhead source URL suffixes.
- Preserved the reviewed v2.5.1 Consumables dataset and all Talent/BiS data unchanged.
- Automated regression suite now passes **43/43 tests**.

## 2.5.1 - 2026-09-27

- Merged the reviewed five-spec Consumables proof capture into production for Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue.
- Added **33 exact source rows / 46 exact recommendations / 0 Pending rows** across the proof set.
- Preserved source-listed alternatives and contexts, including Subtlety best/alternative/default notes and Holy Paladin Herald/Lightsmith weapon-buff context.
- Enabled exact spell-linked consumable recommendations in production; Holy Paladin Lightsmith uses `Rite of Sanctification` (spell 433568) while Herald retains Thalassian Phoenix Oil.
- Retained reviewed proof reports, summary, and manifest under `tools/reviewed_consumables_proof`.
- Preserved all v2.5.0 Talent import strings and BiS item IDs unchanged.


## 2.5.0 - 2026-09-27

- Added the first automated Wowhead Consumables collector pipeline and five-spec proof manifest: Blood Death Knight, Frost Mage, Holy Paladin, Brewmaster Monk, and Subtlety Rogue.
- Added `Capture-WowheadConsumables.ps1`, `wowhead_consumables_capture.py`, `wowhead_consumables_bulk_capture.py`, `supported_consumables_sources.json`, and automatic `ConsumablesReviewBundle.zip` output.
- Consumable capture is fail-closed per source row and accepts only exact Wowhead-linked item IDs or spell IDs; partial specializations are omitted from generated in-game data.
- Added exact spell-linked recommendation support to the generic row renderer for source cases such as class ability weapon buffs.
- Added empty `GuideConsumables.lua` runtime scaffold so reviewed consumables can progressively enable the Consumables tab without affecting other data packs.
- Added small BiS display sanitation for compact pipe-delimited source text and trailing `Explanation` capture artifacts; no BiS item IDs changed.
- Preserved the complete v2.4.0 Talent dataset and all reviewed BiS item selections unchanged.
- Automated regression suite now passes **41/41 tests**.

## 2.4.0 - 2026-09-27

- Merged the reviewed 29-spec bulk BiS expansion into production.
- New-class generated BiS coverage is now **34 specs / 36 gear sets / 570 exact rows / 0 Pending rows**.
- Combined with the existing Shaman and Demon Hunter packs, BiS is now available across all 40 Retail specializations.
- Added slot normalization for Brewmaster `Weapons (1h)` and Subtlety Rogue `Main-Hand` / `Off-Hand`; all repaired rows already had exact source item IDs, names, and sources.
- Preserved Mistweaver Monk's separate Raid and Mythic+ source-published BiS sets.
- Retained the reviewed expansion reports and merge audit under `tools/reviewed_bis_expansion`.
- Preserved the complete talent dataset unchanged.
- Automated regression suite now passes **32/32 tests**.

## 2.3.0 - 2026-09-27

- Expanded `supported_bis_sources.json` from the five proof specs to all **34 non-Shaman/Demon Hunter specializations**.
- Marked the five reviewed v2.2.x specs as the `proof` group and the remaining **29 specs** as the `expansion` group.
- Added `Capture-WowheadBiS.ps1 -ExpansionOnly` plus bulk `--group` filtering so the next live run skips already reviewed proof pages.
- Added fail-closed multi-table set-name inference for unanticipated pages: source-visible qualifiers may become set names, while ambiguous duplicate generic tables remain partial instead of being mislabeled.
- Expanded slot normalization for 2H/two-handed weapons, amulets/necklaces, and pants in addition to the previously fixed Boots handling.
- Added automatic `BiSReviewBundle.zip` output containing the summary, selected-source manifest snapshot, generated Lua, and per-spec diagnostics for a single-file review handoff.
- Increased automated regression coverage to **31 passing tests**.
- Preserved the installed v2.2.1 BiS dataset (95 exact rows across 6 reviewed gear sets) and all talent import strings unchanged.

## 2.2.1 - 2026-09-26

- Promoted the reviewed BiS proof capture for Blood Death Knight, Restoration Druid, Frost Mage, Holy Paladin, and Arms Warrior into the in-game data pack.
- Added **95 exact BiS gear rows across 6 source-listed gear sets**; Blood Death Knight keeps separate Deathbringer and San'layn selections.
- Fixed slot normalization so Wowhead `Boots` rows map to the canonical `Feet` slot instead of becoming Pending.
- Fixed source recovery for responsive tables with an unlabeled trailing blank column; Arms Warrior source names now come from the actual third source cell.
- Preserved every captured item ID/name and the complete v2.1.1 talent dataset unchanged.
- Expanded BiS collector regression coverage for plural `Boots` and trailing-blank source columns.

## 2.2.0 - 2026-09-26

- Added the first automated Wowhead Best-in-Slot collector pipeline.
- Added a five-spec BiS proof manifest: Blood Death Knight, Restoration Druid, Frost Mage, Holy Paladin, and Arms Warrior.
- Added `Capture-WowheadBiS.ps1`, `wowhead_bis_capture.py`, `wowhead_bis_bulk_capture.py`, and `supported_bis_sources.json`.
- BiS collection requires an exact source item ID for every required table row; partial captures remain diagnostic-only and are omitted from generated in-game data.
- Added multi-set BiS schema/UI support for sources that publish more than one complete gear set (for example Hero-tree-specific tank sets).
- Changed tab availability from the old `talentOnly` gate to per-tab data detection, enabling progressive data-pack expansion by specialization.
- Added an empty `GuideBiS.lua` runtime scaffold; no newly captured BiS data is bundled until the proof run is reviewed.
- Preserved the complete v2.1.1 talent dataset and all existing Shaman/Demon Hunter BiS/consumable/enchant/stat data unchanged.

## 2.1.1 - 2026-09-26

- Fixed recommendation metadata parsing so Wowhead rows marked `(Recommended)` are treated as current guide recommendations, not alternates.
- Corrected Holy Paladin Delves default selection to Lightsmith and Windwalker Delves default selection to Conduit of the Celestials.
- Marked all six currently captured `(Recommended)` variants with `recommended = true` in the production dataset.
- Compacted verbose recommendation qualifiers on two-column build-selector buttons; full source names remain available in tooltips.
- Preserved all 268 exact v2.1.0 Blizzard import strings byte-for-byte.
- No changes to the three intentionally Pending cross-Hero-conflict rows.

## 2.1.0 - 2026-09-26

- Merged the safe automated expansion capture for all 34 non-Shaman/Demon Hunter specializations.
- Added **225 exact source-validated guide builds** from that run; combined installed total is now **268 exact builds / 3 Pending variants across all 40 Retail specializations**.
- Kept both Restoration Druid Delves Hero-tree variants Pending because the collector detected the same Blizzard export under Keeper of the Grove and Wildstalker; no cross-Hero value was guessed.
- Preserved all **43 previously validated Shaman/Demon Hunter exact builds** unchanged, including the intentional Elemental Stormbringer Raid Pending conflict.
- Talent-only specs now display the captured Wowhead guide update date from the selected build when available instead of only showing the generic live-source placeholder.
- Reworded Vengeance and generic talent-only notes so Pending language describes the fail-closed policy rather than implying a currently unresolved row when none exists.
- Non-Shaman/Demon Hunter specs remain talent-only; BiS, Consumables, Enchants/Gems, and Stats stay disabled until separate data packs are added.

## 2.0.0 - 2026-09-26

- Expanded the Guide Browser from Shaman/Demon Hunter to **all 40 Retail specializations**.
- Added talent-only guide packs for the 34 newly supported specs; Talents and Sources remain available while BiS/Consumables/Enchants/Stats stay disabled until dedicated data packs are added.
- Expanded `supported_build_sources.json` to all classes/specs with exact specialization IDs, Wowhead talent-guide URLs, and expected Hero Talent trees.
- Added `Capture-WowheadBuilds.ps1 -NewClassesOnly` for a single automated pass over the 34 expansion specs.
- Added automatic detection of the visible Wowhead guide update date when a manifest entry does not pin one.
- Preserved the v1.9.8 production build dataset unchanged: 43 exact builds and the single intentional Elemental Stormbringer Raid Pending row.
- Added regression coverage for all-40-spec manifest completeness and source-date parsing.

## 1.9.8 - 2026-09-26

- Resolved **Vengeance - Aldrachi Reaver - Raid Council** from the exact Blizzard export embedded in that Wowhead row's `Build` URL.
- Resolved **Vengeance - Annihilator - Raid Cleave (Best)** from the exact Blizzard export embedded in that Wowhead row's `Build` URL.
- Production talent data is now **43 exact builds / 1 Pending build** across the supported Shaman and Demon Hunter specs.
- Kept **Elemental - Stormbringer - Raid** Pending because Wowhead currently exposes the same Blizzard export for both Farseer Raid and Stormbringer Raid; cross-Hero duplicates remain fail-closed.
- The collector now accepts row-scoped `/talent-calc/blizzard/<export>` URLs directly after Blizzard header/spec validation instead of navigating them through a calculator page.
- Embedded calculator **Export Talents** controls are no longer treated as primary guide-table Copy rows, preventing duplicate/phantom variants from entering generated data.
- Existing exact build strings remain unchanged.

## 1.9.7 - 2026-09-26

- Hardened the final-Pending Wowhead resolver without changing the installed **41 exact / 3 Pending** production build dataset.
- Reworked guide-row discovery so div/grid-based Wowhead import tables are treated as logical source rows even when the Copy control and Build link live in sibling cells rather than a literal `<tr>`.
- Expanded row-scoped Build-link discovery to inspect source-row anchors and URL-bearing control attributes while preserving the exact source-row provenance boundary.
- Tagged each logical source row so delayed row-local import inputs are sampled from the correct row instead of only the Copy button's immediate parent.
- Added a JavaScript Build-control fallback for rows whose Build action has no plain href: the collector opens a disposable guide clone, clicks only that row's Build control, records popup/history/talent-calculator navigation, and then asks that scoped calculator page for its native Export Talents value.
- Added richer per-row diagnostics (`row_sources` / discovered Build URLs) so any still-Pending row can be debugged without manually copying talent strings.
- Preserved all v1.9.6 exact imports and fail-closed Pending states; no BiS, consumable, enchant, gem, stat-priority, UI layout, or runtime talent behavior changed.

## 1.9.6 - 2026-09-26

- Merged only newly resolved exact builds from the latest targeted Wowhead capture; previously validated exact strings were preserved.
- Enhancement Raid now has distinct exact **Totemic - Single Target** and **Totemic - Raid Cleave** variants instead of one ambiguous Pending row.
- Devourer is now complete for the currently supported guide variants: **8 exact / 0 Pending** across Raid, Mythic+, and Delves.
- The bundled dataset now contains **41 exact builds / 3 Pending builds** across the six supported specs.
- Remaining Pending variants: Elemental **Stormbringer - Raid**, Vengeance **Aldrachi Reaver - Raid Council**, and Vengeance **Annihilator - Raid Cleave**.
- Enhancement Delves exact strings from v1.9.4 were retained even though the latest targeted capture could not re-extract those rows.
- No BiS, consumable, enchant, gem, stat-priority, talent-viewer, comparison, or loadout-import behavior changed.

## 1.9.5 - 2026-09-26

- Hardened the automated Pending-build resolver without changing the installed **36 exact / 7 Pending** production build dataset.
- Added a per-attempt clipboard sentinel plus explicit clipboard readback so a Copy control that fails silently cannot inherit the previous guide row's valid export.
- Added up to three source-row Copy attempts with longer waits for delayed Wowhead client-side generation.
- Added a source-scoped **Build / talent-calculator fallback**: when the guide-table Copy control does not expose a valid Blizzard export, the collector follows only that exact row's Build link and asks the scoped Wowhead page for its native **Export Talents** value. No calculator-state-to-Blizzard reconstruction is performed.
- Added Copy-button variant hints so source rows with duplicate visible labels can remain distinct when their controls explicitly identify **Cleave**, **Council**, or **Raid ST**. This targets the current Enhancement Totemic duplicate-label case without guessing talent selections.
- Added cross-Hero corroboration: if a direct table capture duplicates an earlier export under a different Hero tree, the current row's own Build link is consulted before the normal fail-closed contradiction check.
- Updated the Windows wrapper to accept both comma-separated specialization IDs and native PowerShell arrays for targeted capture.
- Collector regression suite now contains **13 passing unit tests**, plus a synthetic Chromium test confirming duplicate visible Raid labels remain separate exact variants.
- No BiS, consumable, enchant, gem, stat-priority, UI layout, or bundled guide-build import strings changed.

## 1.9.4 - 2026-09-26

- Merged the safe improvements from the targeted Wowhead retry for Elemental, Enhancement, Vengeance, and Devourer.
- Added **6 newly resolved exact builds** without manual talent-string copying.
- Enhancement Delves now has exact **Stormbringer** and **Totemic (Best)** builds; only Raid Totemic remains Pending.
- Vengeance gained exact **Aldrachi Reaver - Raid Cleave**, both Mythic+ variants, and **Annihilator - Delves (Best)**; only Aldrachi Reaver Raid Council and Annihilator Raid Cleave remain Pending.
- Preserved every previously exact build when the targeted run returned the same string, and preserved the hand-validated Elemental Farseer Raid build despite the collector continuing to flag the automated Raid row as cross-Hero ambiguous.
- Installed dataset is now **36 exact builds / 7 Pending variants** across the six supported specializations.
- No BiS, consumable, enchant, gem, or stat-priority recommendations changed.

## 1.9.3 - 2026-09-25

- Reworked the guide-variant selector into a scalable **two-column grid** so long names such as Single Target, Raid Cleave, and Raid Council no longer collide.
- Added variant hover tooltips with the full build name, Hero tree, recommendation state, and exact/Pending status.
- Removed stale talent-description wording that still instructed users to manually paste Wowhead exports even when exact/fail-closed variant data is now managed by the addon.
- Hardened the browser collector with a delayed second sample that is strictly scoped to the clicked row, its `aria-controls` target, or the visible dialog.
- Added targeted bulk capture by specialization ID and Windows `-SpecID` passthrough for faster retries of unresolved specs.
- Preserved the v1.9.2 production build dataset unchanged: **30 exact builds / 13 Pending variants**.
- No BiS, consumable, enchant, gem, stat-priority, or guide-build import strings changed.

## 1.9.2 - 2026-09-25

- Promoted the safe results from the hardened live Wowhead browser capture into the in-game guide dataset.
- Added **29 automatically captured exact builds** across Elemental, Enhancement, Restoration, Havoc, Vengeance, and Devourer.
- Preserved the previously hand-validated **Elemental Farseer Raid** string when the automated run correctly flagged that Raid row as cross-Hero ambiguous; installed total is therefore **30 exact builds**.
- Kept **13 unresolved variants fail-closed**. They remain visible as Pending and cannot be viewed/imported as exact builds until a future capture resolves them.
- Restoration and Havoc now have exact source-validated strings for every guide-listed variant found by the hardened collector.
- Fixed generated labels that already contain `[Best]` from rendering a duplicate `[Best] [Best]` suffix in the Talent tab.
- Changed bulk-generation defaults so a source-marked recommended build remains the default even if its exact transport is still Pending; an exact alternate is no longer silently promoted as the apparent recommendation.
- No pending, conflicting, wrong-spec, or ambiguous captured value was promoted into an exact bundled build.

## 1.9.1 - 2026-09-25

- Hardened the automated Wowhead collector after reviewing the first successful bulk capture.
- Fixed the Windows PowerShell wrapper so its default capture directory is resolved after `$PSScriptRoot` is available; `-OutputDirectory` is no longer required.
- Added per-specialization Hero-tree allowlists so author/byline Copy widgets cannot be misidentified as Hero Talent variants.
- Changed category classification to trust the source row first and only then the nearest relevant heading, preventing stale Delves headings from reclassifying Raid/Mythic+ rows.
- Removed the unsafe page-wide visible-input fallback. DOM fallback capture is now restricted to the active element or a visible dialog opened by the clicked source control.
- Added repeated-row reconciliation: identical duplicate widgets are deduplicated, conflicting duplicate exports fail closed, and one Blizzard export attributed to different Hero trees is rejected as contradictory.
- Added regression coverage for stale-heading classification, Hero-tree allowlists, duplicate reconciliation, and cross-Hero contradiction rejection.
- No newly captured talent strings are bundled in this tooling-hardening release; the next bulk run will generate a cleaner review set before merge.

## 1.9.0 - 2026-09-25

- Added an automated **browser-backed Wowhead Copy collector** (`tools/wowhead_browser_capture.py`) so exact Blizzard talent import strings no longer need to be copied manually as the normal update workflow.
- The collector drives a real Chromium page with Playwright, discovers guide Copy controls, captures the exact clipboard value, classifies Raid/Mythic+/Delves rows, detects nearby Hero-tree headings, preserves `(Best)` recommendations, and generates schema-v2 guide data.
- Added Blizzard export-header decoding at collection time. Exact candidates must decode to the configured specialization ID before they can be promoted; shorter Wowhead calculator-state strings are rejected even when they look base64-like.
- Added automatic duplicate-variant naming for guides that publish multiple builds for the same Hero tree/content category (for example Single Target and Raid Cleave).
- Added `tools/wowhead_bulk_capture.py` plus `tools/supported_build_sources.json` to capture every currently bundled Shaman and Demon Hunter talent guide in one run.
- Added optional Windows `tools/Capture-WowheadBuilds.ps1` wrapper for a one-command bulk capture without manually copying individual strings.
- Added regression tests covering Elemental export-header decoding, calculator-state rejection, content classification, and duplicate-variant keys.
- Kept manual/static `wowhead_build_data.py` as a fallback, but hardened `--import-code` with the same specialization-header validation.
- No new unverified Stormbringer or other talent strings were bundled in this release; existing Elemental exact builds and all other in-game guide data remain unchanged from v1.8.0.

## 1.8.0 - 2026-09-25

- Added **multi-build guide variant support** inside each Raid, Mythic+, and Delves category.
- Upgraded `GuideBuilds.lua` to schema v2 with per-category `defaultBuild`, ordered variants, recommended markers, compact labels, and fail-closed pending variants.
- Added a new **Guide Builds** selector to the Talent tab. Selecting a variant changes the target used by View, Compare, Import, and Copy.
- Variant selection is remembered independently per specialization and content category.
- Switching content categories or guide variants now clears an old talent preview/comparison so stale targets cannot remain on screen.
- Current Elemental guide coverage now represents all six guide-listed rows: Farseer and Stormbringer for Raid, Mythic+, and Delves.
- Existing Farseer Raid, Mythic+, and Delves strings remain exact and validated; Farseer is marked as the current recommendation.
- Stormbringer Raid, Mythic+, and Delves are visible as **Pending** alternatives until their exact live Wowhead Copy strings are captured. No Stormbringer string was guessed or reconstructed.
- Updated `tools/wowhead_build_data.py` to generate schema-v2 multi-variant data with `--variant`, `--import-code CATEGORY.VARIANT=STRING`, `--recommended`, and `--default`.
- Preserved schema-v1 runtime compatibility for older generated build data.
- Fixed the runtime addon version badge/data constant so it now matches the packaged version.
- No BiS, consumable, enchant, gem, or stat-priority data changed.

## 1.7.3 - 2026-09-25

- Bundled the exact **Elemental Shaman - Delves (Best)** Blizzard import string captured from Wowhead's live **Copy** control.
- Marked the Delves target as **Farseer** and kept final specialization, tree, Hero-tree completeness, and round-trip validation in the WoW client.
- Enabled **View Guide Build**, **Compare to Mine**, **Import as Loadout**, and **Copy Build String** for Elemental Delves.
- With this release, **Elemental Shaman Raid, Mythic+, and Delves** all have exact bundled guide builds.
- No BiS, consumable, enchant, gem, stat-priority, or non-Elemental guide data changed from v1.7.2.

## 1.7.2 - 2026-09-24

- Bundled the exact **Elemental Shaman - Mythic+** Blizzard import string captured from Wowhead's live **Copy** control.
- Marked the Mythic+ target as **Farseer** and kept final specialization, tree, Hero-tree completeness, and round-trip validation in the WoW client.
- Enabled **View Guide Build**, **Compare to Mine**, **Import as Loadout**, and **Copy Build String** for Elemental Mythic+.
- Elemental Raid remains unchanged and fully validated from v1.7.1.
- Elemental Delves remains fail-closed until its exact current guide value is collected and validated.
- No BiS, consumable, enchant, gem, stat-priority, or non-Elemental guide data changed from v1.7.1.

## 1.7.1 - 2026-09-24

- Bundled the first exact guide build: **Elemental Shaman - Raid (Best)**.
- The Blizzard import string was captured directly from Wowhead's live **Copy** control; no talent-name reconstruction or calculator-state conversion is used.
- Marked the bundled Raid build as **Farseer** and kept final specialization, tree, Hero-tree completeness, and round-trip checks in the WoW client.
- Enabled **View Guide Build**, **Compare to Mine**, **Import as Loadout**, and **Copy Build String** for Elemental Raid.
- Mythic+ and Delves remain fail-closed until their exact live import strings are collected.
- Hardened the external Wowhead collector so calculator URL state is discovery-only and explicit Blizzard import codes can be supplied with `--import-code`.
- No BiS, consumable, enchant, gem, stat-priority, or non-Elemental guide data changed from v1.7.0.

## 1.7.0 - 2026-09-24

- Added the first **Wowhead Build Data pipeline** foundation for exact Raid/Mythic+/Delve talent transports.
- Added generated `GuideBuilds.lua` support without hard-coding guessed talent names or node selections.
- Added `tools/wowhead_build_data.py`, which scans raw/saved Wowhead guide HTML for explicit `talent-calc/<class>/<spec>/<build-code>` transports and emits a reviewable candidate report.
- The generator requires an explicit `--select KEY=INDEX` before it can write bundled build data; ambiguous candidate discovery cannot silently become production data.
- Added direct **View Guide Build**, **Compare to Mine**, **Import as Loadout**, and **Copy Build String** actions whenever an exact source-validated build is actually bundled.
- Added runtime safety checks for bundled guide builds: current Retail decode, expected specialization, tree compatibility, level-90 Hero-tree completeness, optional expected Hero-tree match, and WoW import-string round-trip validation when available.
- Added visible per-build status messaging when an exact guide transport has not yet been bundled.
- Preserved **Paste / Preview Build** as a secondary/fallback workflow rather than removing a known-good manual path.
- Did **not** bundle an Elemental Raid/Mythic+/Delve import string in this release because the current exact Wowhead-generated transport was not available for independent validation in the collected static guide payload. No substitute string was guessed.
- No BiS, consumable, enchant, gem, stat-priority, or descriptive talent recommendation data changed from v1.6.0.

## 1.6.0 - 2026-09-24

- Expanded Azeroth Guidebook from Shaman-only to a true **cross-class guide browser**.
- Added complete Demon Hunter 12.1.0 support for **Havoc, Vengeance, and Devourer**.
- Added a scalable two-stage **Guide Browser**: choose a class, then choose a bundled specialization, or select Use Current Spec.
- Added automatic current-spec routing for supported Demon Hunter characters while preserving Shaman auto-follow behavior.
- Added `/agb havoc`, `/agb vengeance`, `/agb veng`, `/agb devourer`, and `/agb dev` shortcuts.
- Added complete Havoc data: Raid/Mythic+/Delve talent guidance, BiS, crafted priorities, consumables, enchants, gems, stats, and source dates.
- Added complete Vengeance data: Raid/Mythic+/Delve talent guidance, BiS, crafted priorities, consumables, enchants, gems, stats, and source dates.
- Added complete Devourer data: Raid/Mythic+/Delve talent guidance, BiS, crafted priorities, consumables, enchants, gems, stats, and source dates.
- Generalized pasted-import validation so wrong-class and wrong-spec strings identify the correct bundled target guide instead of assuming Shaman.
- Generalized Preview My Build and live comparison checks to require both the displayed class and specialization to match the active character.
- Preserved the v1.4/v1.5 visual talent trees, comparison colors, Differences Only filter, mismatch navigation, Hero-tree completeness checks, and Import Target as Loadout workflow.

## 1.5.0 - 2026-09-24

- Expanded Azeroth Guidebook from Elemental-only data to **full Shaman support**: Elemental, Enhancement, and Restoration.
- Added a top-right **Shaman specialization selector** with Use Current Spec, Elemental, Enhancement, and Restoration choices.
- Shaman characters now automatically follow their active spec when no manual guide override is selected.
- Added `/agb enhancement`, `/agb enh`, `/agb restoration`, `/agb resto`, `/agb current`, and `/agb auto` shortcuts while retaining Elemental and minimap commands.
- Added complete Enhancement Shaman 12.1.0 data: Raid/Mythic+/Delve talent guidance, BiS, crafted priorities, consumables, enchants, gems, stats, and source dates.
- Added complete Restoration Shaman 12.1.0 data: Raid/Mythic+/Delve talent guidance, BiS, crafted priorities, consumables, enchants, gems, stats, and source dates.
- Generalized **Preview My Build** so it works for whichever bundled Shaman spec is currently displayed and active on the character.
- Pasted talent strings are now checked against the displayed specialization to prevent an Enhancement/Restoration/Elemental tree from appearing under the wrong guide header.
- Retained the v1.4.0 comparison workflow, Differences Only filter, mismatch navigation, visual trees, Hero-tree completeness checks, and Import Target as Loadout.
- Updated the data-pack refresh date to 2026-09-24.

## 1.4.0 - 2026-09-24

- Added **Differences Only** mode to hide matching/unselected comparison nodes and surface only target-only, My Build-only, rank-difference, and choice-difference nodes.
- Added **Previous Difference** and **Next Difference** navigation across Class, Spec, and Hero mismatches.
- Focus navigation automatically switches to the correct talent tree, highlights the focused node, and scrolls it into view.
- Added **Clear Focus** for returning to manual comparison browsing.
- Comparison tooltips now include a direct `Target -> My Build` transition line for mismatches.
- Added **Import Target as Loadout**, backed by Blizzard's `C_ClassTalents.ImportLoadout` API.
- Added a loadout-name dialog and validation for wrong specialization, incomplete max-level Hero trees, unavailable config slots, and API import failures.
- Target import uses the exact decoded target entries plus the original Blizzard/Wowhead import string; the addon does not manually click or stage individual talents.
- Preserved v1.3.0 comparison colors, summaries, live-build reading, max-level Hero checks, visual trees, BiS, consumables, enchants/gems, stats, and sources.
- No guide recommendation data changed in this release.

## 1.3.0 - 2026-09-24

- Added **Guide / Target vs My Build** talent comparison mode.
- Pasted Blizzard/Wowhead import strings are retained as the target build while the addon separately reads the character's live active configuration.
- Added three-way preview controls: **Target Build**, **My Build**, and **Compare**.
- Added color-coded comparison nodes and paths: gold for exact matches, red for target-only selections, blue for My Build-only selections, purple for rank/choice differences, and gray for unselected nodes.
- Added Class / Spec / Hero difference counters.
- Added a plain-English difference list for the active tree.
- Added comparison-aware tooltips showing both the target selection and the current character selection.
- Added explicit handling when the target and current character use different Hero trees.
- Added copy buttons for both target and current-character import strings when available.
- Preserved v1.2.2 live-build reading, max-level Hero-tree completeness checks, visual talent trees, BiS, consumables, enchants/gems, stats, and sources.
- No guide recommendation data changed in this release.

## 1.2.1 - 2026-09-23

- Dynamically centers visual talent trees within the available panel width.
- Allows Class and Specialization layouts to spread farther across the panel when space permits.
- Gives Hero Talent trees a larger coordinate scale so compact Hero layouts are easier to read.
- Changed tree selectors to selected/visible counts, such as `Class 28/46`, `Spec 29/42`, and `Farseer 4/14`.
- Replaced the unsupported choice-node glyph with a reliable cyan `C` badge.
- Hides `0/x` rank labels on unselected multi-rank nodes.
- Increased selected-path line thickness and contrast.
- Compressed the active-preview header and controls to put more of the tree on screen before scrolling.
- Condensed the bundled Wowhead calculator-reference notice while a preview is active.
- No guide-data recommendations were changed from v1.2.0.

## 1.2.0 - 2026-09-23

- Added a full visual talent-tree mode for imported Blizzard/Wowhead builds.
- Added separate **Class**, **Specialization**, and **active Hero** tree views.
- Uses WoW's live trait node `posX` / `posY` coordinates for layout.
- Uses WoW's live `visibleEdges` information to draw talent-tree connections.
- Highlights selected talent nodes and selected paths in gold while leaving unselected live-tree nodes visible and dimmed.
- Added multi-rank node indicators and choice-node markers.
- Added normal Blizzard spell tooltips to visual-tree nodes.
- Added a **Visual Tree / Selected List** display toggle; the v1.1 card list remains available.
- Hero node positions are normalized around the active Hero subtree, mirroring Blizzard's shared talent UI behavior.
- Retains v1.1.1 filtering for inactive Hero subtrees and hidden `SubTreeSelection` nodes.
- No guide-data recommendations were changed from v1.1.1.

## 1.1.1 - 2026-09-23

- Fixed the talent viewer showing purchased talents from the inactive Hero Talent subtree.
- Hero talents are now filtered using WoW's live `subTreeActive` / `isActive` state, matching the active Hero tree shown by Blizzard's talent UI.
- Hidden `SubTreeSelection` nodes are no longer rendered as fake talents such as `Talent 123377`.
- The Hero section now includes the active Hero tree name when WoW exposes it (for example, `Hero - Farseer`).
- No guide-data recommendations were changed from v1.1.0.

## 1.1.0 - 2026-09-23

- Added an in-game Blizzard talent import-string decoder and viewer.
- Added paste/preview support for compatible Blizzard and Wowhead talent strings.
- Added a genuine Wowhead-hosted Elemental/Farseer calculator string as a bundled viewer reference.
- Added live talent names, icons, ranks, Class/Spec/Hero grouping, and spell tooltips.
- Added serialization-version checking and tree-hash validation when the import string embeds a tree hash.
- Added Copy Import String from the active talent preview.
- Kept the exact Wowhead guide import-code limitation clearly labeled rather than substituting an unrelated build.
- Retained all v1.0 BiS, consumable, enchant/gem, stat, source, ownership, minimap, and AddOn Compartment features.

## 1.0.0 - 2026-09-23

- Initial Retail 12.1.0 release.
- Added Elemental Shaman data pack.
- Added Talents, BiS, Consumables, Enchants & Gems, Stats, and Sources tabs.
- Added in-game item tooltips and Shift-click item chat linking.
- Added equipped/bag ownership markers for BiS items.
- Added minimap launcher, AddOn Compartment launcher, and slash commands.

### v3.12.0 startup/minimap follow-up
- Tightened the minimap launcher orbit to the outside rim (8px exterior offset instead of 22px).
- Hardened `/agb` first-login availability by rebuilding WoW's slash-command hash after registration and re-registering at `PLAYER_ENTERING_WORLD`.
- Preserves the validated draggable launcher angle and all companion/source-refresh behavior.