local items = {}

items.item_table = {
    -- KEY ITEMS: CORE
    HPMem = { "HPMem", "Max HP increases by 20!", false },
    Unlocker = { "Unlocker", "Decrypt protected data.", false },
    RailPass = { "RailPass", "Lets you use the CybrRail.", false },
    FireID = { "FireID", "Proof of encountering FireMan.", false },
    GutsProof = { "GutsProof", "Proof of GutsMan's defeat.", false },
    MaintID = { "MaintID", "Proof you're a Hospital Tech", false },

    -- KEY ITEMS: P-CODES
    DexCode = { "DexCode", "A PCode to Dex's HP.", false },
    YaiCode = { "YaiCode", "A PCode to Yai's HP.", false },
    MaylCode = { "MaylCode", "A PCode to Mayl's HP.", false },
    LanCode = { "LanCode", "A PCode to Lan's HP.", false },
    SciCode = { "SciKey", "A Passkey to SciLabSq.", false },
    HometownCode = { "ACDCKey", "A Passkey to ACDC Square.", false },
    CityCode = { "DenKey", "A Passkey to DenCtySq.", false },
    GlobalNetPass = { "G-Pass", "A Passkey to the Global Network.", false },

    -- CONSUMABLES
    MiniEnrg = { "MiniEnrg", "Restores 25% HP!", true },
    HalfEnrg = { "HalfEnrg", "Restores 50% HP!", true },
    FullEnrg = { "FullEnrg", "Restores Max HP!", true },

    SneakRun = { "SneakRun", "No weak viruses for a while.", true },
    LocEnemy = { "LocEnemy", "Locate last enemy fought.", true },

    Tinder = { "Tinder", "Attract Fire viruses.", true },
    DirtSmel = { "DirtSmel", "Attract Wood viruses.", true },
    LghtnRod = { "LghtnRod", "Attract Elec viruses." },
    FishBait = { "FishBait", "Attract Aqua viruses.", true },

    WhtStone = { "WhtStone", "Attract Sword viruses.", true },
    WthrVane = { "WthrVane", "Attract Wind viruses.", true },
    BackTrgt = { "BackTrgt", "Attract Cursor viruses.", true },
    HevyBall = { "HevyBall", "Attracts Break viruses.", true },

    -- KEY ITEMS: SIDEQUESTS
    YaiData = { "YaiData", "Data from Yai's homework. She needs this!", false },
    CyberFrappe = { "CybrFrap", "A luxury Cyber-Drink.", false },
    ForteScrap = { "F.Scrap", "A scrap of Forte's cloak...", false },
    OvenCoolant = { "Coolant", "Douses small CyberFires!", false },

    -- LIBERATION ITEMS

    -- Range Key: Length x Width
    -- Example: 2x3 means 2 panels forward, 3 panels wide; this is LifeSword range.

    -- Active
    -- Range: 3 Forward, 1 Wide
    -- Destroys panels, items, traps
    -- Point Cost: 2
    GutsHammer = { "GutsHamr", "Destroys panels, items, and traps 3sq ahead.", false },

    -- Active
    -- Range: 2 Forward, 3 Wide
    -- Destroys panels, items, traps.
    -- Point Cost: 2
    SharpAx = { "SharpAx", "3x2. Destroys panels, items, and traps.", false },

    -- Active, Combat.
    -- Range: 2x1
    -- Does not disable traps.
    -- Does not destroy items.
    -- Point Cost: 1
    LongSword = { "LongSwrd", "A LongSwrd chip. Use it in liberations!", false },

    -- Active, Combat.
    -- Range: 1x3
    -- Does not disable traps.
    -- Does not destroy items.
    -- Point Cost: 1
    WideSword = { "WideSwrd", "Liberate 3sq in front.", false },

    -- Active, Combat.
    -- Range: 4x1
    -- Destroys traps.
    -- Point Cost: 4
    OldSaber = { "OldSaber", "NtpArmy Saber tech. Liberate a path ahead!", false },

    -- Passive
    -- Blocks damage from enemy map attacks. Does not defend teammates.
    -- Point Cost: N/A
    HeavyShield = { "HevyShld", "Creamland military tech. Defend from any attack!", false },

    -- Passive.
    -- Enables movement on dark panels, cannot liberate unless on normal ground
    -- Point Cost: N/A
    ShdwShoe = { "ShdwShoe", "Shoes as light as air. Step over DrkPanls!", false },

    -- Active, Conditional.
    -- Deal 30% damage to Dark Hole viruses and bosses.
    -- Point Cost: 2
    HexSickle = { "HexSickl", "Assassin gear. Deal high dmg to bosses!", false },

    -- Active, Noncombat.
    -- Disarms all traps and collects items without liberating.
    -- Point Cost: 2
    NumberSearch = { "NumGdgt", "A gift from Higsby. Disarms traps & collect items!", false },

    -- Active, Noncombat.
    -- Grant a barrier that negates one map attack, fades after current turn.
    -- Point Cost: 1
    TeamBarr = { "TeamBarr", "A modified Barrier chip. Everyone absorbs 1 hit!", false }
}

items.setup = function()
    for key, value in pairs(items.item_table) do
        Net.register_item(value[1], { name = value[1], description = value[2], consumable = value[3] })
    end
end

return items
