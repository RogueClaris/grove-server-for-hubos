function encounter_init(encounter, data)
    print("Loading ACDC4 Liberation Encounter")
    print("Terrain = " .. data.terrain)

    encounter:enable_automatic_turn_end(true);
    encounter:set_turn_limit(3);

    if data.terrain == "advantage" then
        for i = 1, 3 do
            local tile = encounter:field():tile_at(4, i)
            tile:set_team(Team.Red, Direction.Right)
        end

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
        encounter:enable_flipping(true)

        for i = 1, 3 do
            local tile = encounter:field():tile_at(3, i)
            tile:set_team(Team.Blue, Direction.Left)
        end

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
        encounter:enable_flipping(true)
        encounter:spawn_player(1, 3, 2)

        -- set behind tiles to blue
        for y = 1, 3 do
            for x = 1, 2 do
                local tile = encounter:field():tile_at(x, y)
                tile:set_team(Team.Blue, Direction.Left)
            end
        end

        -- set some tiles to red to give the player room
        for i = 1, 3 do
            local tile = encounter:field():tile_at(4, i)
            tile:set_team(Team.Red, Direction.Right)
        end

        -- set spawn position?

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
