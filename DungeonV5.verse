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
    var IsPlaced:logic=false
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
        # Try placing the room randomly until a valid spot is found
        var Tries:int=0
        loop:
            set Tries+=1

            if(FlooredMaxWidth:=Floor[maxWidth/TileSize]):
                if(FlooredMaxHeight:=Floor[maxHeight/TileSize]):
                    if(FlooredMaxDepth:=Floor[maxDepth/TileHeight]):
                        potentialX := GetRandomInt(1, FlooredMaxWidth - Width - 1)  # Avoid edges for boundary buffer
                        potentialY := GetRandomInt(1, FlooredMaxHeight - Height - 1)
                        potentialZ := GetRandomInt(0,  FlooredMaxDepth)  # Assuming floors start from 0
                        if( CheckRoomPlacement( potentialX, potentialY, potentialZ, Width, Height, Depth)=true):
                            set StartPoint.X = potentialX
                            set StartPoint.Y = potentialY
                            set StartPoint.Z = potentialZ
                            # Mark the grid as occupied
                            if(HalfWidth:=Floor[Width*1.0/2.0]):
                                if(HalfHeight:=Floor[Height*1.0/2.0]):
                                    if(HalfDepth:= Floor[Depth*1.0/2.0]):
                                        for (x:= potentialX-HalfWidth..potentialX + HalfWidth ):
                                            for (y := potentialY-HalfHeight..potentialY + HalfHeight ):
                                                for (z := potentialZ..potentialZ + Depth ):
                                                    if(set Parent.OccupancyGrid[x][y][z] = 1){}
                                                    SpawnTarget(vector3{X:= x * TileSize, Y:= y * TileSize, Z:= z * TileHeight},Parent.BossCube)
                            break
            if(Tries>10):
                break
            
    

    PlaceRandomlyOnFloor(maxWidth: float, maxHeight: float, FloorLevel:int)<suspends>: void =
        loop:
            if(potentialX := GetRandomInt(1, Floor[maxWidth/TileSize] - Width - 1),
            potentialY := GetRandomInt(1, Floor[maxHeight/TileSize] - Height - 1),
            potentialZ := FloorLevel):  # Assuming floors start from 0
                if (CheckRoomPlacement(potentialX, potentialY, potentialZ, Width, Height, Depth) = true):
                    set StartPoint = Point3D{X:=potentialX, Y:=potentialY, Z:=potentialZ}
                    MarkGridOccupied(potentialX, potentialY, potentialZ, Width, Height, Depth)
                    set IsPlaced=true
                    break

    RotateRandomly()<suspends>: void =
        if(set Rotation = array{0, 90, 180, 270}[GetRandomInt(0, 3)]){}
        # set Rotation =0

    RotateEntrance()<suspends>: void =
        if(IsPlaced = false):
            return
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
        if(IsPlaced = false):
            Print("Room not placed yet, cannot spawn")
            return
        # Convert grid position to world coordinates
        Location := vector3{X:= StartPoint.X * TileSize, Y:= StartPoint.Y * TileSize, Z:= StartPoint.Z * TileHeight}
        set RoomProp= SpawnTarget(Location, Asset.Asset)
        if(RoomProp.TeleportTo[Location,RoomProp.GetTransform().Rotation.ApplyYaw(DegreesToRadians(Rotation*1.0))]){}

    MarkEntrance(DebugProp:creative_prop_asset):void=
        if(IsPlaced = false):
            return
        # Convert grid position to world coordinates
        for(EntrancePoint:EntrancePoints):
            EntranceLocation := vector3{
                X:= (StartPoint.X + EntrancePoint.X) * TileSize,
                Y:= (StartPoint.Y + EntrancePoint.Y) * TileSize,
                Z:= (StartPoint.Z + EntrancePoint.Z) * TileHeight
            }        
            SpawnTarget(EntranceLocation, DebugProp)


    
    # Mark the grid as occupied
    MarkGridOccupied(x: int, y: int, z: int, width: int, height: int, depth: int): void =
        if(IsPlaced = false):
            return
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
    var GridDepth:int=0


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

    GroupEntrancesByHeight():[int][]tuple(RoomV5,Point3D)=
        var EntranceGroups:[int][]tuple(RoomV5,Point3D)=map{}
        for(room:RoomList):
            for(Entrance: room.EntrancePoints):
                if(not EntranceGroups[Entrance.Z]):
                    if(set EntranceGroups[Entrance.Z]=array{}){}
                if(set EntranceGroups[Entrance.Z] += array{(room, Entrance)}){}
        return EntranceGroups

    GetFloorGrid(depth: int): [][]int =
        var floorGrid: [][]int = array{}
        if(depth < 0 or depth >= GridHeight):
            Print("Requested depth {depth} out of bounds.")
            return floorGrid  # Return empty array if out of bounds

        for (x := 0 .. GridWidth - 1):
            set floorGrid += array{array{}}
            for (y := 0 .. GridHeight - 1):
                if(set floorGrid[x] += array{OccupancyGrid[x][y][depth]}){}
        return floorGrid

    PathFindFloors()<suspends>:void=
        Print("Pathfinding floors")
        GroupedPoints:=GroupEntrancesByHeight()
        for(Key->Value:GroupedPoints):
            Print("Grouped Points {Key}: {Value.Length}")
        for(I->grouped:GroupedPoints):
            Print("Grouped Points {I}: {grouped.Length}")
            InitPathFinding(I, grouped)


        Print("done pathfinding floors")

    InitPathFinding(Level:int, Points:[]tuple(RoomV5,Point3D))<suspends>:void=
        var RoomEntryPoints: []Point = array{}
        
        for(RoomTuple:Points):
            EntranceLocation := CreatePoint(RoomTuple(0).StartPoint.X +RoomTuple(1).X, RoomTuple(0).StartPoint.Y + RoomTuple(1).Y)
            Print("EntranceLocation {EntranceLocation.X} {EntranceLocation.Y}")
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
        var SlicedGrid:[][]int=GetFloorGrid(Level)
        AStar3 := AStarV3{OccupancyGrid:= SlicedGrid, DebugCube:= DebugCube, FinalCube:=BossCube}
        AStar3.Init(SlicedGrid)

        var AIndex2:int = 0
        
        var AllProps: []creative_prop = array{}      
        loop:
            Print("AIndex2: {AIndex2}")
            if(MSTEdge:=MSTEdges[AIndex2]):
                Res:=AStarAsync(MSTEdge, AStar3,SlicedGrid,Level, ?Final:=true)
                set AllProps += Res(0)
                set SlicedGrid = Res(1)
                Print("Props: {AllProps.Length}")
                
            set AIndex2+=1

            if(AIndex2>= MSTEdges.Length):
                break

        # for(prop:AllProps):
        #     prop.Dispose()
       
        set SlicedGrid = AStar3.OccupancyGrid
        for(room:RoomList):
            for(EntrancePoint:room.EntrancePoints):
                if(set SlicedGrid[room.StartPoint.X+EntrancePoint.X][room.StartPoint.Y+EntrancePoint.Y] = 3){}
            
        for(X:SlicedGrid):
            var arr:string = ""
            for(Y:X):
                set arr += "{Y} "
            Print("{arr}")
                
        # MergeParallelCorridors()

        tilemappingV5 := TileMapV5{GridSlice:=SlicedGrid}
        FinalTiles:= tilemappingV5.GenerateTileMapping(SlicedGrid)

        # for(IndexI->I:FinalTiles):
        #     var PrintRow : string = ""

        #     for(IndexJ->J:I):
        #         tileType := J(0)
        #         rot := J(1)
        #         SpawnLocation := vector3{X := IndexI * 500.0, Y := IndexJ * 500.0, Z := Level*1000.0}

        #         set PrintRow+= "{J(0)}"
        #         case(J(0)):
        #             "C" => {
        #                 Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_FLOOR_PROP)
        #                 Sleep(0.04)
        #                 if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
        #             }
        #             "X" => {
        #                 Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_CROSSING_PROP)
        #                 Sleep(0.04)
        #                 if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
        #             }
        #             "CC" => {
        #                 Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_CORNER_PROP)
        #                 Sleep(0.04)
        #                 if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
        #             }
        #             "CT" => {
        #                 Print("TPoint")
        #                 Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_TPOINT_PROP)
        #                 Sleep(0.04)
        #                 if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
        #             }
        #             _=>{}
        #     Print("{PrintRow}")

        for(Player:Parent.GetPlayspace().GetPlayers()):
            if(FC:=Player.GetFortCharacter[], StartRoom:=RoomList[0]):
                Sleep(0.1)
                Trans:=StartRoom.RoomProp.GetTransform().Translation
                if(FC.TeleportTo[vector3{X:=Trans.X, Y:=Trans.Y, Z:=Trans.Z+50.0}, FC.GetTransform().Rotation]){}

    # Function to sort edge points by ID to ensure consistency
    SortEdgePoints(edge: tuple(Point, Point)): tuple(Point, Point) =
        if (edge(0).UUID.GetIntValue() < edge(1).UUID.GetIntValue()):
            return (edge(0), edge(1))
        else:
            return (edge(1), edge(0))

 
    #
    AStarAsync(MSTEdge: Edge, AStar: AStarV3, SLicedGrid:[][]int,Level:int, ?Final: logic = false)<suspends>: tuple([]creative_prop,[][]int ) =
        var NewSlicedGrid: [][]int = array{}
        var SelectedStartPoint: Point = MSTEdge.Point1
        var SelectedEndPoint: Point = MSTEdge.Point2
        Print("start search start {SelectedStartPoint.X} {SelectedStartPoint.Y} end {SelectedEndPoint.X} {SelectedEndPoint.Y}")
        PathResult := AStar.Search(
            SelectedStartPoint, SelectedEndPoint
        )
        Print("end search")
        var Props: []creative_prop = array{}
        if(Final = true):
            set NewSlicedGrid = AStar.OccupancyGrid
            for(index->I: PathResult):
                Sleep(0.05)
                SpawnLocation := vector3{X := I.X * 500.0, Y := I.Y * 500.0, Z := Level * 1000.0}
                set Props+= array{SpawnTarget(SpawnLocation, BossCube)}
        return (Props,NewSlicedGrid)