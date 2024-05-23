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


    # Function
# Function to create a room
RoomV4 := class:
    Asset: DungeonAsset
    var StartPoint: Point = Point{X:=0, Y:=0, UUID:="", ID:=0}
    var EndPoint: Point = Point{X:=0, Y:=0, UUID:="", ID:=0}
    var EntrancePoints: []Point = array{}
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
                        if(not Parent.OccupancyGrid[x][y]):
                            return false
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
                        if(HalfWidth:=Floor[Width*1.0/2.0]):
                            if(HalfHeight:=Floor[Height*1.0/2.0]):
                                
                                for (x:= potentialX-HalfWidth..potentialX + HalfWidth ):
                                    for (y := potentialY-HalfHeight..potentialY + HalfHeight ):
                                        if(set Parent.OccupancyGrid[x][y] = 1){}
                                        # SpawnTarget(vector3{X:= x * TileSize, Y:= y * TileSize, Z:= 1200.0},Parent.BossCube)
                        break
            
        Print("StartPoint: {StartPoint.X} , {StartPoint.Y}")

    RotateRandomly()<suspends>: void =
        if(set Rotation = array{0, 90, 180, 270}[GetRandomInt(0, 3)]){}
        # set Rotation =0

    RotateEntrance()<suspends>: void =
        for(I->EntrancePoint:EntrancePoints):
            # Adjust the entrance point based on the room's rotation
            oldEntranceX := EntrancePoint.X
            oldEntranceY := EntrancePoint.Y
            case (Rotation):
                90 => if(set EntrancePoints[I] = CreatePoint(oldEntranceY*-1,oldEntranceX ) ){}
                180 => if(set EntrancePoints[I] = CreatePoint(oldEntranceX, oldEntranceY*-1)){}
                270 => if(set EntrancePoints[I] = CreatePoint(oldEntranceY, oldEntranceX)){}
                _=> # If rotation is 0 or invalid, keep the original entrance point
      


    SpawnRoom()<suspends>: void =
        # Convert grid position to world coordinates
        Location := vector3{X:= StartPoint.X * TileSize, Y:= StartPoint.Y * TileSize, Z:= Parent.FloorHeight*1000.0}
        set RoomProp= SpawnTarget(Location, Asset.Asset)
        if(RoomProp.TeleportTo[Location,RoomProp.GetTransform().Rotation.ApplyYaw(DegreesToRadians(Rotation*1.0))]){}
        Print("Room spawned at {Location}")
    

    MarkEntrance(DebugProp:creative_prop_asset):void=
        # Convert grid position to world coordinates
        for(EntrancePoint:EntrancePoints):
            EntranceLocation := vector3{
                X:= (StartPoint.X + EntrancePoint.X) * TileSize,
                Y:= (StartPoint.Y + EntrancePoint.Y) * TileSize,
                Z:= Parent.FloorHeight *1000.0  # Slightly above the ground for visibility
            }        
            SpawnTarget(EntranceLocation, DebugProp)
            Print("Entrance marked at {EntranceLocation}")


