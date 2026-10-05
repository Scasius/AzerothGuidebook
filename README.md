# Azeroth Guidebook

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

- `addon/AzerothGuidebook/` — addon source for v3.16.0
- `addon/generated/` — compressed generated runtime data used when reconstructing a source checkout
- `companion/` — companion release/source information
- `docs/` — companion and project documentation
- `CHANGELOG.md` — public release highlights
- `SECURITY.md` — trust, download, and installer information

The official addon release ZIP contains all runtime files in expanded form. See [addon source notes](addon/README.md).

## Guide sources

Azeroth Guidebook can present reviewed information from:

- Wowhead
- Icy Veins
- U.GG

U.GG data is presented as **observed player data**, not as editorial Best-in-Slot recommendations.

Azeroth Guidebook is an independent project and is not affiliated with or endorsed by Blizzard Entertainment, Wowhead, Icy Veins, or U.GG. World of Warcraft and related names are trademarks of Blizzard Entertainment. Third-party names and content remain the property of their respective owners.

## Addon installation

The primary addon distribution is CurseForge.

For a manual installation, the resulting folder must be:

`World of Warcraft/_retail_/Interface/AddOns/AzerothGuidebook/`

Open the addon in game with:

- the minimap compass icon
- the AddOn Compartment
- `/agb`

## Optional Windows Companion

The addon works without the companion using its bundled reviewed data.

The optional **Azeroth Guidebook Companion** enables:

- Refresh Current Source
- Refresh Current Spec
- Refresh All Sources
- refresh notifications
- recent refresh history
- domain-level **What's New Since Last Refresh?** comparisons when the required before/after snapshots are available

Official Companion v1.1.0 release:

https://github.com/Scasius/AzerothGuidebook/releases/tag/companion-v1.1.0

See [Companion installation and safety notes](docs/COMPANION.md).

### Companion v1.1.0 checksums

Installer:

`e3533fd3b20bb78a227ea1ee10f99caecb32f0ad67544c863173712515ffd337`

Source package:

`aaa981043026bbe80efd1660083512194ae1fb44424278e302c00e06071ddd68`

## Current addon release

### Azeroth Guidebook v3.16.0

v3.16.0 adds specialization-specific Activity Profiles for **Raid**, **Mythic+**, and **Delves**. Profiles remember the exact guide configuration selected by the player, including source choices, talent context/build, U.GG context, gear-set context, and rotation context/preset.

The release also includes the official Azeroth Guidebook blue-and-gold compass branding for the in-game minimap launcher and AddOn Compartment.

Current production ZIP SHA-256:

`e75148378f99019b1d659b0ddadb1a1b1677ec511027d9f46c0aec0b92ce4f98`

## License

The original Azeroth Guidebook code and project assets are distributed under an **All Rights Reserved** license. See [LICENSE.txt](LICENSE.txt).

This license does not claim ownership of Blizzard Entertainment assets, third-party trademarks, or third-party guide content.
