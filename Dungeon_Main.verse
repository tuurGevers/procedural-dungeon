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
    @editable     LinePropAsset : creative_prop_asset = DefaultCreativePropAsset
    OnBegin<override>()<suspends>:void=
        # Initialize the dungeon
        # dungeon := CreateDungeon(20, SpawnCube, CombatCube, BossCube, CorridorAsset)
        # dungeon.Generate()
       
        Dungeon2:= CreateDungeonV2(15, 3, 6, 6, CombatCube, LinePropAsset, BossCube)
        

        # Optionally, print out positions and other properties for debugging
        Print("Room and corridor spawning complete. Check visualization for correctness.")
    