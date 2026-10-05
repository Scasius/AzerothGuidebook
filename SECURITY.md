# Security and trust

## Official downloads

Use these official distribution points:

- CurseForge for the Azeroth Guidebook addon.
- This GitHub repository's Releases page for the optional Windows Companion.

Do not download the companion from third-party mirrors.

## Companion behavior

The companion is optional and exists because World of Warcraft addons cannot perform arbitrary web requests.

It processes the Azeroth Guidebook source-refresh workflow, accepts only project-validated source packs, and writes fail-closed local overrides. Invalid, ambiguous, partial, mismatched, or corrupt data does not replace accepted guide data.

## Unsigned Windows installer

The current companion installer is unsigned. Windows or antivirus reputation systems may inspect a newly published build because its hash is new.

Current Companion v1.1.0 installer SHA-256:

`e3533fd3b20bb78a227ea1ee10f99caecb32f0ad67544c863173712515ffd337`

## Reporting a security issue

Do not post credentials, private account data, API keys, or other secrets in a public GitHub issue. For ordinary bugs and non-sensitive problems, use the repository Issues page.
