# Azeroth Guidebook

![Azeroth Guidebook](assets/AzerothGuidebook_Logo.png)

**Azeroth Guidebook** is a World of Warcraft Retail PvE guide companion that brings reviewed guide information, source-aware character auditing, and activity-specific setup management directly into the game.

Current public versions:

- Addon: **v3.16.0**
- Optional Windows Companion: **v1.1.0**
- Target client: **Retail 12.1.0**

## Highlights

- Talents with source-listed Raid, Mythic+, and Delves builds
- Visual talent-tree preview and build comparison
- Rotation, opener, cooldown, and priority guidance
- Gear recommendations and U.GG observed-player gear views
- Consumables
- Enchants and gems
- Stat priorities
- **My Character** live auditing
- **Character Action Plan** with direct navigation to issues
- **Activity Profiles** for Raid, Mythic+, and Delves
- Source selection across Wowhead, Icy Veins, and U.GG
- Optional one-click source refresh and refresh-change history through the Windows Companion

## Repository layout

- `addon/AzerothGuidebook/` — current addon source for v3.16.0
- `addon/generated/` — compressed generated runtime artifact used by the addon source tree
- `companion/source/` — current Windows companion source for v1.1.0
- `docs/` — installation and project documentation
- `assets/` — public project branding assets

## Guide sources

Azeroth Guidebook can present reviewed information from Wowhead, Icy Veins, and U.GG. U.GG data is presented as **observed player data**, not as editorial Best-in-Slot recommendations.

Azeroth Guidebook is an independent project and is not affiliated with or endorsed by Blizzard Entertainment, Wowhead, Icy Veins, or U.GG. World of Warcraft and related names are trademarks of Blizzard Entertainment. Third-party names and content remain the property of their respective owners.

## Addon installation

The primary addon distribution is CurseForge.

For a manual installation, the resulting folder must be:

`World of Warcraft/_retail_/Interface/AddOns/AzerothGuidebook/`

Open the addon in game with the minimap compass icon, the AddOn Compartment, or `/agb`.

The official release ZIP is complete and requires no source-tree reconstruction. See [addon/README.md](addon/README.md) if building from this repository checkout.

## Optional Windows Companion

The addon works without the companion using its bundled reviewed data.

The optional **Azeroth Guidebook Companion** enables one-click source/spec/all-source refresh, notifications, recent refresh history, and domain-level “What’s New Since Last Refresh?” comparisons when retained snapshots are available.

The current public Windows companion is **v1.1.0**:

[Azeroth Guidebook Companion v1.1.0](https://github.com/Scasius/AzerothGuidebook/releases/tag/companion-v1.1.0)

See [docs/COMPANION.md](docs/COMPANION.md) for installation, uninstall, and safety notes.

## Current releases

### Azeroth Guidebook v3.16.0

[GitHub release](https://github.com/Scasius/AzerothGuidebook/releases/tag/addon-v3.16.0)

v3.16.0 adds specialization-specific Activity Profiles for **Raid**, **Mythic+**, and **Delves**. Profiles remember the exact guide configuration selected by the player, including source choices, talent context/build, U.GG context, gear-set context, and rotation context/preset.

The release also includes the official Azeroth Guidebook blue-and-gold compass branding for the in-game minimap launcher and AddOn Compartment.

Release ZIP SHA-256:

`e75148378f99019b1d659b0ddadb1a1b1677ec511027d9f46c0aec0b92ce4f98`

### Companion v1.1.0

[GitHub release](https://github.com/Scasius/AzerothGuidebook/releases/tag/companion-v1.1.0)

Companion v1.1.0 is the live-validated public Windows companion paired with v3.16.0.

Installer SHA-256:

`e3533fd3b20bb78a227ea1ee10f99caecb32f0ad67544c863173712515ffd337`

## License

The original Azeroth Guidebook code and project assets are distributed under an **All Rights Reserved** license. See [LICENSE.txt](LICENSE.txt).

This license does not claim ownership of Blizzard Entertainment assets, third-party trademarks, or third-party guide content.
