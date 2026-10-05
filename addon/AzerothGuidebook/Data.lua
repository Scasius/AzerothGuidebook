local addonName, AGB = ...

AGB.VERSION = "3.16.0"
AGB.DATA_REFRESHED = "2026-09-29"
AGB.DATA_REFRESHED_EPOCH = 1790640000 -- 2026-09-29; freshness is informational only.
AGB.GUIDE_TARGET_LEVEL = 90 -- Reviewed endgame guide target for Retail Midnight.

AGB.GuideClasses = {
    {
        classFile = "DEATHKNIGHT",
        name = "Death Knight",
        specs = {
            { id = 250, name = "Blood" },
            { id = 251, name = "Frost" },
            { id = 252, name = "Unholy" },
        },
    },
    {
        classFile = "DEMONHUNTER",
        name = "Demon Hunter",
        specs = {
            { id = 577, name = "Havoc" },
            { id = 581, name = "Vengeance" },
            { id = 1480, name = "Devourer" },
        },
    },
    {
        classFile = "DRUID",
        name = "Druid",
        specs = {
            { id = 102, name = "Balance" },
            { id = 103, name = "Feral" },
            { id = 104, name = "Guardian" },
            { id = 105, name = "Restoration" },
        },
    },
    {
        classFile = "EVOKER",
        name = "Evoker",
        specs = {
            { id = 1467, name = "Devastation" },
            { id = 1468, name = "Preservation" },
            { id = 1473, name = "Augmentation" },
        },
    },
    {
        classFile = "HUNTER",
        name = "Hunter",
        specs = {
            { id = 253, name = "Beast Mastery" },
            { id = 254, name = "Marksmanship" },
            { id = 255, name = "Survival" },
        },
    },
    {
        classFile = "MAGE",
        name = "Mage",
        specs = {
            { id = 62, name = "Arcane" },
            { id = 63, name = "Fire" },
            { id = 64, name = "Frost" },
        },
    },
    {
        classFile = "MONK",
        name = "Monk",
        specs = {
            { id = 268, name = "Brewmaster" },
            { id = 270, name = "Mistweaver" },
            { id = 269, name = "Windwalker" },
        },
    },
    {
        classFile = "PALADIN",
        name = "Paladin",
        specs = {
            { id = 65, name = "Holy" },
            { id = 66, name = "Protection" },
            { id = 70, name = "Retribution" },
        },
    },
    {
        classFile = "PRIEST",
        name = "Priest",
        specs = {
            { id = 256, name = "Discipline" },
            { id = 257, name = "Holy" },
            { id = 258, name = "Shadow" },
        },
    },
    {
        classFile = "ROGUE",
        name = "Rogue",
        specs = {
            { id = 259, name = "Assassination" },
            { id = 260, name = "Outlaw" },
            { id = 261, name = "Subtlety" },
        },
    },
    {
        classFile = "SHAMAN",
        name = "Shaman",
        specs = {
            { id = 262, name = "Elemental" },
            { id = 263, name = "Enhancement" },
            { id = 264, name = "Restoration" },
        },
    },
    {
        classFile = "WARLOCK",
        name = "Warlock",
        specs = {
            { id = 265, name = "Affliction" },
            { id = 266, name = "Demonology" },
            { id = 267, name = "Destruction" },
        },
    },
    {
        classFile = "WARRIOR",
        name = "Warrior",
        specs = {
            { id = 71, name = "Arms" },
            { id = 72, name = "Fury" },
            { id = 73, name = "Protection" },
        },
    },
}

AGB.SpecIndex = {}
for _, classInfo in ipairs(AGB.GuideClasses) do
    for _, specInfo in ipairs(classInfo.specs) do
        AGB.SpecIndex[specInfo.id] = {
            classFile = classInfo.classFile,
            className = classInfo.name,
            specName = specInfo.name,
        }
    end
end

local TALENT_LIMITATION = "Azeroth Guidebook supports live-captured multi-build guide data across every Retail specialization. Exact source-validated Wowhead builds expose direct View, Compare, Import, and Copy actions; unresolved or source-conflicting variants remain visible but fail closed to Paste / Preview Build. Row-scoped Wowhead Blizzard Build URLs are accepted only after header/spec validation, and every bundled string is revalidated against the live Retail talent tree before use. Level-90 Midnight builds with an incomplete active Hero Talent tree are rejected."

