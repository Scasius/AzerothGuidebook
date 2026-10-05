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

- `addon/AzerothGuidebook/` — current addon source
- `companion/source/` — current companion source
- `docs/` — installation and project documentation
- `branding/` — public Azeroth Guidebook branding assets

## Guide sources

Azeroth Guidebook can present reviewed information from Wowhead, Icy Veins, and U.GG.

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
- domain-level “What’s New Since Last Refresh?” comparisons when the required before/after snapshots are available

Download the companion from this repository's **Releases** page.

See [Companion installation and safety notes](docs/COMPANION.md).

## Current release

### Azeroth Guidebook v3.16.0

v3.16.0 adds specialization-specific Activity Profiles for **Raid**, **Mythic+**, and **Delves**. Profiles remember the exact guide configuration selected by the player, including source choices, talent context/build, U.GG context, gear-set context, and rotation context/preset.

The release also includes the official Azeroth Guidebook blue-and-gold compass branding for the in-game minimap launcher and AddOn Compartment.

### Companion v1.1.0

Companion v1.1.0 is the validated public Windows companion paired with v3.16.0.

## License

The original Azeroth Guidebook code and project assets are distributed under an **All Rights Reserved** license. See [LICENSE.txt](LICENSE.txt).

This license does not claim ownership of Blizzard Entertainment assets, third-party trademarks, or third-party guide content.
