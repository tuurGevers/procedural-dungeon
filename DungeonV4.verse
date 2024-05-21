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

PointV2 := class<concrete>:
    var X: float = 0.0
    var Y: float = 0.0

    # Function
# Function to create a room
RoomV4 := class:
    Asset: DungeonAsset
    var StartPoint: PointV2 = PointV2{X:=0.0, Y:=0.0}
    var EndPoint: PointV2 = PointV2{X:=0.0, Y:=0.0}
    var EntrancePoint: PointV2 = PointV2{X:=0.0, Y:=0.0}
    var Width: float :=0.0
    var Height: float :=0.0
    var Rotation:int=0
    TileSize:float
    var RoomProp:creative_prop = creative_prop{}

    # Initialize room dimensions
    InitDimensions()<suspends>: void =
        # Assuming a method to get dimensions from the asset, e.g., GetAssetDimensions()
        dimensions := Asset.Size
        set Width = dimensions.X
        set Height = dimensions.Y
        Print("Width: {Width}, Height: {Height}")

    PlaceRandomly(maxWidth: float, maxHeight: float)<suspends>: void =
        set StartPoint.X = GetRandomFloat(0.0, maxWidth/TileSize - Width )
        set StartPoint.Y = GetRandomFloat(0.0, maxHeight/TileSize - Height )
        Print("StartPoint: {StartPoint.X} , {StartPoint.Y}")

    RotateRandomly()<suspends>: void =
        if(set Rotation = array{0, 90, 180, 270}[GetRandomInt(0, 3)]){}

    RotateEntrance()<suspends>: void =
        # Adjust the entrance point based on the room's rotation
        
        case (Rotation):
            90 => set EntrancePoint = PointV2{X:= Height - 1.0 - EntrancePoint.Y, Y:= EntrancePoint.X}
            180 => set EntrancePoint = PointV2{X:= Width - 1.0 - EntrancePoint.X, Y:= Height - 1.0 - EntrancePoint.Y}
            270 => set EntrancePoint = PointV2{X:= EntrancePoint.Y, Y:= Width - 1.0 - EntrancePoint.X}
            _=> 

    SpawnRoom()<suspends>: void =
        # Convert grid position to world coordinates
        Location := vector3{X:= StartPoint.X * TileSize, Y:= StartPoint.Y * TileSize, Z:= 0.0}
        set RoomProp= SpawnTarget(Location, Asset.Asset)
        if(RoomProp.TeleportTo[Location,RoomProp.GetTransform().Rotation.ApplyYaw(DegreesToRadians(Rotation*1.0))]){}
        Print("Room spawned at {Location}")


DungeonV4 := class:
    RoomAssets: []DungeonAsset 
    var OccupancyGrid: [][]int = array{}
    var RoomList: []RoomV4 = array{}

