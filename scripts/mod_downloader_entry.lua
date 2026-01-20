local ModDownloader = require("scripts/libs/mod_downloader")

local package_ids = {
  -- bosses
  "BattleNetwork4.FireMan",
  "BattleNetwork4.GutsMan",
  "BattleNetwork5.BlizzardMan",
  -- viruses
  "BattleNetwork3.Basher",
  "BattleNetwork3.Ratty",
  "BattleNetwork3.Spikey",
  "BattleNetwork4.Gaia",
  "BattleNetwork3.Canodumb",
  "BattleNetwork6.Mettaur",
  "BattleNetwork5.Cactikil",
  "BattleNetwork5.Powie",
  "BattleNetwork6.Piranha",
  "BattleNetwork6.Gunner",
  -- libraries
  "BattleNetwork.Assets",
  "BattleNetwork.FallingRock",
  "dev.konstinople.library.ai",
  "dev.konstinople.library.iterator",
  "BattleNetwork6.Statuses.EnemyAlert",
  "BattleNetwork6.TileStates.Ice",
}

ModDownloader.download_once(package_ids)

Net:on("player_connect", function(event)
  -- preload mods on join
  for _, package_id in ipairs(package_ids) do
    Net.provide_package_for_player(event.player_id, ModDownloader.resolve_asset_path(package_id))
  end
end)