DungeonV4 := class:
    var OccupancyGrid: [][]int = array{}
    var RoomList: []RoomV4 = array{}
    LinePropAsset:creative_prop_asset
    BossCube:creative_prop_asset
    DebugCube:creative_prop_asset
    TILE_CORRIDOR_FLOOR_PROP:creative_prop_asset
    TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset
    TILE_CORRIDOR_CORNER_PROP: creative_prop_asset
    TILE_CORRIDOR_TPOINT_PROP: creative_prop_asset
    Parent:DungeonMainV4
    var GridWidth:int=0
    var GridHeight:int=0
    FloorHeight:int

    InitOccupancyGrid(Width:int, Height:int): void =
        set GridWidth = Width
        set GridHeight = Height
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
            for(EntrancePoint:room.EntrancePoints):
                EntranceLocation := CreatePoint(room.StartPoint.X + EntrancePoint.X, room.StartPoint.Y + EntrancePoint.Y)
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
        #add a few adges with a low porbablility  from delaunay back to increase room connectivity
        # for(edge:Edges):
        #     var IsUnique:logic = true
        #     for(MSTEdge:MSTEdges):
        #         if(MSTEdge.Point1.UUID = edge(0).UUID and MSTEdge.Point2.UUID = edge(1).UUID):
        #             set IsUnique = false
        #         if(IsUnique = true):
        #             if(GetRandomFloat(0.0, 1.0) < 0.01):
        #                 set MSTEdges+= array{Edge{Point1:=edge(0), Point2:=edge(1)}}

        Print("total mst edges: {MSTEdges.Length}")
        
        #
        AStar3 := AStarV3{OccupancyGrid:= OccupancyGrid, DebugCube:= DebugCube, FinalCube:=BossCube}
        AStar3.Init(OccupancyGrid)

        var AIndex2:int = 0
        
        var AllProps: []creative_prop = array{}      
        loop:
            if(MSTEdge:=MSTEdges[AIndex2]):
                set AllProps += AStarAsync(MSTEdge, AStar3, ?Final:=true)
                
            set AIndex2+=1

            if(AIndex2>= MSTEdges.Length):
                break

        for(prop:AllProps):
            prop.Dispose()
       
        set OccupancyGrid = AStar3.OccupancyGrid
        for(room:RoomList):
            for(EntrancePoint:room.EntrancePoints):
                if(set OccupancyGrid[room.StartPoint.X+EntrancePoint.X][room.StartPoint.Y+EntrancePoint.Y] = 3){}
            
        for(X:OccupancyGrid):
            var arr:string = ""
            for(Y:X):
                set arr += "{Y} "
            Print("{arr}")
                
        # MergeParallelCorridors()

        tilemappingV4 := TileMapV4{ParentDungeon:=Self}
        FinalTiles:= tilemappingV4.GenerateTileMapping(OccupancyGrid)

        for(IndexI->I:FinalTiles):
            var PrintRow : string = ""

            for(IndexJ->J:I):
                tileType := J(0)
                rot := J(1)
                SpawnLocation := vector3{X := IndexI * 500.0, Y := IndexJ * 500.0, Z := FloorHeight *1000.0}

                set PrintRow+= "{J(0)}"
                case(J(0)):
                    "C" => {
                        Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_FLOOR_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
                    }
                    "X" => {
                        Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_CROSSING_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
                    }
                    "CC" => {
                        Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_CORNER_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
                    }
                    "CT" => {
                        Print("TPoint")
                        Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_TPOINT_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
                    }
                    _=>{}
            Print("{PrintRow}")

        for(Player:Parent.GetPlayspace().GetPlayers()):
            if(FC:=Player.GetFortCharacter[], StartRoom:=RoomList[0]):
                Sleep(0.1)
                Trans:=StartRoom.RoomProp.GetTransform().Translation
                # if(FC.TeleportTo[vector3{X:=Trans.X, Y:=Trans.Y, Z:=Trans.Z+50.0}, FC.GetTransform().Rotation]){}

    # Function to sort edge points by ID to ensure consistency
    SortEdgePoints(edge: tuple(Point, Point)): tuple(Point, Point) =
        if (edge(0).UUID.GetIntValue() < edge(1).UUID.GetIntValue()):
            return (edge(0), edge(1))
        else:
            return (edge(1), edge(0))

 
    #
    AStarAsync(MSTEdge: Edge, AStar: AStarV3, ?Final: logic = false)<suspends>: []creative_prop =
      
        var SelectedStartPoint: Point = MSTEdge.Point1
        var SelectedEndPoint: Point = MSTEdge.Point2

        PathResult := AStar.Search(
            SelectedStartPoint, SelectedEndPoint
        )
        var Props: []creative_prop = array{}
        if(Final = true):
            set OccupancyGrid = AStar.OccupancyGrid
            for(index->I: PathResult):
                Sleep(0.05)
                SpawnLocation := vector3{X := I.X * 500.0, Y := I.Y * 500.0, Z := FloorHeight *1000.0}
                set Props+= array{SpawnTarget(SpawnLocation, BossCube)}
        return Props

       

