## Map Custom Properties

- `Liberation Encounter` a server path to the default encounter
  - example: `/server/mods/default-encounter`
- `Target Phase` number, optional. Defaults to 10
  - Used to resolve a reasonable target phase based on the player count
- `Target Player Count` number, optional. Defaults to 1
  - Used to resolve a reasonable target phase based on the player count
- `Minimum Target Phase` number, optional. Defaults to 1
  - Used to resolve a reasonable target phase based on the player count

## Dark Panels

Dark Panels are Tile Objects.

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

Custom Properties for panels with an encounter:

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
  - `Gate Key` unlocks `Gate Panel`s with a matching property
