using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Simulation/Tags }

# Function to create a room
CreateRoomV4(
    X: int, Y: int, Points: []tuple(Point, creative_prop_asset), Type: string, Parent: DungeonV3
)<suspends>: RoomV4 =
    room := RoomV4{
        X := X,
        Y := Y,
        Points := Points,
        UUID := GenerateUUID(),
        Type := Type,
        Parent := Parent
    }
    room.Init()
    return room

RoomV4 := class:
    UUID: string
    X: int
    Y: int
    Points: []tuple(Point, creative_prop_asset)
    Connections: []RoomV2 = array{}
    Type: string
    Parent: DungeonV3
    var Props: []creative_prop = array{}

    Init()<suspends>: void =
        for (pointAsset: Points):
            point := pointAsset(0)
            asset := pointAsset(1)
            Spawn := vector3{X := (X + point.X) * Parent.PropSize, Y := (Y + point.Y) * Parent.PropSize, Z := 50.0}
            Prop := SpawnTarget(Spawn, asset)
            set Props += array{Prop}

Dungeon1Tag := class(tag){}

DungeonV4 := class():
    ILE_CORRIDOR_FLOOR_PROP : creative_prop_asset
    TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset
    TILE_CORRIDOR_ENTRANCE_PROP : creative_prop_asset
    TILE_CORRIDOR_CORNER_PROP: creative_prop_asset
    TILE_CORRIDOR_TPOINT_PROP: creative_prop_asset
    CombatCube: creative_prop_asset 
    LinePropAsset : creative_prop_asset
    BossCube : creative_prop_asset
    DebugCube: creative_prop_asset
    DebugLinePropAsset: creative_prop_asset
    AStarLinePropAsset:creative_prop_asset
    PropSize:float
    var OccupancyGrid: [][]int = array{}
    DungeonLevel: int = 1

    # List of all rooms in the dungeon
    var Rooms: []RoomV4 = array{}
    
    # Dungeon width and height for boundary checks
    var Width:int
    var Height:int

    PreferedRooms:int

    # Function to add a room to the dungeon
    AddRoom(room:RoomV4): void =
        set Rooms += array{room}    

    Generate()<suspends>:void=
       Print("")
