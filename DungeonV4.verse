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
    var X: int = 0
    var Y: int = 0

    # Function
# Function to create a room
RoomV4 := class:
    Asset: DungeonAsset
    var StartPoint: Point = Point{X:=0, Y:=0, UUID:="", ID:=0}
    var EndPoint: Point = Point{X:=0, Y:=0, UUID:="", ID:=0}
    var EntrancePoint: Point = Point{X:=0, Y:=0, UUID:="", ID:=0}
    var Width: int :=0
    var Height: int :=0
    var Rotation:int=0
    TileSize:float
    var RoomProp:creative_prop = creative_prop{}
    Parent:DungeonV4

    # Initialize room dimensions
    InitDimensions()<suspends>: void =
        # Assuming a method to get dimensions from the asset, e.g., GetAssetDimensions()
        dimensions := Asset.Size
        if:
            set Width = Floor[dimensions.X]
            set Height = Floor[dimensions.Y]
        Print("Width: {Width}, Height: {Height}")


    # Method to check if room overlaps or is too close to existing rooms
    CheckRoomPlacement(startX: int, startY: int, roomWidth: int, roomHeight: int)<transacts>: logic =
                for (x:= startX-2..startX + roomWidth + 2):
                    for (y := startY-2..startY + roomHeight + 2):
                        if (Parent.OccupancyGrid[x][y] <> 0):  # Assumes 0 is unoccupied
                            return false
        return true
    
    PlaceRandomly(maxWidth: float, maxHeight: float)<suspends>: void =
        # Try placing the room randomly until a valid spot is found
        loop:
            if(FlooredMaxWidth:=Floor[maxWidth/TileSize]):
                if(FlooredMaxHeight:=Floor[maxHeight/TileSize]):
                    potentialX := GetRandomInt(1, FlooredMaxWidth - Width - 1)  # Avoid edges for boundary buffer
                    potentialY := GetRandomInt(1, FlooredMaxHeight - Height - 1)
                    if( CheckRoomPlacement( potentialX, potentialY, Width, Height)=true):
                        set StartPoint.X = potentialX
                        set StartPoint.Y = potentialY
                        # Mark the grid as occupied
                        for (x:= potentialX..potentialX + Width ):
                            for (y := potentialY..potentialY + Height ):
                                if(set Parent.OccupancyGrid[x][y] = 1){}
                        break
            
        Print("StartPoint: {StartPoint.X} , {StartPoint.Y}")

    RotateRandomly()<suspends>: void =
        if(set Rotation = array{0, 90, 180, 270}[GetRandomInt(0, 3)]){}
        # set Rotation =0

    RotateEntrance()<suspends>: void =
        # Adjust the entrance point based on the room's rotation
        oldEntranceX := EntrancePoint.X
        oldEntranceY := EntrancePoint.Y
        case (Rotation):
            90 => set EntrancePoint = CreatePoint(oldEntranceY*-1,oldEntranceX ) 
            180 => set EntrancePoint = CreatePoint(oldEntranceX, oldEntranceY*-1)
            270 => set EntrancePoint = CreatePoint(oldEntranceY, oldEntranceX)
            _=> # If rotation is 0 or invalid, keep the original entrance point


    SpawnRoom()<suspends>: void =
        # Convert grid position to world coordinates
        Location := vector3{X:= StartPoint.X * TileSize, Y:= StartPoint.Y * TileSize, Z:= 0.0}
        set RoomProp= SpawnTarget(Location, Asset.Asset)
        if(RoomProp.TeleportTo[Location,RoomProp.GetTransform().Rotation.ApplyYaw(DegreesToRadians(Rotation*1.0))]){}
        Print("Room spawned at {Location}")
    

    MarkEntrance(DebugProp:creative_prop_asset):void=
        # Convert grid position to world coordinates
        EntranceLocation := vector3{
            X:= (StartPoint.X + EntrancePoint.X) * TileSize,
            Y:= (StartPoint.Y + EntrancePoint.Y) * TileSize,
            Z:= 50.0  # Slightly above the ground for visibility
        }        
        SpawnTarget(EntranceLocation, DebugProp)
        Print("Entrance marked at {EntranceLocation}")


