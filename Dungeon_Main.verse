using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }


DungeonMain := class(creative_device):
    @editable SpawnCube: creative_prop_asset = DefaultCreativePropAsset
    @editable CombatCube: creative_prop_asset = DefaultCreativePropAsset
    @editable BossCube: creative_prop_asset = DefaultCreativePropAsset
    @editable CorridorAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable DebugCube : creative_prop_asset = DefaultCreativePropAsset
    @editable LinePropAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable DebugLinePropAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable AStarLinePropAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_ROOM_FLOOR_PROP : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_ROOM_WALL_PROP : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_WALL_CORNER_PROP : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_FLOOR_PROP : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_ENTRANCE_PROP : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_CORNER_PROP: creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_TPOINT_PROP: creative_prop_asset= DefaultCreativePropAsset

    OnBegin<override>()<suspends>:void=
        Print("free palpatine")
        Sleep(1.0)
        # Initialize the dungeon
        # dungeon := CreateDungeon(20, SpawnCube, CombatCube, BossCube, CorridorAsset)
        # dungeon.Generate()
        # Dungeon2:= CreateDungeonV2(13, 2, 4, 6, CombatCube, LinePropAsset, BossCube, DebugCube, DebugLinePropAsset, AStarLinePropAsset)
        Dungeon3:= CreateDungeonV3(40, 1, 3, 4, CombatCube, LinePropAsset, BossCube, DebugCube, DebugLinePropAsset, AStarLinePropAsset, 500.0, TILE_ROOM_FLOOR_PROP, TILE_ROOM_WALL_PROP, TILE_WALL_CORNER_PROP, TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_ENTRANCE_PROP, TILE_CORRIDOR_CORNER_PROP, TILE_CORRIDOR_TPOINT_PROP)
        

        # Optionally, print out positions and other properties for debugging
        Print("Room and corridor spawning complete. Check visualization for correctness.")
    