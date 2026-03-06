local ModDownloader = require("scripts/libs/mod_downloader")

local package_ids = {
  -- bosses

  -- BN4
  "BattleNetwork4.FireMan",
  "BattleNetwork4.GutsMan",
  "BattleNetwork4.Bass",

  -- BN5
  "BattleNetwork3.Metrid",
  "BattleNetwork5.BlizzardMan",
  "BattleNetwork5.Virus.BigBrute",

  -- viruses
  -- BN3
  "BattleNetwork3.Basher",
  "BattleNetwork3.Ratty",
  "BattleNetwork3.Canodumb",
  "BattleNetwork3.Enemy.Spikey",
  "BattleNetwork3.Virus.Boomer",

  -- BN4
  "BattleNetwork4.Gaia",

  -- BN5
  "BattleNetwork5.Cactikil",
  "BattleNetwork5.Powie",

  -- BN6
  "BattleNetwork6.Piranha",
  "BattleNetwork6.Gunner",
  "BattleNetwork6.Mettaur",
  "BattleNetwork6.Encounter.FighterPlane",

  -- libraries
  "BattleNetwork.Assets",
  "BattleNetwork.FallingRock",
  "dev.konstinople.library.ai",
  "dev.konstinople.library.iterator",
  "BattleNetwork6.Libraries.Conveyor",

  -- tile states
  -- BN2
  "BattleNetwork2.TileStates.Magnet",

  -- BN3
  "BattleNetwork3.TileStates.Sand",
  "BattleNetwork3.TileStates.Metal",

  -- BN4
  "BattleNetwork4.TileStates.Dark",

  -- BN5
  "BattleNetwork5.TileStates.Sea",
  "BattleNetwork5.TileStates.Lava",

  -- BN6
  "BattleNetwork6.TileStates.Ice",
  "BattleNetwork6.TileStates.Holy",
  "BattleNetwork6.TileStates.Grass",
  "BattleNetwork6.TileStates.Poison",
  "BattleNetwork6.TileStates.Volcano",
  "BattleNetwork6.TileStates.ConveyorUp",
  "BattleNetwork6.TileStates.ConveyorLeft",
  "BattleNetwork6.TileStates.ConveyorDown",
  "BattleNetwork6.TileStates.ConveyorRight",

  -- Custom
  "dev.GladeWoodsgrove.TileStates.Brambles",
  "dev.GladeWoodsgrove.TileStates.SwordTrap",

  -- statuses
  "BattleNetwork6.Statuses.EnemyAlert",

  -- minimal libraries necessary for liberations:
  "dev.konstinople.library.liberation",
  "BattleNetwork6.Statuses.Invincible",
}

ModDownloader.maintain(package_ids)

Net:on("player_connect", function(event)
  -- preload mods on join
  for _, package_id in ipairs(package_ids) do
    Net.provide_package_for_player(event.player_id, ModDownloader.resolve_asset_path(package_id))
  end
end)