DungeonV4 := class:
    var OccupancyGrid: [][]int = array{}
    var RoomList: []RoomV4 = array{}
    LinePropAsset:creative_prop_asset
    BossCube:creative_prop_asset
    DebugCube:creative_prop_asset

    InitOccupancyGrid(Width:int, Height:int): void =
        for(I:=0..Width-1):
            set OccupancyGrid+= array{array{}}
            for(J:=0..Height-1):
                if(set OccupancyGrid[I] += array{0}){}
        W:= OccupancyGrid.Length
        Print("WIshto{W}")        
        if( H:= OccupancyGrid[0].Length) :      
            Print("Occupancy grid initialized with {W}x{H} dimensions.")

    InitPathFinding()<suspends>:void=
        var RoomEntryPoints: []Point = array{}
        for(room : RoomList):
            EntranceLocation := CreatePoint(room.StartPoint.X + room.EntrancePoint.X, room.StartPoint.Y + room.EntrancePoint.Y)
            set RoomEntryPoints += array{EntranceLocation}
        
        Triangulation := DelaunayTriangulation{LinePropAsset:= LinePropAsset, BossCube:=BossCube}  # Ensure LinePropAsset is defined or passed appropriately
        StartingTriangles:= Triangulation.Initialize(RoomEntryPoints)

        # Perform the triangulation
        Triangles := Triangulation.Triangulate(RoomEntryPoints)

        var Edges: []tuple(Point,Point) = array{}
        for(triangle :Triangles):
            for(edge:triangle.Edges):
                set Edges += array{edge}

        #
        var UniqueEdges :[string]tuple(Point,Point)= map{}
        for (edge : Edges):
            var ShouldSkip:logic = false
            sortedEdge := SortEdgePoints(edge)
            for(T:StartingTriangles):
                for(TEdge: T.Edges):
                    if((TEdge(0).X = edge(0).X and TEdge(0).Y = edge(0).Y) or (TEdge(1).X = edge(1).X and TEdge(1).Y = edge(1).Y)):
                        set ShouldSkip = true
            if(ShouldSkip = false):
                edgeKey := "{sortedEdge(0).UUID}-{sortedEdge(1).UUID}"
                if(set UniqueEdges[edgeKey] = edge){}

        set Edges = array{}
        for(Key->Value: UniqueEdges):
            set Edges+= array{Value}

        var RoomPairs: []tuple(Point, Point) = array{}

        # Create all pairs for MST edges
        for(i := 0 .. RoomEntryPoints.Length - 1):
            for(j := i + 1 .. RoomEntryPoints.Length - 1):
                if(set RoomPairs += array{(RoomEntryPoints[i], RoomEntryPoints[j])}){}
                
        # Apply Kruskal's MST algorithm to connect all rooms
        var MSTEdges: []Edge = KruskalMST(RoomEntryPoints, Edges)
        Print("total mst edges: {MSTEdges.Length}")
        
        #
        AStar3 := AStarV3{OccupancyGrid:= OccupancyGrid, DebugCube:= DebugCube, FinalCube:=BossCube}
        AStar3.Init(OccupancyGrid)

        var AIndex2:int = 0
        

        loop:
            if(MSTEdge:=MSTEdges[AIndex2]):
                AStarAsync(MSTEdge, AStar3, ?Final:=true)
                
            set AIndex2+=1

            if(AIndex2>= MSTEdges.Length):
                break

       
        set OccupancyGrid = AStar3.OccupancyGrid
        # MergeParallelCorridors()

        for(edge: MSTEdges):
            if(set OccupancyGrid[edge.Point1.X][edge.Point1.Y] = 1){}
            if(set OccupancyGrid[edge.Point2.X][edge.Point2.Y] = 1){}

    # Function to sort edge points by ID to ensure consistency
    SortEdgePoints(edge: tuple(Point, Point)): tuple(Point, Point) =
        if (edge(0).UUID.GetIntValue() < edge(1).UUID.GetIntValue()):
            return (edge(0), edge(1))
        else:
            return (edge(1), edge(0))

 
    #
    AStarAsync(MSTEdge: Edge, AStar: AStarV3, ?Final: logic = false)<suspends>: void =
      
        var SelectedStartPoint: Point = MSTEdge.Point1
        var SelectedEndPoint: Point = MSTEdge.Point2

        PathResult := AStar.Search(
            SelectedStartPoint, SelectedEndPoint
        )

        if(Final = true):
            for(index->I: PathResult):
                SpawnLocation := vector3{X := I.X * 500.0, Y := I.Y * 500.0, Z := 75.0}
                SpawnTarget(SpawnLocation, BossCube)

       

