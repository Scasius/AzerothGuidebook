# Addon source

This directory contains the source for **Azeroth Guidebook v3.16.0**.

The installable addon folder is:

`addon/AzerothGuidebook/`

For normal players, the recommended installation path is the CurseForge release rather than cloning this repository.

## Generated guide data

Most reviewed guide datasets are stored directly in the source tree.

`GuideIcyRotations.lua` is a large generated/reviewed runtime artifact. The official v3.16.0 release ZIP contains the fully expanded file. A compressed copy is kept at:

`addon/generated/GuideIcyRotations.lua.gz`

To recreate it from a repository checkout, decompress that file to:

`addon/AzerothGuidebook/GuideIcyRotations.lua`

For example on macOS/Linux:

```bash
gzip -dc addon/generated/GuideIcyRotations.lua.gz > addon/AzerothGuidebook/GuideIcyRotations.lua
```

The official release ZIP is already complete and requires no reconstruction step.

## Target

- World of Warcraft Retail
- Interface: 12.1.0 / 120100
- Addon: v3.16.0
