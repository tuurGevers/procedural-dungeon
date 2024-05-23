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

# Define a new class to represent 3D points
Point3D := class:
    var X: int = 0
    var Y: int = 0
    var Z: int = 0

# Define RoomV5 to use Point3D for positioning and dimensions
RoomV5 := class:
    Asset: DungeonAssetV5
    var StartPoint: Point3D = Point3D{X:=0, Y:=0, Z:=0}
    var EntrancePoints: []Point3D = array{}
    var Rotation:int=0
    var Width: int = 0
    var Height: int = 0
    var Depth: int = 0  # Represents the vertical extension, i.e., floors
    TileSize: float
    TileHeight: float
    Parent: DungeonV5
    var RoomProp:creative_prop = creative_prop{}

    # Initialize room dimensions
    InitDimensions()<suspends>: void =
        dimensions := Asset.Size
        if:
            set Width = Floor[dimensions.X]
            set Height = Floor[dimensions.Y]
            set Depth = Floor[dimensions.Z]
        Print("Width: {Width}, Height: {Height}, Depth: {Depth}")

    # Check if the room placement overlaps or is too close to existing rooms
    CheckRoomPlacement(startX: int, startY: int, startZ: int, roomWidth: int, roomHeight: int, roomDepth: int)<transacts>: logic =
        for (x := startX - 2..startX + roomWidth + 2):
            for (y := startY - 2..startY + roomHeight + 2):
                for (z := startZ - 1..startZ + roomDepth + 1):  # Consider one floor above and below for buffer
                    if (Parent.OccupancyGrid[x][y][z] <> 0):
                        return false
        return true

    # Place the room randomly within the bounds, adjusting for 3D
    PlaceRandomly(maxWidth: float, maxHeight: float, maxDepth: float)<suspends>: void =
        loop:
            if(potentialX := GetRandomInt(1, Floor[maxWidth/TileSize] - Width - 1),
            potentialY := GetRandomInt(1, Floor[maxHeight/TileSize] - Height - 1),
            potentialZ := GetRandomInt(0, Floor[maxDepth/TileSize] - Depth)):  # Assuming floors start from 0
                if (CheckRoomPlacement(potentialX, potentialY, potentialZ, Width, Height, Depth) = true):
                    set StartPoint = Point3D{X:=potentialX, Y:=potentialY, Z:=potentialZ}
                    MarkGridOccupied(potentialX, potentialY, potentialZ, Width, Height, Depth)
                    break

    RotateRandomly()<suspends>: void =
        if(set Rotation = array{0, 90, 180, 270}[GetRandomInt(0, 3)]){}
        # set Rotation =0

    RotateEntrance()<suspends>: void =
        for(I->EntrancePoint:EntrancePoints):
            # Adjust the entrance point based on the room's rotation
            oldEntranceX := EntrancePoint.X
            oldEntranceY := EntrancePoint.Y
            oldEntranceZ := EntrancePoint.Z
            case (Rotation):
                90 => if(set EntrancePoints[I] = Point3D{X:=oldEntranceY*-1, Y:=oldEntranceX,Z:=oldEntranceZ  } ){}
                180 => if(set EntrancePoints[I] = Point3D{X:=oldEntranceX, Y:=oldEntranceY*-1,Z:=oldEntranceZ }){}
                270 => if(set EntrancePoints[I] = Point3D{X:=oldEntranceY, Y:=oldEntranceX, Z:=oldEntranceZ}){}
                _=> # If rotation is 0 or invalid, keep the original entrance point

    SpawnRoom()<suspends>: void =
        # Convert grid position to world coordinates
        Location := vector3{X:= StartPoint.X * TileSize, Y:= StartPoint.Y * TileSize, Z:= StartPoint.Z * TileHeight}
        set RoomProp= SpawnTarget(Location, Asset.Asset)
        if(RoomProp.TeleportTo[Location,RoomProp.GetTransform().Rotation.ApplyYaw(DegreesToRadians(Rotation*1.0))]){}
        Print("Room spawned at {Location}")

    MarkEntrance(DebugProp:creative_prop_asset):void=
        # Convert grid position to world coordinates
        for(EntrancePoint:EntrancePoints):
            EntranceLocation := vector3{
                X:= (StartPoint.X + EntrancePoint.X) * TileSize,
                Y:= (StartPoint.Y + EntrancePoint.Y) * TileSize,
                Z:= (StartPoint.Z + EntrancePoint.Z) * TileHeight
            }        
            SpawnTarget(EntranceLocation, DebugProp)
            Print("Entrance marked at {EntranceLocation}")


    # Mark the grid as occupied
    MarkGridOccupied(x: int, y: int, z: int, width: int, height: int, depth: int): void =
        for (xi := x..x + width):
            for (yi := y..y + height):
                for (zi := z..z + depth):
                    if(set Parent.OccupancyGrid[xi][yi][zi] = 1){}

DungeonV5 := class:
    var OccupancyGrid: [][][]int = array{}
    var RoomList: []RoomV5 = array{}

    LinePropAsset:creative_prop_asset
    BossCube:creative_prop_asset
    DebugCube:creative_prop_asset
    TILE_CORRIDOR_FLOOR_PROP:creative_prop_asset
    TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset
    TILE_CORRIDOR_CORNER_PROP: creative_prop_asset
    TILE_CORRIDOR_TPOINT_PROP: creative_prop_asset
    Parent:DungeonMainV5
    var GridWidth:int=0
    var GridHeight:int=0


    InitOccupancyGrid(Width:int, Height:int, Depth:int): void =
        set GridWidth = Width
        set GridHeight = Height
        for(I:=0..Width-1):
            set OccupancyGrid+= array{array{}}
            for(J:=0..Height-1):
                if(set OccupancyGrid[I]+= array{array{}}){}
                for(K:=0..Depth-1):
                    if(set OccupancyGrid[I][J]+= array{0}){}
        W:= OccupancyGrid.Length
        Print("WIshto{W}")        
        if( H:= OccupancyGrid[0].Length) :  
            if(D:= OccupancyGrid[0][0].Length)  :
                Print("Occupancy grid initialized with {W}x{H}x{D} dimensions.")