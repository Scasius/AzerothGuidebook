# Azeroth Guidebook Companion

The companion is optional. Azeroth Guidebook works with its bundled reviewed data without it.

## v3.16.0 compatibility

Azeroth Guidebook v3.16.0 adds in-addon Activity Profiles only. **Companion v1.1.0-rc1 remains the accepted companion baseline**; no companion protocol, refresh-history format, installation behavior, or source-pack validation changes are required for v3.16.0.


## CurseForge users

1. Install **Azeroth Guidebook** through CurseForge.
2. Download the current companion installer (`AzerothGuidebookCompanionSetup_v1.1.0-rc1.exe`) from the companion link on the CurseForge project page.
3. Run the installer once. Administrator rights are not required.
4. Launch/reload WoW. The Sources tab should show **Companion: Ready | v1.1.0-rc1**.
5. From then on, use only **Refresh Current Source**, **Refresh Current Spec**, or **Refresh All Sources** in-game.

## v1.1.0 refresh history

Azeroth Guidebook v3.15.0 adds Refresh Change Intelligence. Companion v1.1.0-rc1 is the accepted companion baseline for Azeroth Guidebook v3.15.0. It preserves all validated v1.0.0-rc5 install/startup/uninstall behavior and adds schema-v2 local refresh history. It retains the last five completed runs and compares validated source-pack snapshots by guide domain, separating recommendation changes from source-date-only updates.

The companion still accepts only validated packs and still writes non-destructive overrides. If a legacy local pack has no retained pre-refresh Lua snapshot, detailed diffing fails closed and the addon reports that the old baseline is unavailable instead of guessing.


The companion installs per-user under `%LOCALAPPDATA%\AzerothGuidebook\Companion`, starts automatically at Windows logon, and appears in Windows **Installed apps**. CurseForge addon updates do not remove it.

The previously accepted companion baseline for Azeroth Guidebook v3.13.0 was **v1.0.0-rc5**; v3.15.0 advances the accepted baseline to **v1.1.0-rc1** after live refresh-history validation. Live validation confirmed installation, Windows Installed Apps registration, WoW Ready-state detection, all three refresh scopes, Windows completion notifications, reinstall/startup behavior, and uninstall. Uninstall immediately resets the addon-facing status to **Companion: Not installed** and disables the refresh buttons after `/reload`.

rc5 avoids `tasklist.exe` and `taskkill.exe` for process management. It first requests a clean companion shutdown through a local stop-request file and then uses native Windows process APIs only if an older or unresponsive process remains. This was added after Norton CyberCapture interfered with the external command path during live testing.

The executable is currently unsigned. Windows SmartScreen or third-party reputation systems may warn or scan a new build. Code signing is optional and deferred for the current release.