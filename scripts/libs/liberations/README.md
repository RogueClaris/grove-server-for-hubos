# Hub OS Nebulous Liberations Lib

## Setting Up

The library comes in two pieces, assets and scripts.

Assets are found in `assets/liberations`, it must always have this path as the Lua library references files in this location.

You can find the Lua library in `scripts/libs/liberations`, it must always be at this path.

### Minimal Map

- At least 1 [Spawn Point](#spawn-point) placed on the map for spawning players.
- A single [Dark Panel](#dark-panel) with a `Boss` set to allow players to complete the mission.
- The map custom property `Liberation Encounter` should be set to decide the default encounter for dark panels.
- `assets/liberations/tiles/collision.tsx` should be included as a tileset, even if it is unused in the map.
  - This tile set is used to toggle collision on panels for shadow step.
  - You can include this tileset by applying it to a tile or new object in the map, then deleting it.

### Encounters

The `data` param in `encounter_init(encounter, data)` is used by the server to pass relevant state into your encounter.

Keys on the `data` table and how you should handle them:

- `terrain`
  - `even`
    - The default field layout should be used.
  - `advantage`
    - The red team should have an extra column.
  - `disadvantage`
    - The blue team should have an extra column.
  - `surrounded`
    - The encounter should set two blue columns on each side of the field, with the red team stuck in the middle.
- `rank`
  - Only appears when the player is fighting a boss / miniboss.
  - It should be possible to use `Rank[data.rank]` to resolve the rank to pass for spawning this enemy.
- `health`
  - Only appears when the player is fighting a boss / miniboss. Used to restore the enemy's health from a previous battle.
  - The [:mutate()](https://docs.hubos.dev/client/lua-api/field-api/encounter#mutatormutatefunctionentity) function can be chained with `encounter:spawn_at()` to modify enemies spawned by `encounter`.

There's a type definition file at `scripts/libs/liberations/liberations.client.d.lua`. When this file is included, similar to the client type definitions in the [Getting Started guide](https://docs.hubos.dev/client/getting-started), your editor will have auto complete and error information for the data param when properly tagged.

Example of tagging the type for the data param:

```lua
---@param encounter Encounter
---@param data Liberation.EncounterData
function encounter_init(encounter, data)
end
```

## Map Custom Properties

- `Liberation Encounter` a server path to the default encounter
  - example: `/server/mods/default-encounter`
- `Target Phase` number, optional. Defaults to 10
  - Used to resolve a reasonable target phase based on the player count
- `Target Player Count` number, optional. Defaults to 1
  - Used to resolve a reasonable target phase based on the player count
- `Minimum Target Phase` number, optional. Defaults to 1
  - Used to resolve a reasonable target phase based on the player count

## Spawn Point

You should have one point object named `Spawn Point` somewhere on the map to decide where players spawn in.

You can chain multiple spawn points for the library to cycle through by adding a `Next Point` custom property with type object, pointing to another point (which may also have this property).

## Panels

Panels are Tile Objects, identified by the library using the `Type` field.

Every panel aside from `Dark Panel`, `Item Panel`, and `Trap Panel` should have a collision slightly larger than a tile defined. You can copy the collision from `assets/liberations/tiles/collision.tsx`.

The panels in `assets/liberations/tiles/panels.tsx` already have collisions properly set.

Supported panel `Type`s and custom properties can be found below.

### `Dark Panel`

- `Encounter` a server path to the encounter, uses the map's default when missing.
- `Boss` the name of the boss to spawn, overrides the `Encounter`
- `Rank` the rank of the boss, ex: `V1`, `SP`, `Omega`. Passed as `rank` in the encounter's data param.

### `Dark Hole`

- `Direction` the direction the character spawned should face
- `Spawns` the name of the enemy to spawn, overrides `Encounter` when this character moves over another panel
- `Rank` the rank of the spawned enemy, ex: `V1`, `SP`, `Omega`. Passed as `rank` in the encounter's data param.

### `Trap Panel`

- `Encounter` a server path to the encounter, uses the map's default when missing.

### `Item Panel`

- `Specific Loot` the name of a specific loot, falls back to a pool otherwise
- `Encounter` a server path to the encounter, uses the map's default when missing.

### `Bonus Panel`

- `Specific Loot` the name of a specific loot, falls back to a pool otherwise

### `Gate Panel`

- `Gate Key` unlocks when a `KEY` with a matching property is looted

### `Indestructible Panel`

Converts into a Dark Panel when every `Dark Hole` is destroyed

## Specific Loot

Additional custom properties are supported by loot.

- `HEART` - Heals 50% of the player's health
- `CHIP` - WIP
- `MONEY` - Rewards money to the player. WIP
  - `Money` Determines how much money to give
- `BUGFRAG` - WIP
- `ORDER_POINT` - Grants the player 3 Order Points, the player can have at most 8 at a time.
- `INVINCIBILITY` - Grants the player on-map invincibility, stopping Guardian and Darkloid attacks from harming them.
- `MAJOR_HIT` - Destroys a nearby Guardian. Won’t destroy bosses.
- `KEY`
  - `Gate Key` unlocks every `Gate Panel` with a matching value in the `Gate Key` property
