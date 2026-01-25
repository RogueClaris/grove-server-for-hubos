local LiberationLib = require("dev.konstinople.library.liberation")

---@param encounter Encounter
function encounter_init(encounter, data)
    print("Loading ACDC4 Liberation Encounter")
    print("Terrain = " .. data.terrain)

    LiberationLib.init(encounter, data)

    encounter:set_spectate_on_delete(true)

    if data.terrain == "advantage" then
        local choice = math.random(8)
        if choice == 1 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 2 then
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 3)
        elseif choice == 3 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 3)
        elseif choice == 4 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 3)
        elseif choice == 5 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 3)
        elseif choice == 6 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 3)
        elseif choice == 7 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 8 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 3)
        end
    elseif data.terrain == "disadvantage" then
        local choice = math.random(8)
        if choice == 1 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 2 then
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(4, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(3, 3)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(5, 2)
        elseif choice == 3 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(4, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 3)
        elseif choice == 4 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 3)
        elseif choice == 5 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(4, 1)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 6 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(4, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(3, 3)
        elseif choice == 7 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(4, 2)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(5, 3)
        elseif choice == 8 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(4, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(3, 3)
        end
    elseif data.terrain == "surrounded" then
        local choice = math.random(8)
        if choice == 1 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(1, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 2 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(1, 3)
        elseif choice == 3 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(2, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(1, 3)
        elseif choice == 4 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(1, 1)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(1, 3)
        elseif choice == 5 then
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(2, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(1, 3)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 6 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(2, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(1, 3)
        elseif choice == 7 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(1, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 8 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(1, 3)
        end
    else
        local choice = math.random(8)
        if choice == 1 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 2 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(4, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 3)
        elseif choice == 3 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(4, 3)
        elseif choice == 4 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 3)
        elseif choice == 5 then
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(5, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(4, 3)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(6, 3)
        elseif choice == 6 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(4, 3)
        elseif choice == 7 then
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(4, 2)
            encounter:create_spawner("BattleNetwork3.Basher.Enemy", Rank.V1):spawn_at(5, 3)
        elseif choice == 8 then
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 1)
            encounter:create_spawner("BattleNetwork3.Canodumb.Enemy", Rank.V1):spawn_at(5, 2)
            encounter:create_spawner("BattleNetwork3.Character.Spikey", Rank.V1):spawn_at(6, 3)
        end
    end
end
