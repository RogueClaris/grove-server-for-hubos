---@param encounter Encounter
---@param data Liberation.EncounterData
function encounter_init(encounter, data)
    if data.terrain == "advantage" then
        for i = 1, 3 do
            Field.tile_at(4, i):set_team(Team.Red, Direction.Right)
        end
    elseif data.terrain == "disadvantage" then
        for i = 1, 3 do
            Field.tile_at(3, i):set_team(Team.Blue, Direction.Left)
        end
    elseif data.terrain == "surrounded" then
        for x = 0, 2 do
            for y = 1, 3 do
                Field.tile_at(x, y):set_team(Team.Blue, Direction.Right)
            end
        end

        for y = 1, 3 do
            Field.tile_at(3, y):set_team(Team.Red, Direction.Left)
        end

        for y = 1, 3 do
            Field.tile_at(4, y):set_team(Team.Red, Direction.Right)
        end

        encounter:spawn_player(0, 3, 2)
        encounter:spawn_player(1, 4, 2)
    end

    local test_spawner = encounter:create_spawner("BattleNetwork5.Character.BigBrute", Rank.V1)
    test_spawner:spawn_at(5, 2):mutate(function(entity)
        if data.health then
            entity:set_health(data.health)
        end
    end)
end
