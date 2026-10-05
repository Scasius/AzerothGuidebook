local addonName, AGB = ...

-- Validated source-refresh override pack.
-- This file is intentionally empty in the distributed addon. The external companion
-- rewrites it only with project-validated, hash-verified source packs.
AGB.LocalRefreshPack = AGB.LocalRefreshPack or {
    schemaVersion = 1,
    generatedAt = nil,
    appliedPacks = 0,
}