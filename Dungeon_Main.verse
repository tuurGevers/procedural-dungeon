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

    OnBegin<override>()<suspends>:void=
        # Initialize the dungeon
        dungeon := CreateDungeon(10, SpawnCube, CombatCube, BossCube, CorridorAsset)

        # Create and add rooms
        spawnRoom := CreateRoom(0, 1, 0, dungeon)
        combatRoom := CreateRoom(1, 1, 1, dungeon)
        combatRoom2 := CreateRoom(1, 2, 1, dungeon)
        combatRoom3 := CreateRoom(0, 0, 1, dungeon)
        bossRoom := CreateRoom(2, 1, 2, dungeon)
        
        dungeon.AddRoom(spawnRoom)
        dungeon.AddRoom(combatRoom)
        dungeon.AddRoom(combatRoom2)
        dungeon.AddRoom(combatRoom3)
        dungeon.AddRoom(bossRoom)

        # Connect rooms with corridors
        corridor1 := CreateCorridor(spawnRoom, combatRoom, dungeon)
        corridor2 := CreateCorridor(combatRoom, bossRoom, dungeon)
        corridor3 := CreateCorridor(combatRoom, combatRoom2, dungeon)
        corridor4 := CreateCorridor(spawnRoom, combatRoom3, dungeon)

        # Spawn rooms and corridors
        spawnRoom.SpawnRoom()
        combatRoom.SpawnRoom()
        combatRoom2.SpawnRoom()
        combatRoom3.SpawnRoom()
        bossRoom.SpawnRoom()
        corridor1.SpawnCorridor()
        corridor2.SpawnCorridor()
        corridor3.SpawnCorridor()
        corridor4.SpawnCorridor()

        # Optionally, print out positions and other properties for debugging
        Print("Room and corridor spawning complete. Check visualization for correctness.")
    