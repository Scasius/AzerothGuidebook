# Addon source

`AzerothGuidebook/` contains the source corresponding to the public **Azeroth Guidebook v3.16.0** release.

The installable addon folder is `AzerothGuidebook` itself.

## Generated rotation data

The official v3.16.0 release ZIP already includes the complete `GuideIcyRotations.lua` runtime file.

To keep the repository source tree manageable, that generated/reviewed file is stored in compressed form at:

`addon/generated/GuideIcyRotations.lua.gz`

If you want to run the addon directly from a repository checkout, decompress it to:

`addon/AzerothGuidebook/GuideIcyRotations.lua`

Example on macOS/Linux:

```bash
gzip -dc addon/generated/GuideIcyRotations.lua.gz > addon/AzerothGuidebook/GuideIcyRotations.lua
```

On Windows, use any gzip-capable archive tool to extract the same file into the addon folder.

## Target

- World of Warcraft Retail
- Interface: **120100 / 12.1.0**
- Addon: **v3.16.0**