AGB.Data = {
    SHAMAN = {
        [262] = {
            className = "Shaman",
            specName = "Elemental",
            patch = "12.1.0",
            author = "HawkCorrigan",
            statPriority = "Intellect > Mastery > Haste = Critical Strike >> Versatility",
            statNote = "Use this as a rough reference. Large item-level gains can outweigh secondary-stat optimization; sim your character for final decisions.",
            statToolNote = "For DPS gearing decisions, use a character-specific simulator such as Raidbots rather than treating a generic stat order as absolute.",

            talents = {
                sourceName = "Wowhead - Best Elemental Shaman Talent Tree Builds - Midnight",
                sourceUpdated = "2026-08-21",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/elemental/talent-builds-pve-dps",
                previewLevel = 90,
                builds = {
                    {
                        key = "raid",
                        name = "Raid (Best)",
                        content = "Raid",
                        note = "Wowhead marks Farseer Raid as the current recommendation and also lists a Stormbringer Raid alternative. Select the guide variant below; exact captured strings are revalidated by WoW before use.",
                    },
                    {
                        key = "mythicplus",
                        name = "Mythic+",
                        content = "Mythic+",
                        note = "Wowhead marks Farseer Mythic+ as the current recommendation and also lists a Stormbringer Mythic+ alternative. Select the guide variant below; exact captured strings are revalidated by WoW before use.",
                    },
                    {
                        key = "delves",
                        name = "Delves (Best)",
                        content = "Delves",
                        note = "Wowhead marks Farseer Delves as the current recommendation and also lists a Stormbringer Delves alternative. The recommended setup is utility-focused, taking additional crowd control while leaning on Voltaic Blaze and Purging Flames for low-target cleave.",
                        highlights = {
                            "Utility crowd control",
                            "Voltaic Blaze",
                            "Purging Flames",
                        },
                    },
                },
                limitation = TALENT_LIMITATION,
            },

            bis = {
                sourceName = "Wowhead - Elemental Shaman Gear and Best in Slot - Midnight",
                sourceUpdated = "2026-08-17",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/elemental/bis-gear",
                items = {
                    { slot = "Weapon",    id = 271092, name = "Jan'thrazet, the Soul Fang",              source = "Ula'tek" },
                    { slot = "Off Hand",  id = 268262, name = "Bubblefin Splash Guard",                 source = "Nymrissa Wavecaller" },
                    { slot = "Head",      id = 271483, name = "Serpent Crown of the Ophidian Oracle",   source = "Tier Set" },
                    { slot = "Neck",      id = 268265, name = "Aqirbane Reliquary",                      source = "Ula'tek" },
                    { slot = "Shoulders", id = 271481, name = "Hissing Mantle of the Ophidian Oracle", source = "Tier Set" },
                    { slot = "Cloak",     id = 268253, name = "Silken Voodoo Drape",                    source = "The Coiled Altar" },
                    { slot = "Chest",     id = 271486, name = "Fanged Raiment of the Ophidian Oracle", source = "Tier Set" },
                    { slot = "Wrist",     id = 244584, name = "Farstrider's Plated Bracers",            source = "Crafting" },
                    { slot = "Hands",     id = 271484, name = "Hexing Grips of the Ophidian Oracle",    source = "Tier Set" },
                    { slot = "Waist",     id = 268254, name = "Serpentine Mixing Belt",                 source = "Vashnik the Malignant" },
                    { slot = "Legs",      id = 271482, name = "Leggings of the Ophidian Oracle",        source = "Tier Set" },
                    { slot = "Feet",      id = 244577, name = "Farstrider's Razor Talons",              source = "Crafting" },
                    { slot = "Ring 1",    id = 268249, name = "Vile Alchemist's Band",                  source = "Vashnik the Malignant" },
                    { slot = "Ring 2",    id = 252258, name = "Sickening Signet of Atroxus",            source = "Voidscar Arena" },
                    { slot = "Trinket 1", id = 270164, name = "Gebbo's Bottomless Bag",                 source = "The Lost Explorers" },
                    { slot = "Trinket 2", id = 273796, name = "Vile Vial of Volatile Venom",            source = "Altar of Fangs" },
                },
                crafted = {
                    "Farstrider's Razor Talons with Arcanoweave Lining",
                    "Farstrider's Plated Bracers with Arcanoweave Lining",
                },
            },

            consumables = {
                sourceName = "Wowhead - Elemental Shaman Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-12",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/elemental/enchants-gems-pve-dps",
                items = {
                    { type = "Flask",         id = 241322, name = "Flask of the Magisters" },
                    { type = "Alt. Flask",    id = 241326, name = "Flask of the Shattered Sun" },
                    { type = "Combat Potion", id = 241308, name = "Light's Potential" },
                    { type = "Health Potion", id = 271884, name = "Concentrated Silvermoon Health Potion" },
                    { type = "Weapon Oil",    id = 243734, name = "Thalassian Phoenix Oil" },
                    { type = "Augment Rune",  id = 259085, name = "Void-Touched Augment Rune" },
                    { type = "Food",          id = 255846, name = "Harandar Celebration" },
                },
                note = "If Flametongue Weapon is talented, use Flametongue Weapon instead of a weapon oil.",
            },

            enchants = {
                sourceName = "Wowhead - Elemental Shaman Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-12",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/elemental/enchants-gems-pve-dps",
                items = {
                    { slot = "Weapon",    id = 243973, name = "Enchant Weapon - Berserker's Rage" },
                    { slot = "Weapon",    id = 243971, name = "Enchant Weapon - Jan'alai's Precision" },
                    { slot = "Head",      id = 244007, name = "Enchant Helm - Empowered Rune of Avoidance" },
                    { slot = "Shoulders", id = 243991, name = "Enchant Shoulders - Amirdrassil's Grace" },
                    { slot = "Chest",     id = 243977, name = "Enchant Chest - Mark of the Worldsoul" },
                    { slot = "Legs",      id = 240133, name = "Sunfire Silk Spellthread" },
                    { slot = "Boots",     id = 243953, name = "Enchant Boots - Lynx's Dexterity" },
                    { slot = "Ring",      id = 243957, name = "Enchant Ring - Eyes of the Eagle" },
                },
                gems = {
                    { type = "Thalassian Diamond", id = 240967, name = "Powerful Eversong Diamond" },
                    { type = "Garnet",             id = 240908, name = "Flawless Masterful Garnet" },
                    { type = "Peridot",            id = 240892, name = "Flawless Masterful Peridot" },
                    { type = "Amethyst",           id = 240898, name = "Flawless Deadly Amethyst" },
                    { type = "Lapis",              id = 240918, name = "Flawless Masterful Lapis" },
                },
                note = "The current guide recommends one of each listed gem family before filling remaining sockets with Mastery/Crit options as appropriate.",
            },

            sources = {
                { label = "Talent Builds", updated = "2026-08-21", url = "https://www.wowhead.com/guide/classes/shaman/elemental/talent-builds-pve-dps" },
                { label = "BiS Gear", updated = "2026-08-17", url = "https://www.wowhead.com/guide/classes/shaman/elemental/bis-gear" },
                { label = "Consumables / Enchants / Gems", updated = "2026-08-12", url = "https://www.wowhead.com/guide/classes/shaman/elemental/enchants-gems-pve-dps" },
                { label = "Stats", updated = "2026-08-12", url = "https://www.wowhead.com/guide/classes/shaman/elemental/stat-priority-pve-dps" },
                { label = "Rotation", updated = "2026-09-20", url = "https://www.wowhead.com/guide/classes/shaman/elemental/rotation-cooldowns-pve-dps" },
            },
        },

        [263] = {
            className = "Shaman",
            specName = "Enhancement",
            patch = "12.1.0",
            author = "wordup",
            statPriority = "Agility >> Mastery = Critical Strike > Haste >> Versatility",
            statNote = "This is a general Season 2 gearing direction. Enhancement stat values are close enough that individual gear, hero tree, and item level can move the answer; sim upgrades for final decisions.",
            statToolNote = "Wowhead recommends character-specific simulation for Enhancement; use Raidbots Top Gear when deciding between real items.",

            talents = {
                sourceName = "Wowhead - Best Enhancement Shaman Talent Tree Builds - Midnight",
                sourceUpdated = "2026-08-22",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/enhancement/talent-builds-pve-dps",
                previewLevel = 90,
                builds = {
                    {
                        key = "raid",
                        name = "Raid (Best)",
                        content = "Single Target / Raid",
                        heroTree = "Stormbringer",
                        note = "Wowhead's Season 2 raid recommendation leans strongly toward Stormbringer, using Ascendance for two-minute burst while retaining strong cleave through the standard build.",
                        highlights = { "Stormbringer", "Ascendance burst", "Voltaic Blaze", "Fire Nova" },
                    },
                    {
                        key = "mythicplus",
                        name = "Mythic+ (Best)",
                        content = "Mythic+ / AoE",
                        heroTree = "Stormbringer",
                        note = "Stormbringer is the current preferred Mythic+ direction, pairing strong mid-target-count throughput with Conductive Energy and a high-impact two-minute burst profile.",
                        highlights = { "Stormbringer", "Chaining Storms", "Ride the Lightning", "Conductive Energy" },
                    },
                    {
                        key = "delves",
                        name = "Delves (Best)",
                        content = "Delves",
                        heroTree = "Totemic",
                        note = "For Delves, Wowhead favors Totemic's more frequent burst cycle: Surging Totem has a short cooldown and Doom Winds damage is front-loaded enough to move cleanly from pull to pull.",
                        highlights = { "Totemic", "Surging Totem", "Doom Winds" },
                    },
                },
                limitation = TALENT_LIMITATION,
            },

            bis = {
                sourceName = "Wowhead - Enhancement Shaman Gear and Best in Slot - Midnight",
                sourceUpdated = "2026-08-24",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/enhancement/bis-gear",
                items = {
                    { slot = "Main Hand", id = 268209, name = "Aman'muso, Warlord's Vengeance",           source = "The Coiled Altar" },
                    { slot = "Off Hand",  id = 237850, name = "Farstrider's Chopper",                    source = "Blacksmithing" },
                    { slot = "Head",      id = 271483, name = "Serpent Crown of the Ophidian Oracle",   source = "Catalyst - Voidscar Arena" },
                    { slot = "Neck",      id = 268265, name = "Aqirbane Reliquary",                      source = "Ula'tek" },
                    { slot = "Shoulders", id = 271481, name = "Hissing Mantle of the Ophidian Oracle", source = "Catalyst - The Coiled Altar" },
                    { slot = "Cloak",     id = 268253, name = "Silken Voodoo Drape",                    source = "The Coiled Altar" },
                    { slot = "Chest",     id = 271486, name = "Fanged Raiment of the Ophidian Oracle", source = "Catalyst - Ula'tek" },
                    { slot = "Wrist",     id = 244584, name = "Farstrider's Plated Bracers",            source = "Leatherworking" },
                    { slot = "Hands",     id = 271484, name = "Hexing Grips of the Ophidian Oracle",    source = "Token - Entombed Sentinels" },
                    { slot = "Waist",     id = 268254, name = "Serpentine Mixing Belt",                 source = "Vashnik the Malignant" },
                    { slot = "Legs",      id = 271482, name = "Leggings of the Ophidian Oracle",        source = "Catalyst - The Coiled Altar" },
                    { slot = "Feet",      id = 268258, name = "Boots of the Reckless Wayfarer",         source = "The Lost Explorers" },
                    { slot = "Ring 1",    id = 273792, name = "Band of the Amani Warlord",              source = "Altar of Fangs" },
                    { slot = "Ring 2",    id = 268252, name = "Apex Brute's Claw Ring",                 source = "Sszorak" },
                    { slot = "Trinket 1", id = 270175, name = "Voracious Heart of Ula'tek",             source = "Ula'tek" },
                    { slot = "Trinket 2", id = 270173, name = "Zul'jin's Guillotine Technique",         source = "The Coiled Altar" },
                },
                crafted = {
                    "Farstrider's Chopper with Hunter's Ritual Stone",
                    "Farstrider's Plated Bracers with Arcanoweave Lining",
                },
            },

            consumables = {
                sourceName = "Wowhead - Enhancement Shaman Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-23",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/enhancement/enchants-gems-pve-dps",
                items = {
                    { type = "Flask",          id = 241322, name = "Flask of the Magisters" },
                    { type = "Alt. Flask",     id = 241326, name = "Flask of the Shattered Sun" },
                    { type = "ST Potion",      id = 271887, name = "Liquid Luster" },
                    { type = "AoE Potion",     id = 241288, name = "Potion of Recklessness" },
                    { type = "Health Potion",  id = 271884, name = "Concentrated Silvermoon Health Potion" },
                    { type = "Augment Rune",   id = 259085, name = "Void-Touched Augment Rune" },
                    { type = "Feast",          id = 255845, name = "Silvermoon Parade" },
                    { type = "Personal Food",  id = 242275, name = "Royal Roast" },
                },
                note = "Enhancement uses its own Flametongue/Windfury weapon imbues, so do not pair the build with temporary weapon oils or whetstones. Flask and potion value can move with your current secondary-stat balance; sim when optimizing.",
            },

            enchants = {
                sourceName = "Wowhead - Enhancement Shaman Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-23",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/enhancement/enchants-gems-pve-dps",
                items = {
                    { slot = "Main Hand", id = 273072, name = "Enchant Weapon - Rite of the Hash'ey" },
                    { slot = "Off Hand",  id = 273072, name = "Enchant Weapon - Rite of the Hash'ey" },
                    { slot = "Head",      id = 244007, name = "Enchant Helm - Empowered Rune of Avoidance" },
                    { slot = "Sockets",   id = 275707, name = "Miasmic Jewelbinder" },
                    { slot = "Shoulders", id = 243991, name = "Enchant Shoulders - Amirdrassil's Grace" },
                    { slot = "Chest",     id = 243977, name = "Enchant Chest - Mark of the Worldsoul" },
                    { slot = "Legs",      id = 244641, name = "Forest Hunter's Armor Kit" },
                    { slot = "Boots",     id = 243953, name = "Enchant Boots - Lynx's Dexterity" },
                    { slot = "Ring",      id = 243957, name = "Enchant Ring - Eyes of the Eagle" },
                },
                gems = {
                    { type = "Diamond",      id = 240967, name = "Powerful Eversong Diamond" },
                    { type = "Alt. Diamond", id = 240983, name = "Indecipherable Eversong Diamond" },
                    { type = "Amethyst",     id = 240900, name = "Flawless Quick Amethyst" },
                    { type = "Peridot",      id = 240892, name = "Flawless Masterful Peridot" },
                    { type = "Garnet",       id = 240908, name = "Flawless Masterful Garnet" },
                    { type = "Lapis",        id = 240918, name = "Flawless Masterful Lapis" },
                },
                note = "Rite of the Hash'ey is the current Season 2 weapon-enchant recommendation on both weapons. At low early-season stat levels, Acuity of the Ren'dorei can still be a temporary alternative. Gem mixes should be simmed as your stat balance changes.",
            },

            sources = {
                { label = "Talent Builds", updated = "2026-08-22", url = "https://www.wowhead.com/guide/classes/shaman/enhancement/talent-builds-pve-dps" },
                { label = "BiS Gear", updated = "2026-08-24", url = "https://www.wowhead.com/guide/classes/shaman/enhancement/bis-gear" },
                { label = "Consumables / Enchants / Gems", updated = "2026-08-23", url = "https://www.wowhead.com/guide/classes/shaman/enhancement/enchants-gems-pve-dps" },
                { label = "Stats", updated = "2026-08-22", url = "https://www.wowhead.com/guide/classes/shaman/enhancement/stat-priority-pve-dps" },
            },
        },

        [264] = {
            className = "Shaman",
            specName = "Restoration",
            patch = "12.1.0",
            author = "Harreks",
            statPriority = "Intellect > Critical Strike > Haste = Versatility > Mastery",
            statNote = "Intellect remains the primary goal. Critical Strike is the strongest general secondary; Haste and Versatility are close behind, while Mastery is the lowest generic priority. Healing gear is especially context-sensitive.",
            statToolNote = "For Restoration, use Questionably Epic Live or another healer-focused optimizer when evaluating your actual available gear rather than relying only on a generic stat order.",

            talents = {
                sourceName = "Wowhead - Best Restoration Shaman Talent Tree Builds - Midnight",
                sourceUpdated = "2026-09-05",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/restoration/talent-builds-pve-healer",
                previewLevel = 90,
                builds = {
                    {
                        key = "raid",
                        name = "Raid (Best)",
                        content = "Raid",
                        heroTree = "Totemic",
                        note = "Wowhead's current default raid build is centered on Totemic: spread Riptides, maintain Surging Totem, use Healing Stream Totem on cooldown, and fill with Chain Heal while keeping the build relatively low-complexity.",
                        highlights = { "Totemic", "Surging Totem", "Healing Stream Totem", "Chain Heal" },
                    },
                    {
                        key = "mythicplus",
                        name = "Mythic+ (Best)",
                        content = "Mythic+",
                        heroTree = "Totemic",
                        note = "The default Mythic+ direction emphasizes Totemic's constant passive healing and instant Chain Heals from Lively Totems. Farseer remains useful when you specifically want stronger spot healing and are comfortable with more hard-casting.",
                        highlights = { "Totemic", "Lively Totems", "Acid Rain", "Flexible cooldowns" },
                    },
                    {
                        key = "delves",
                        name = "Delves (Best)",
                        content = "Delves",
                        note = "Wowhead publishes dedicated Farseer and Totemic Delve variants. Select the guide build below; exact captured variants are revalidated by WoW before use, while any unresolved source row remains visibly Pending.",
                    },
                },
                limitation = TALENT_LIMITATION,
            },

            bis = {
                sourceName = "Wowhead - Restoration Shaman Gear and Best in Slot - Midnight",
                sourceUpdated = "2026-08-26",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/restoration/bis-gear",
                items = {
                    { slot = "Head",      id = 271483, name = "Serpent Crown of the Ophidian Oracle",   source = "Raid / Vault" },
                    { slot = "Neck",      id = 268265, name = "Aqirbane Reliquary",                      source = "Ula'tek" },
                    { slot = "Shoulders", id = 271481, name = "Hissing Mantle of the Ophidian Oracle", source = "The Coiled Altar / Catalyst" },
                    { slot = "Cloak",     id = 268248, name = "Amani Summoning Shawl",                   source = "Nek'zali the Soulcoiler" },
                    { slot = "Chest",     id = 271486, name = "Fanged Raiment of the Ophidian Oracle", source = "King's Rest / Catalyst" },
                    { slot = "Wrist",     id = 159380, name = "Arc-Glass Bindings",                      source = "Temple of Sethraliss" },
                    { slot = "Hands",     id = 271484, name = "Hexing Grips of the Ophidian Oracle",    source = "The Blinding Vale / Catalyst" },
                    { slot = "Waist",     id = 268216, name = "Cursed Reliquary Cincture",              source = "Nek'zali the Soulcoiler" },
                    { slot = "Legs",      id = 271482, name = "Leggings of the Ophidian Oracle",        source = "Temple of Sethraliss / Catalyst" },
                    { slot = "Feet",      id = 251125, name = "Felsoaked Soles",                         source = "Murder Row" },
                    { slot = "Ring 1",    id = 268252, name = "Apex Brute's Claw Ring",                 source = "Sszorak" },
                    { slot = "Ring 2",    id = 251148, name = "Pilfered Precious Band",                  source = "Den of Nalorakk" },
                    { slot = "Trinket 1", id = 270162, name = "Soulcoiler Ritual Vessel",               source = "Nek'zali the Soulcoiler" },
                    { slot = "Trinket 2", id = 270167, name = "Wavecaller's Seastone",                  source = "Nymrissa Wavebinder" },
                    { slot = "Weapon",    id = 271092, name = "Jan'thrazet, the Soul Fang",             source = "Ula'tek" },
                    { slot = "Shield",    id = 268196, name = "Venom-Slashed Scuteward",                source = "The Lost Explorers" },
                },
                crafted = {
                    "Farstrider's Plated Bracers with Arcanoweave Lining",
                    "Farstrider's Razor Talons with Arcanoweave Lining",
                },
            },

            consumables = {
                sourceName = "Wowhead - Restoration Shaman Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-12",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/restoration/enchants-gems-pve-healer",
                items = {
                    { type = "Flask",          id = 241326, name = "Flask of the Shattered Sun" },
                    { type = "Mana Potion",    id = 241300, name = "Lightfused Mana Potion" },
                    { type = "Output Potion",  id = 241288, name = "Potion of Recklessness" },
                    { type = "Health Potion",  id = 271884, name = "Concentrated Silvermoon Health Potion" },
                    { type = "Augment Rune",   id = 259085, name = "Void-Touched Augment Rune" },
                    { type = "Feast",          id = 255845, name = "Silvermoon Parade" },
                    { type = "Personal Food",  id = 242275, name = "Royal Roast" },
                    { type = "Alt. Food",      id = 242299, name = "Sanguithorn Tea" },
                },
                note = "Keep Earthliving Weapon active as your class weapon buff; it cannot be combined with temporary weapon oils. Potion of Recklessness is especially strong when Critical Strike is your highest secondary, while Lightfused Mana Potion remains the direct mana option.",
            },

            enchants = {
                sourceName = "Wowhead - Restoration Shaman Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-12",
                sourceURL = "https://www.wowhead.com/guide/classes/shaman/restoration/enchants-gems-pve-healer",
                items = {
                    { slot = "Weapon",    id = 244029, name = "Enchant Weapon - Acuity of the Ren'dorei" },
                    { slot = "Head",      id = 243951, name = "Enchant Helm - Empowered Hex of Leeching" },
                    { slot = "Shoulders", id = 244021, name = "Enchant Shoulders - Silvermoon's Mending" },
                    { slot = "Chest",     id = 244003, name = "Enchant Chest - Mark of the Magister" },
                    { slot = "Legs",      id = 240155, name = "Arcanoweave Spellthread" },
                    { slot = "Boots",     id = 243983, name = "Enchant Boots - Shaladrassil's Roots" },
                    { slot = "Ring",      id = 243957, name = "Enchant Ring - Eyes of the Eagle" },
                },
                gems = {
                    { type = "Diamond",      id = 240983, name = "Indecipherable Eversong Diamond" },
                    { type = "Mana Diamond", id = 240968, name = "Telluric Eversong Diamond" },
                    { type = "Garnet",       id = 240909, name = "Flawless Versatile Garnet" },
                    { type = "Peridot",      id = 240889, name = "Flawless Deadly Peridot" },
                    { type = "Lapis",        id = 240913, name = "Flawless Deadly Lapis" },
                    { type = "Amethyst",     id = 240897, name = "Flawless Deadly Amethyst" },
                },
                note = "Telluric Eversong Diamond gains value when mana matters; Indecipherable Eversong Diamond is the throughput alternative when mana is comfortable. The remaining gem mix depends on which diamond you use and your current stat balance.",
            },

            sources = {
                { label = "Talent Builds", updated = "2026-09-05", url = "https://www.wowhead.com/guide/classes/shaman/restoration/talent-builds-pve-healer" },
                { label = "BiS Gear", updated = "2026-08-26", url = "https://www.wowhead.com/guide/classes/shaman/restoration/bis-gear" },
                { label = "Consumables / Enchants / Gems", updated = "2026-08-12", url = "https://www.wowhead.com/guide/classes/shaman/restoration/enchants-gems-pve-healer" },
                { label = "Stats", updated = "2026-08-12", url = "https://www.wowhead.com/guide/classes/shaman/restoration/stat-priority-pve-healer" },
            },
        },
    },


    DEMONHUNTER = {
        [577] = {
            className = "Demon Hunter",
            specName = "Havoc",
            patch = "12.1.0",
            author = "Shadarek",
            statPriority = "Agility >> Critical Strike > Mastery > Haste >> Versatility",
            statNote = "Critical Strike is the strongest general secondary in the current Season 2 guide, followed by Mastery and Haste. Item level and your exact hero/build setup can still change individual upgrades.",
            statToolNote = "For Havoc gearing decisions, sim your actual character with Raidbots rather than treating a generic stat order as absolute.",

            talents = {
                sourceName = "Wowhead - Best Havoc Demon Hunter Talent Tree Builds - Midnight",
                sourceUpdated = "2026-09-24",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/talent-builds-pve-dps",
                previewLevel = 90,
                builds = {
                    {
                        key = "raid",
                        name = "Raid (Best)",
                        content = "Raid",
                        note = "Wowhead's current raid recommendations revolve around Essence Break and Exergy, with encounter-specific swaps between pure single-target and mixed cleave. Select the guide variant below; exact captured strings are revalidated by WoW before use.",
                        highlights = { "Essence Break", "Exergy", "Encounter-specific cleave" },
                    },
                    {
                        key = "mythicplus",
                        name = "Mythic+ (Best)",
                        content = "Mythic+",
                        heroTree = "Fel-Scarred",
                        note = "The current Mythic+ direction emphasizes Fel-Scarred, Eye Beam/Exergy windows, and strong Immolation Aura-based AoE. Select the guide variant below; exact captured strings are revalidated by WoW before use.",
                        highlights = { "Fel-Scarred", "Eye Beam", "Immolation Aura", "Priority damage" },
                    },
                    {
                        key = "delves",
                        name = "Delves (Best)",
                        content = "Delves",
                        heroTree = "Fel-Scarred",
                        note = "Wowhead's Delve recommendation follows the regular Fel-Scarred Mythic+ direction, giving a practical mix of burst AoE, mobility, and self-sustain for variable pull sizes.",
                    },
                },
                limitation = TALENT_LIMITATION,
            },

            bis = {
                sourceName = "Wowhead - Havoc Demon Hunter Gear and Best in Slot - Midnight",
                sourceUpdated = "2026-08-28",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/bis-gear",
                items = {
                    { slot = "Weapon",    id = 268209, name = "Aman'muso, Warlord's Vengeance",              source = "The Coiled Altar" },
                    { slot = "Off Hand",  id = 237840, name = "Spellbreaker's Warglaive",                    source = "Crafting" },
                    { slot = "Head",      id = 271875, name = "Gaze of the Coiled Watcher",                  source = "Ula'tek" },
                    { slot = "Neck",      id = 268265, name = "Aqirbane Reliquary",                          source = "Ula'tek" },
                    { slot = "Shoulders", id = 271535, name = "Abyssal Doomhound's Jaws",                   source = "Catalyst / Vashnik the Malignant" },
                    { slot = "Cloak",     id = 268253, name = "Silken Voodoo Drape",                        source = "The Coiled Altar" },
                    { slot = "Chest",     id = 271540, name = "Abyssal Doomhound's Coreguard",              source = "Catalyst / King's Rest" },
                    { slot = "Wrist",     id = 244576, name = "Silvermoon Agent's Deflectors",              source = "Crafting" },
                    { slot = "Hands",     id = 271538, name = "Abyssal Doomhound's Studded Gauntlets",      source = "Entombed Sentinels / Catalyst" },
                    { slot = "Waist",     id = 268256, name = "Sash of the Forlorn Vessel",                  source = "The Coiled Altar" },
                    { slot = "Legs",      id = 271536, name = "Abyssal Doomhound's Legwraps",               source = "Catalyst / The Coiled Altar" },
                    { slot = "Feet",      id = 159327, name = "Sand-Shined Snakeskin Sandals",              source = "Temple of Sethraliss" },
                    { slot = "Ring 1",    id = 251136, name = "Signet of Snarling Servitude",               source = "Murder Row" },
                    { slot = "Ring 2",    id = 158366, name = "Charged Sandstone Band",                     source = "Temple of Sethraliss" },
                    { slot = "Trinket 1", id = 270173, name = "Zul'jin's Guillotine Technique",             source = "The Coiled Altar" },
                    { slot = "Trinket 2", id = 270168, name = "Font of Venomous Rage",                      source = "Ula'tek" },
                },
                crafted = {
                    "Spellbreaker's Warglaive with Hunter's Ritual Stone",
                    "Silvermoon Agent's Deflectors with Arcanoweave Lining",
                },
            },

            consumables = {
                sourceName = "Wowhead - Havoc Demon Hunter Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-29",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/enchants-gems-pve-dps",
                items = {
                    { type = "Flask",         id = 241326, name = "Flask of the Shattered Sun" },
                    { type = "Combat Potion", id = 241288, name = "Potion of Recklessness" },
                    { type = "Health Potion", id = 271884, name = "Concentrated Silvermoon Health Potion" },
                    { type = "Weapon Buff",   id = 243734, name = "Thalassian Phoenix Oil" },
                    { type = "Augment Rune",  id = 259085, name = "Void-Touched Augment Rune" },
                    { type = "Personal Food", id = 242275, name = "Royal Roast" },
                    { type = "Feast",         id = 255846, name = "Harandar Celebration" },
                },
                note = "The guide favors Critical Strike-heavy consumable choices for Havoc. Sim your character if your current secondary-stat balance is close.",
            },

            enchants = {
                sourceName = "Wowhead - Havoc Demon Hunter Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-29",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/enchants-gems-pve-dps",
                items = {
                    { slot = "Weapon",    id = 273072, name = "Enchant Weapon - Rite of the Hash'ey" },
                    { slot = "Helm",      id = 244007, name = "Enchant Helm - Empowered Rune of Avoidance" },
                    { slot = "Shoulders", id = 243991, name = "Enchant Shoulders - Amirdrassil's Grace" },
                    { slot = "Chest",     id = 243977, name = "Enchant Chest - Mark of the Worldsoul" },
                    { slot = "Legs",      id = 244641, name = "Forest Hunter's Armor Kit" },
                    { slot = "Boots",     id = 243953, name = "Enchant Boots - Lynx's Dexterity" },
                    { slot = "Ring",      id = 243957, name = "Enchant Ring - Eyes of the Eagle" },
                },
                gems = {
                    { type = "Diamond", id = 240983, name = "Indecipherable Eversong Diamond" },
                    { type = "Garnet",  id = 240908, name = "Flawless Masterful Garnet" },
                },
                note = "Use Indecipherable Eversong Diamond as the primary diamond and favor Crit/Mastery gem combinations that fit your current simmed stat balance.",
            },

            sources = {
                { label = "Talent Builds", updated = "2026-09-24", url = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/talent-builds-pve-dps" },
                { label = "BiS Gear", updated = "2026-08-28", url = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/bis-gear" },
                { label = "Consumables / Enchants / Gems", updated = "2026-08-29", url = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/enchants-gems-pve-dps" },
                { label = "Stats", updated = "2026-08-12", url = "https://www.wowhead.com/guide/classes/demon-hunter/havoc/stat-priority-pve-dps" },
            },
        },

        [581] = {
            className = "Demon Hunter",
            specName = "Vengeance",
            patch = "12.1.0",
            author = "Itamae",
            statPriority = "Agility / Item Level >>> Haste >= Versatility = Critical Strike = Mastery",
            statNote = "The current guide strongly prioritizes item level and total Agility first. Haste is the preferred secondary for smoothness, while Versatility, Critical Strike, and Mastery are close enough that higher-item-level gear usually wins.",
            statToolNote = "For Vengeance, use Raidbots for damage-oriented gearing and evaluate defensive value in the context of the content you are actually tanking.",

            talents = {
                sourceName = "Wowhead - Best Vengeance Demon Hunter Talent Tree Builds - Midnight",
                sourceUpdated = "2026-08-12",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/talent-builds-pve-tank",
                previewLevel = 90,
                builds = {
                    {
                        key = "raid",
                        name = "Raid Cleave (Best)",
                        content = "Raid Cleave",
                        note = "Wowhead maintains multiple Raid variants, including Single Target, Raid Cleave, and Raid Council options across the supported Hero trees. Select the desired guide variant below; any source row that cannot be validated is kept Pending rather than guessed.",
                        highlights = { "Raid Cleave", "Sigil utility", "Boss-specific swaps" },
                    },
                    {
                        key = "mythicplus",
                        name = "Mythic+",
                        content = "Mythic+",
                        note = "The Mythic+ section emphasizes a durable, high-uptime dungeon setup with flexible Sigil utility. Select the desired guide variant below; exact captured strings are revalidated by WoW, while any unresolved source row remains fail-closed.",
                    },
                    {
                        key = "delves",
                        name = "Delves (Best)",
                        content = "Delves",
                        note = "Wowhead publishes a dedicated recommended Delve build for Vengeance. It retains the tank spec's self-sustain and crowd-control strengths while adapting utility for solo/small-group pulls.",
                    },
                },
                limitation = TALENT_LIMITATION,
            },

            bis = {
                sourceName = "Wowhead - Vengeance Demon Hunter Gear and Best in Slot - Midnight",
                sourceUpdated = "2026-09-05",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/bis-gear",
                items = {
                    { slot = "Weapon",    id = 268209, name = "Aman'muso, Warlord's Vengeance",              source = "The Coiled Altar" },
                    { slot = "Off Hand",  id = 237840, name = "Spellbreaker's Warglaive",                    source = "Crafting" },
                    { slot = "Head",      id = 271537, name = "Abyssal Doomhound's Relentless Stare",       source = "Ula'tek / Catalyst" },
                    { slot = "Neck",      id = 268265, name = "Aqirbane Reliquary",                          source = "Ula'tek" },
                    { slot = "Shoulders", id = 271535, name = "Abyssal Doomhound's Jaws",                   source = "Voidscar Arena / Catalyst" },
                    { slot = "Cloak",     id = 268253, name = "Silken Voodoo Drape",                        source = "The Coiled Altar" },
                    { slot = "Chest",     id = 271540, name = "Abyssal Doomhound's Coreguard",              source = "Vashnik the Malignant / Catalyst" },
                    { slot = "Wrist",     id = 244576, name = "Silvermoon Agent's Deflectors",              source = "Crafting" },
                    { slot = "Hands",     id = 271538, name = "Abyssal Doomhound's Studded Gauntlets",      source = "Murder Row / Catalyst" },
                    { slot = "Waist",     id = 268256, name = "Sash of the Forlorn Vessel",                  source = "The Coiled Altar" },
                    { slot = "Legs",      id = 271536, name = "Abyssal Doomhound's Legwraps",               source = "The Coiled Altar / Catalyst" },
                    { slot = "Feet",      id = 251153, name = "Arctic Explorer's Legwraps",                 source = "Den of Nalorakk" },
                    { slot = "Ring 1",    id = 268252, name = "Apex Brute's Claw Ring",                     source = "Sszorak" },
                    { slot = "Ring 2",    id = 159459, name = "Ritual Binder's Ring",                        source = "King's Rest" },
                    { slot = "Trinket 1", id = 270164, name = "Gebbo's Bottomless Bag",                     source = "The Lost Explorers" },
                    { slot = "Trinket 2", id = 270175, name = "Voracious Heart of Ula'tek",                 source = "Ula'tek" },
                },
                crafted = {
                    "Spellbreaker's Warglaive with Hunter's Ritual Stone or Darkmoon Sigil: Hunt",
                    "Silvermoon Agent's Deflectors with Arcanoweave Lining",
                },
            },

            consumables = {
                sourceName = "Wowhead - Vengeance Demon Hunter Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-23",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/enchants-gems-pve-tank",
                items = {
                    { type = "Flask",         id = 241325, name = "Flask of the Blood Knights" },
                    { type = "Combat Potion", id = 241308, name = "Light's Potential" },
                    { type = "Health Potion", id = 271884, name = "Concentrated Silvermoon Health Potion" },
                    { type = "Weapon Buff",   id = 243734, name = "Thalassian Phoenix Oil" },
                    { type = "Augment Rune",  id = 259085, name = "Void-Touched Augment Rune" },
                    { type = "Agility Feast", id = 255846, name = "Harandar Celebration" },
                    { type = "Secondary Feast", id = 242273, name = "Blooming Feast" },
                },
                note = "Haste is the safest general flask direction. Thalassian Phoenix Oil is the balanced weapon buff; damage-only alternatives can vary by target count.",
            },

            enchants = {
                sourceName = "Wowhead - Vengeance Demon Hunter Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-23",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/enchants-gems-pve-tank",
                items = {
                    { slot = "Weapon (Defense)", id = 244029, name = "Enchant Weapon - Acuity of the Ren'dorei" },
                    { slot = "Weapon (Offense)", id = 273072, name = "Enchant Weapon - Rite of the Hash'ey" },
                    { slot = "Helm",      id = 243981, name = "Enchant Helm - Empowered Blessing of Speed" },
                    { slot = "Shoulders", id = 243963, name = "Enchant Shoulders - Akil'zon's Swiftness" },
                    { slot = "Chest",     id = 243977, name = "Enchant Chest - Mark of the Worldsoul" },
                    { slot = "Legs",      id = 244641, name = "Forest Hunter's Armor Kit" },
                    { slot = "Boots",     id = 244009, name = "Enchant Boots - Farstrider's Hunt" },
                    { slot = "Ring",      id = 243957, name = "Enchant Ring - Eyes of the Eagle" },
                },
                gems = {
                    { type = "Diamond", id = 240983, name = "Indecipherable Eversong Diamond" },
                    { type = "Peridot", id = 240890, name = "Flawless Deadly Peridot" },
                    { type = "Peridot", id = 240894, name = "Flawless Versatile Peridot" },
                    { type = "Lapis",   id = 240916, name = "Flawless Quick Lapis" },
                    { type = "Garnet",  id = 240906, name = "Flawless Quick Garnet" },
                    { type = "Amethyst", id = 240900, name = "Flawless Quick Amethyst" },
                },
                note = "The guide favors an Indecipherable Eversong Diamond for consistent main-stat value, then a mixed gem set before filling remaining sockets with Haste-focused combinations.",
            },

            sources = {
                { label = "Talent Builds", updated = "2026-08-12", url = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/talent-builds-pve-tank" },
                { label = "BiS Gear", updated = "2026-09-05", url = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/bis-gear" },
                { label = "Consumables / Enchants / Gems", updated = "2026-08-23", url = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/enchants-gems-pve-tank" },
                { label = "Stats", updated = "2026-08-25", url = "https://www.wowhead.com/guide/classes/demon-hunter/vengeance/stat-priority-pve-tank" },
            },
        },

        [1480] = {
            className = "Demon Hunter",
            specName = "Devourer",
            patch = "12.1.0",
            author = "VooDooSaurus",
            statPriority = "Intellect > Haste to ~18% > Mastery >= Critical Strike > Versatility >>> excess Haste",
            statNote = "The current Season 2 guide targets roughly 18% Haste for the common breakpoint setup, then favors Mastery and Critical Strike. Some build variants want more Haste, so treat the breakpoint as build-dependent rather than universal.",
            statToolNote = "Devourer has meaningful Haste-breakpoint behavior. Sim your exact gear and target build with Raidbots before replacing a large item-level upgrade for secondary-stat optimization.",

            talents = {
                sourceName = "Wowhead - Best Devourer Demon Hunter Talent Tree Builds - Midnight",
                sourceUpdated = "2026-09-18",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/talent-builds-pve-dps",
                previewLevel = 90,
                builds = {
                    {
                        key = "raid",
                        name = "Raid (Best)",
                        content = "Raid",
                        heroTree = "Void-Scarred",
                        note = "The current 12.1 raid direction favors rapid Void Metamorphosis cycling and strong cleave through Eradicate while preserving single-target value. Annihilator remains available but is not the guide's preferred Season 2 direction.",
                        highlights = { "Void-Scarred", "Void Metamorphosis", "Eradicate", "Reap" },
                    },
                    {
                        key = "mythicplus",
                        name = "Mythic+ (Best)",
                        content = "Mythic+",
                        heroTree = "Void-Scarred",
                        note = "Wowhead recommends Void-Scarred for the current Mythic+ season, using frequent Void Metamorphosis windows for burst cleave plus strong single-target and priority damage.",
                        highlights = { "Void-Scarred", "Soul Glutton", "Voidsurge", "Hungering Slash" },
                    },
                    {
                        key = "delves",
                        name = "Delves (Best)",
                        content = "Delves",
                        heroTree = "Void-Scarred",
                        note = "The Delve build closely follows the Void-Scarred Mythic+ setup with a class tree tailored for variable pull sizes and solo utility.",
                    },
                },
                limitation = TALENT_LIMITATION,
            },

            bis = {
                sourceName = "Wowhead - Devourer Demon Hunter Gear and Best in Slot - Midnight",
                sourceUpdated = "2026-08-17",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/bis-gear",
                items = {
                    { slot = "Weapon",    id = 271092, name = "Jan'thrazet, the Soul Fang",                  source = "Ula'tek" },
                    { slot = "Off Hand",  id = 268211, name = "Baleful Hexblade",                            source = "The Coiled Altar" },
                    { slot = "Head",      id = 271537, name = "Abyssal Doomhound's Relentless Stare",       source = "Ula'tek / Catalyst" },
                    { slot = "Neck",      id = 268265, name = "Aqirbane Reliquary",                          source = "Ula'tek" },
                    { slot = "Shoulders", id = 271535, name = "Abyssal Doomhound's Jaws",                   source = "Voidscar Arena / Catalyst" },
                    { slot = "Cloak",     id = 268253, name = "Silken Voodoo Drape",                        source = "The Coiled Altar" },
                    { slot = "Chest",     id = 271540, name = "Abyssal Doomhound's Coreguard",              source = "Den of Nalorakk / Catalyst" },
                    { slot = "Wrist",     id = 244576, name = "Silvermoon Agent's Deflectors",              source = "Crafting" },
                    { slot = "Hands",     id = 271538, name = "Abyssal Doomhound's Studded Gauntlets",      source = "Tier Set" },
                    { slot = "Waist",     id = 268256, name = "Sash of the Forlorn Vessel",                  source = "The Coiled Altar" },
                    { slot = "Legs",      id = 271536, name = "Abyssal Doomhound's Legwraps",               source = "The Coiled Altar / Catalyst" },
                    { slot = "Feet",      id = 244569, name = "Silvermoon Agent's Sneakers",                source = "Crafting" },
                    { slot = "Ring 1",    id = 268249, name = "Vile Alchemist's Band",                      source = "Vashnik the Malignant" },
                    { slot = "Ring 2",    id = 158366, name = "Charged Sandstone Band",                     source = "Temple of Sethraliss" },
                    { slot = "Trinket 1", id = 250215, name = "Freightrunner's Flask",                      source = "Murder Row" },
                    { slot = "Trinket 2", id = 270167, name = "Wavecaller's Seastone",                      source = "Nymrissa Wavecaller" },
                    { slot = "M+ Trinket", id = 270164, name = "Gebbo's Bottomless Bag",                    source = "The Lost Explorers" },
                },
                crafted = {
                    "Spellbreaker's Warglaive with Hunter's Ritual Stone is a strong early-season weapon craft",
                    "Silvermoon Agent's Deflectors or Sneakers with Arcanoweave Lining",
                },
            },

            consumables = {
                sourceName = "Wowhead - Devourer Demon Hunter Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-24",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/enchants-gems-pve-dps",
                items = {
                    { type = "Flask",         id = 241322, name = "Flask of the Magisters" },
                    { type = "Alt. Flask",    id = 241326, name = "Flask of the Shattered Sun" },
                    { type = "Combat Potion", id = 241288, name = "Potion of Recklessness" },
                    { type = "Health Potion", id = 271884, name = "Concentrated Silvermoon Health Potion" },
                    { type = "Weapon Buff",   id = 243734, name = "Thalassian Phoenix Oil" },
                    { type = "Augment Rune",  id = 259085, name = "Void-Touched Augment Rune" },
                    { type = "Feast",         id = 275266, name = "Feast of Knowledge" },
                    { type = "Personal Food", id = 242274, name = "Champion's Bento" },
                },
                note = "Devourer wants secondary-stat food in Season 2. Potion of Recklessness should not be allowed to proc Haste once your build has reached its desired Haste target.",
            },

            enchants = {
                sourceName = "Wowhead - Devourer Demon Hunter Enchants & Consumables - Midnight",
                sourceUpdated = "2026-08-24",
                sourceURL = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/enchants-gems-pve-dps",
                items = {
                    { slot = "Main Hand", id = 273072, name = "Enchant Weapon - Rite of the Hash'ey" },
                    { slot = "Off Hand",  id = 273072, name = "Enchant Weapon - Rite of the Hash'ey" },
                    { slot = "Helm",      id = 244007, name = "Enchant Helm - Empowered Rune of Avoidance" },
                    { slot = "Shoulders", id = 243991, name = "Enchant Shoulders - Amirdrassil's Grace" },
                    { slot = "Chest",     id = 243977, name = "Enchant Chest - Mark of the Worldsoul" },
                    { slot = "Legs",      id = 240133, name = "Sunfire Silk Spellthread" },
                    { slot = "Boots",     id = 243953, name = "Enchant Boots - Lynx's Dexterity" },
                    { slot = "Ring",      id = 243957, name = "Enchant Ring - Eyes of the Eagle" },
                },
                gems = {
                    { type = "Diamond",  id = 240983, name = "Indecipherable Eversong Diamond" },
                    { type = "Amethyst", id = 240898, name = "Flawless Deadly Amethyst" },
                    { type = "Amethyst", id = 240900, name = "Flawless Quick Amethyst" },
                },
                note = "Indecipherable Eversong Diamond is the current primary diamond recommendation. The remaining sockets favor Mastery/Crit or Mastery/Haste combinations depending on your exact build and Haste target.",
            },

            sources = {
                { label = "Talent Builds", updated = "2026-09-18", url = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/talent-builds-pve-dps" },
                { label = "BiS Gear", updated = "2026-08-17", url = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/bis-gear" },
                { label = "Consumables / Enchants / Gems", updated = "2026-08-24", url = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/enchants-gems-pve-dps" },
                { label = "Stats", updated = "2026-08-12", url = "https://www.wowhead.com/guide/classes/demon-hunter/devourer/stat-priority-pve-dps" },
            },
        },
    },
}


-- Progressive expansion packs -----------------------------------------------
-- Every Retail specialization is available in the Guide Browser. Shaman and
-- Demon Hunter retain their full reference packs; the remaining specializations
-- begin with talents and can gain BiS/consumables/enchants/stats independently as
-- reviewed generated data packs are merged. Tab availability is data-driven.
AGB.TalentOnlySpecs = {
    [250] = {
        classFile = "DEATHKNIGHT", className = "Death Knight", specName = "Blood",
        sourceURL = "https://www.wowhead.com/guide/classes/death-knight/blood/talent-builds-pve-tank",
    },
    [251] = {
        classFile = "DEATHKNIGHT", className = "Death Knight", specName = "Frost",
        sourceURL = "https://www.wowhead.com/guide/classes/death-knight/frost/talent-builds-pve-dps",
    },
    [252] = {
        classFile = "DEATHKNIGHT", className = "Death Knight", specName = "Unholy",
        sourceURL = "https://www.wowhead.com/guide/classes/death-knight/unholy/talent-builds-pve-dps",
    },
    [102] = {
        classFile = "DRUID", className = "Druid", specName = "Balance",
        sourceURL = "https://www.wowhead.com/guide/classes/druid/balance/talent-builds-pve-dps",
    },
    [103] = {
        classFile = "DRUID", className = "Druid", specName = "Feral",
        sourceURL = "https://www.wowhead.com/guide/classes/druid/feral/talent-builds-pve-dps",
    },
    [104] = {
        classFile = "DRUID", className = "Druid", specName = "Guardian",
        sourceURL = "https://www.wowhead.com/guide/classes/druid/guardian/talent-builds-pve-tank",
    },
    [105] = {
        classFile = "DRUID", className = "Druid", specName = "Restoration",
        sourceURL = "https://www.wowhead.com/guide/classes/druid/restoration/talent-builds-pve-healer",
    },
    [1467] = {
        classFile = "EVOKER", className = "Evoker", specName = "Devastation",
        sourceURL = "https://www.wowhead.com/guide/classes/evoker/devastation/talent-builds-pve-dps",
    },
    [1468] = {
        classFile = "EVOKER", className = "Evoker", specName = "Preservation",
        sourceURL = "https://www.wowhead.com/guide/classes/evoker/preservation/talent-builds-pve-healer",
    },
    [1473] = {
        classFile = "EVOKER", className = "Evoker", specName = "Augmentation",
        sourceURL = "https://www.wowhead.com/guide/classes/evoker/augmentation/talent-builds-pve-dps",
    },
    [253] = {
        classFile = "HUNTER", className = "Hunter", specName = "Beast Mastery",
        sourceURL = "https://www.wowhead.com/guide/classes/hunter/beast-mastery/talent-builds-pve-dps",
    },
    [254] = {
        classFile = "HUNTER", className = "Hunter", specName = "Marksmanship",
        sourceURL = "https://www.wowhead.com/guide/classes/hunter/marksmanship/talent-builds-pve-dps",
    },
    [255] = {
        classFile = "HUNTER", className = "Hunter", specName = "Survival",
        sourceURL = "https://www.wowhead.com/guide/classes/hunter/survival/talent-builds-pve-dps",
    },
    [62] = {
        classFile = "MAGE", className = "Mage", specName = "Arcane",
        sourceURL = "https://www.wowhead.com/guide/classes/mage/arcane/talent-builds-pve-dps",
    },
    [63] = {
        classFile = "MAGE", className = "Mage", specName = "Fire",
        sourceURL = "https://www.wowhead.com/guide/classes/mage/fire/talent-builds-pve-dps",
    },
    [64] = {
        classFile = "MAGE", className = "Mage", specName = "Frost",
        sourceURL = "https://www.wowhead.com/guide/classes/mage/frost/talent-builds-pve-dps",
    },
    [268] = {
        classFile = "MONK", className = "Monk", specName = "Brewmaster",
        sourceURL = "https://www.wowhead.com/guide/classes/monk/brewmaster/talent-builds-pve-tank",
    },
    [270] = {
        classFile = "MONK", className = "Monk", specName = "Mistweaver",
        sourceURL = "https://www.wowhead.com/guide/classes/monk/mistweaver/talent-builds-pve-healer",
    },
    [269] = {
        classFile = "MONK", className = "Monk", specName = "Windwalker",
        sourceURL = "https://www.wowhead.com/guide/classes/monk/windwalker/talent-builds-pve-dps",
    },
    [65] = {
        classFile = "PALADIN", className = "Paladin", specName = "Holy",
        sourceURL = "https://www.wowhead.com/guide/classes/paladin/holy/talent-builds-pve-healer",
    },
    [66] = {
        classFile = "PALADIN", className = "Paladin", specName = "Protection",
        sourceURL = "https://www.wowhead.com/guide/classes/paladin/protection/talent-builds-pve-tank",
    },
    [70] = {
        classFile = "PALADIN", className = "Paladin", specName = "Retribution",
        sourceURL = "https://www.wowhead.com/guide/classes/paladin/retribution/talent-builds-pve-dps",
    },
    [256] = {
        classFile = "PRIEST", className = "Priest", specName = "Discipline",
        sourceURL = "https://www.wowhead.com/guide/classes/priest/discipline/talent-builds-pve-healer",
    },
    [257] = {
        classFile = "PRIEST", className = "Priest", specName = "Holy",
        sourceURL = "https://www.wowhead.com/guide/classes/priest/holy/talent-builds-pve-healer",
    },
    [258] = {
        classFile = "PRIEST", className = "Priest", specName = "Shadow",
        sourceURL = "https://www.wowhead.com/guide/classes/priest/shadow/talent-builds-pve-dps",
    },
    [259] = {
        classFile = "ROGUE", className = "Rogue", specName = "Assassination",
        sourceURL = "https://www.wowhead.com/guide/classes/rogue/assassination/talent-builds-pve-dps",
    },
    [260] = {
        classFile = "ROGUE", className = "Rogue", specName = "Outlaw",
        sourceURL = "https://www.wowhead.com/guide/classes/rogue/outlaw/talent-builds-pve-dps",
    },
    [261] = {
        classFile = "ROGUE", className = "Rogue", specName = "Subtlety",
        sourceURL = "https://www.wowhead.com/guide/classes/rogue/subtlety/talent-builds-pve-dps",
    },
    [265] = {
        classFile = "WARLOCK", className = "Warlock", specName = "Affliction",
        sourceURL = "https://www.wowhead.com/guide/classes/warlock/affliction/talent-builds-pve-dps",
    },
    [266] = {
        classFile = "WARLOCK", className = "Warlock", specName = "Demonology",
        sourceURL = "https://www.wowhead.com/guide/classes/warlock/demonology/talent-builds-pve-dps",
    },
    [267] = {
        classFile = "WARLOCK", className = "Warlock", specName = "Destruction",
        sourceURL = "https://www.wowhead.com/guide/classes/warlock/destruction/talent-builds-pve-dps",
    },
    [71] = {
        classFile = "WARRIOR", className = "Warrior", specName = "Arms",
        sourceURL = "https://www.wowhead.com/guide/classes/warrior/arms/talent-builds-pve-dps",
    },
    [72] = {
        classFile = "WARRIOR", className = "Warrior", specName = "Fury",
        sourceURL = "https://www.wowhead.com/guide/classes/warrior/fury/talent-builds-pve-dps",
    },
    [73] = {
        classFile = "WARRIOR", className = "Warrior", specName = "Protection",
        sourceURL = "https://www.wowhead.com/guide/classes/warrior/protection/talent-builds-pve-tank",
    },
}

for specID, meta in pairs(AGB.TalentOnlySpecs) do
    AGB.Data[meta.classFile] = AGB.Data[meta.classFile] or {}
    if not AGB.Data[meta.classFile][specID] then
        AGB.Data[meta.classFile][specID] = {
            className = meta.className,
            specName = meta.specName,
            patch = "12.1.0",
            talentOnly = true,
            talents = {
                sourceName = "Wowhead - Talent Builds - Midnight",
                sourceUpdated = "live source",
                sourceURL = meta.sourceURL,
                previewLevel = 90,
                builds = {
                    { key = "raid", name = "Raid", content = "Raid", note = "Source-listed Raid builds are collected from the live Wowhead guide. Select a captured guide variant below; exact builds are revalidated by WoW and any unresolved source row remains fail-closed." },
                    { key = "mythicplus", name = "Mythic+", content = "Mythic+", note = "Source-listed Mythic+ builds are collected from the live Wowhead guide. Select a captured guide variant below; exact builds are revalidated by WoW and any unresolved source row remains fail-closed." },
                    { key = "delves", name = "Delves", content = "Delves", note = "Source-listed Delves builds are collected from the live Wowhead guide. Select a captured guide variant below; exact builds are revalidated by WoW and any unresolved source row remains fail-closed." },
                },
                limitation = TALENT_LIMITATION,
            },
            sources = {
                { label = "Talent Builds", updated = "live source", url = meta.sourceURL },
            },
        }
    end
end

-- Restore the older public alias for older code/data consumers.
for _, classInfo in ipairs(AGB.GuideClasses) do
    if classInfo.classFile == "SHAMAN" then
        AGB.ShamanSpecs = classInfo.specs
        break
    end
end