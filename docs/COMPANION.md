# Azeroth Guidebook Companion

Current public companion: **v1.1.0**

The companion is optional. Azeroth Guidebook works normally with its bundled reviewed guide data without any external program.

## What the companion enables

With the companion installed, the in-game **Sources** tab can perform:

- **Refresh Current Source**
- **Refresh Current Spec**
- **Refresh All Sources**
- Windows completion notifications
- recent refresh history
- “What’s New Since Last Refresh?” domain-level change summaries when retained snapshots are available

The companion runs outside World of Warcraft because WoW addons cannot make arbitrary web requests.

## Download

Use the official GitHub release:

[Azeroth Guidebook Companion v1.1.0](https://github.com/Scasius/AzerothGuidebook/releases/tag/companion-v1.1.0)

Installer:

`AzerothGuidebookCompanionSetup_v1.1.0.exe`

Validated installer SHA-256:

`e3533fd3b20bb78a227ea1ee10f99caecb32f0ad67544c863173712515ffd337`

## Installation

1. Install **Azeroth Guidebook v3.16.0** through CurseForge or manually.
2. Download `AzerothGuidebookCompanionSetup_v1.1.0.exe` from the official GitHub release above.
3. Run the installer. Administrator rights are not required for the normal per-user install.
4. Launch or return to World of Warcraft.
5. Type `/reload`.
6. Open Azeroth Guidebook and go to **Sources**.
7. Confirm the status shows **Companion: Ready | v1.1.0**.

The companion installs per-user under:

`%LOCALAPPDATA%\AzerothGuidebook\Companion`

It registers for startup at Windows logon and appears in **Windows Settings > Apps > Installed apps**.

## Uninstall

Uninstall **Azeroth Guidebook Companion** from Windows **Installed apps**.

After uninstalling, use `/reload` in WoW. Azeroth Guidebook should immediately report **Companion: Not installed**, with refresh buttons disabled. The addon continues to work from bundled data.

## Refresh-history behavior

Companion v1.1.0 includes the schema-v2 local refresh history used by Azeroth Guidebook's **What’s New Since Last Refresh?** feature. It retains the newest five completed runs and compares validated before/after source-pack snapshots across:

- Talents
- Gear/BiS
- Consumables
- Enchants & Gems
- Stats
- Rotation

Recommendation changes are kept separate from source-date-only updates. When an older local fingerprint exists without the corresponding retained Lua snapshot, detailed comparison fails closed instead of guessing.

## Safety model

The companion accepts only Azeroth Guidebook's validated source-pack workflow and writes non-destructive local overrides. Invalid, ambiguous, partial, mismatched, or corrupt data does not replace accepted guide data.

Normal users do not need to run PowerShell, Python, browser automation, or manual refresh scripts.

The companion's process-management lifecycle uses native Windows process APIs rather than depending on `tasklist.exe` / `taskkill.exe`.

## Antivirus / reputation

The current installer is unsigned. Windows SmartScreen or third-party security/reputation products may inspect or warn about a newly published build. Only download the installer from the official Azeroth Guidebook GitHub release.

## Current pairing

- Addon: **Azeroth Guidebook v3.16.0**
- Companion: **v1.1.0**
