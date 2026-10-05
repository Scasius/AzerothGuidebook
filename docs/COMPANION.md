# Azeroth Guidebook Companion

Current public companion: **v1.1.0**

The Azeroth Guidebook Companion is an **optional Windows application** used by the in-game addon to perform one-click guide-source refreshes outside the World of Warcraft sandbox.

The addon works without it using bundled reviewed data.

## What it enables

- Refresh Current Source
- Refresh Current Spec
- Refresh All Sources
- refresh notifications
- recent refresh history
- domain-level change summaries when retained before/after snapshots are available

## Installation

1. Download `AzerothGuidebookCompanionSetup_v1.1.0.exe` from this repository's **Releases** page.
2. Close or leave World of Warcraft running; the installer can be run independently.
3. Run the installer.
4. Launch or return to World of Warcraft.
5. Type `/reload`.
6. Open Azeroth Guidebook and go to **Sources**.
7. Confirm the status shows **Companion: Ready | v1.1.0**.

## Uninstall

Use **Windows Settings > Apps > Installed apps > Azeroth Guidebook Companion > Uninstall**.

After uninstalling, use `/reload` in WoW. Azeroth Guidebook should report **Companion: Not installed** and continue working from bundled data.

## Safety model

The companion accepts only Azeroth Guidebook project-validated source packs and writes fail-closed local overrides. It does not require normal users to run PowerShell, Python, browser automation, or copy/paste refresh commands.

## Antivirus / reputation

The installer is currently unsigned. Some antivirus or reputation systems may inspect or delay a newly published installer because its hash is new. Only download the companion from this official repository's Releases page.

## Current pairing

- Addon: **Azeroth Guidebook v3.16.0**
- Companion: **v1.1.0**
