using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }


CreateRoomV3(
    X:int, Y:int, Width:int, Height:int, Type:string, Parent:DungeonV3,
    TILE_ROOM_FLOOR_PROP : creative_prop_asset,
    TILE_ROOM_WALL_PROP : creative_prop_asset,
    TILE_WALL_CORNER_PROP : creative_prop_asset,
    TILE_CORRIDOR_FLOOR_PROP : creative_prop_asset,
    TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset,
    TILE_CORRIDOR_ENTRANCE_PROP : creative_prop_asset
    )<suspends>: RoomV3 =
        # Implementation to initialize a room
        room:=  RoomV3{X:=X, Y:=Y, Width:=Width, Height:=Height, Type:=Type, UUID:=GenerateUUID(), Parent:=Parent, TILE_ROOM_FLOOR_PROP:=TILE_ROOM_FLOOR_PROP, TILE_ROOM_WALL_PROP:=TILE_ROOM_WALL_PROP, TILE_WALL_CORNER_PROP:=TILE_WALL_CORNER_PROP, TILE_CORRIDOR_FLOOR_PROP:=TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP:=TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_ENTRANCE_PROP:=TILE_CORRIDOR_ENTRANCE_PROP}
        room.Init()
        return room

CreateDungeonV3(PreferredRooms:int, MinRoomSize:int, MaxRoomSize:int, MinBuffer:int, CombatCube : creative_prop_asset, LinePropAsset:creative_prop_asset, BossCube:creative_prop_asset,DebugCube:creative_prop_asset,    
DebugLinePropAsset: creative_prop_asset,     AStarLinePropAsset:creative_prop_asset, PropSize:float,
TILE_ROOM_FLOOR_PROP : creative_prop_asset,
TILE_ROOM_WALL_PROP : creative_prop_asset,
TILE_WALL_CORNER_PROP : creative_prop_asset,
TILE_CORRIDOR_FLOOR_PROP : creative_prop_asset,
TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset,
TILE_CORRIDOR_ENTRANCE_PROP : creative_prop_asset,
TILE_CORRIDOR_CORNER_PROP: creative_prop_asset,
TILE_CORRIDOR_TPOINT_PROP: creative_prop_asset

): DungeonV3 =
    # Implementation to create a dungeon
    dungeon:= DungeonV3{Width:=30, Height:=30, PreferedRooms:=PreferredRooms, CombatCube:=CombatCube, 
    LinePropAsset:=LinePropAsset, BossCube:=BossCube, DebugCube:=DebugCube, DebugLinePropAsset:=DebugLinePropAsset, AStarLinePropAsset:=AStarLinePropAsset, PropSize:=PropSize,
    TILE_ROOM_FLOOR_PROP:=TILE_ROOM_FLOOR_PROP, TILE_ROOM_WALL_PROP:=TILE_ROOM_WALL_PROP, TILE_WALL_CORNER_PROP:=TILE_WALL_CORNER_PROP, TILE_CORRIDOR_FLOOR_PROP:=TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP:=TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_ENTRANCE_PROP:=TILE_CORRIDOR_ENTRANCE_PROP, TILE_CORRIDOR_CORNER_PROP:=TILE_CORRIDOR_CORNER_PROP, TILE_CORRIDOR_TPOINT_PROP:=TILE_CORRIDOR_TPOINT_PROP}
    spawn. dungeon.Generate(MinRoomSize, MaxRoomSize, MinBuffer)
    return dungeon

RoomV3:=class:
    TILE_ROOM_FLOOR_PROP : creative_prop_asset
    TILE_ROOM_WALL_PROP : creative_prop_asset
    TILE_WALL_CORNER_PROP : creative_prop_asset
    TILE_CORRIDOR_FLOOR_PROP : creative_prop_asset
    TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset
    TILE_CORRIDOR_ENTRANCE_PROP : creative_prop_asset
    # Unique identifier for the room
    var UUID: string 
    # Position of the room on the dungeon grid
    var X:int
    var Y:int
    
    # Width and Height for non-square rooms
    var Width:int
    var Height:int
    
    # A list of connections to other rooms
    var Connections: []RoomV2 = array{}
    
    # Room type could be 'normal', 'entrance', 'boss', etc.
    var Type: string 
    

    var Props: []creative_prop = array{}
    Parent: DungeonV3

    Init()<suspends>:void=
        for(i := 0..Width-1):
            for(j := 0..Height-1):
                # Print("Spawning tile at {X*1.0+i*100.0}, {Y*1.0+j*100.0}, 50.0")
                Spawn:= vector3{X:=(X+i)*Parent.PropSize, Y:=(Y+j)*Parent.PropSize, Z:=50.0}
                # Spawn a floor tile at the given position
                Prop:=SpawnTarget(Spawn, Parent.CombatCube)
                set Props += array{Prop}

     


        # Implementation to initialize the room




            
DungeonV3:= class:
    TILE_ROOM_FLOOR_PROP : creative_prop_asset
    TILE_ROOM_WALL_PROP : creative_prop_asset
    TILE_WALL_CORNER_PROP : creative_prop_asset
    TILE_CORRIDOR_FLOOR_PROP : creative_prop_asset
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

    # List of all rooms in the dungeon
    var Rooms: []RoomV3 = array{}
    
    # Dungeon width and height for boundary checks
    var Width:int
    var Height:int

    PreferedRooms:int

     # Function to add a room to the dungeon
     AddRoom(room:RoomV3): void =
        set Rooms += array{room}

    #
    # Function to sort edge points by ID to ensure consistency
    SortEdgePoints(edge: tuple(Point, Point)): tuple(Point, Point) =
        if (edge(0).UUID.GetIntValue() < edge(1).UUID.GetIntValue()):
            return (edge(0), edge(1))
        else:
            return (edge(1), edge(0))

    # Function to generate the dungeon
    Generate( MinRoomSize:int, MaxRoomSize:int, MinBuffer:int)<suspends>: void =
        InitOccupancyGrid()
        var RoomsCreated:int = 0
        var Fails:int = 0
        loop:
            Print("Creating room {RoomsCreated+1}")
            if(RoomsCreated >=PreferedRooms):
                break

            var RoomWidth:int = GetRandomInt(MinRoomSize, MaxRoomSize)
            var RoomHeight:int = GetRandomInt(MinRoomSize, MaxRoomSize)

            # Find an unoccupied spot
            var FoundSpot:logic = false
            var RoomX:int = -1
            var RoomY:int = -1

            # Limit attempts to avoid an infinite loop if there's no space
            var attempts:int = 0
            loop :
                if(attempts > 400):
                    break
                set attempts += 1
                set RoomX = GetRandomInt(2, Width - RoomWidth-2)
                set RoomY = GetRandomInt(2, Height - RoomHeight-2)

                if(IsAreaFree(RoomX, RoomY, RoomWidth, RoomHeight, MinBuffer) = true):
                    set FoundSpot = true
                    break

            if(FoundSpot= true):
                var NewRoom:RoomV3 = CreateRoomV3(RoomX, RoomY, RoomWidth, RoomHeight, "normal", Self, TILE_ROOM_FLOOR_PROP, TILE_ROOM_WALL_PROP, TILE_WALL_CORNER_PROP, TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_ENTRANCE_PROP)
                if(HalfBuffer:=Floor(MinBuffer/2)):
                    MarkAreaOccupied(RoomX, RoomY, RoomWidth, RoomHeight,HalfBuffer, 15)

                    AddRoom(NewRoom)
                    set RoomsCreated += 1
            else:
                Print("No more space available for new rooms.")
                set Fails+=1
                if(Fails>10):
                    break

        Print("Dungeon generation complete. Created {RoomsCreated} rooms. Starting triangulation.")
        

        #astar
        AStar := AStarV2{OccupancyGrid:= OccupancyGrid, DebugCube:= DebugCube, FinalCube:=BossCube}
        AStar.Init(OccupancyGrid)

        # Prepare room entry points for MST
        var RoomEntryPoints: []Point = array{}
        var RoomPairs: []tuple(Point, Point) = array{}

        for(room : Rooms):
            if(EntryPoint := CreatePoint(room.X , room.Y + Floor(room.Height / 2) )):
                SpawnTarget(vector3{X:=EntryPoint.X*PropSize, Y:=EntryPoint.Y*PropSize, Z:=85.0}, DebugCube)
                set RoomEntryPoints += array{EntryPoint}

       

        ###
        # Initialize the Delaunay triangulation with these points
        Triangulation := DelaunayTriangulation{LinePropAsset:= LinePropAsset, BossCube:=BossCube}  # Ensure LinePropAsset is defined or passed appropriately
        StartingTriangles:= Triangulation.Initialize(RoomEntryPoints)

        # Perform the triangulation
        Triangles := Triangulation.Triangulate(RoomEntryPoints)

        var Edges: []tuple(Point,Point) = array{}
        for(triangle :Triangles):
            for(edge:triangle.Edges):
                set Edges += array{edge}

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

        

        #
         # Create all pairs for MST edges
         for(i := 0 .. RoomEntryPoints.Length - 1):
            for(j := i + 1 .. RoomEntryPoints.Length - 1):
                if(set RoomPairs += array{(RoomEntryPoints[i], RoomEntryPoints[j])}){}
                
        # Apply Kruskal's MST algorithm to connect all rooms
        var MSTEdges: []Edge = KruskalMST(RoomEntryPoints, Edges)
        Print("total mst edges: {MSTEdges.Length}")
        var MSTMap: [string]logic = map{}
        for(edge : MSTEdges):
            MSTKey := "{edge.Point1.UUID}-{edge.Point2.UUID}"
            if(set MSTMap[MSTKey] = true,
            set MSTMap["{edge.Point2.UUID}-{edge.Point1.UUID}"] = true){}  # For undirected edges


        # Connect rooms using A*
        Print("total mst edges with random: {MSTEdges.Length}")

        # var AIndex:int = 0
        

        # loop:
        #     if(MSTEdge:=MSTEdges[AIndex]):
        #         spawn. AStarAsync(MSTEdge, AStar)
        #     if(MSTEdge:=MSTEdges[AIndex+1]):
        #         spawn. AStarAsync(MSTEdge, AStar)
        #     if(MSTEdge:=MSTEdges[AIndex+2]):
        #         AStarAsync(MSTEdge, AStar)
                
        #     set AIndex+=3

        #     if(AIndex>= MSTEdges.Length):
        #         break

        # Sleep(4.0)
        # Print("All rooms connected successfully.")
        # set OccupancyGrid = AStar.OccupancyGrid
        #astar
        AStar2 := AStarV2{OccupancyGrid:= OccupancyGrid, DebugCube:= DebugCube, FinalCube:=BossCube}
        AStar2.Init(OccupancyGrid)

        var AIndex2:int = 0
        

        loop:
            if(MSTEdge:=MSTEdges[AIndex2]):
                AStarAsync(MSTEdge, AStar2, ?Final:=true)
                
            set AIndex2+=1

            if(AIndex2>= MSTEdges.Length):
                break

       
        set OccupancyGrid = AStar2.OccupancyGrid
        # MergeParallelCorridors()

        for(edge: MSTEdges):
            if(set OccupancyGrid[edge.Point1.X][edge.Point1.Y] = 1){}
            if(set OccupancyGrid[edge.Point2.X][edge.Point2.Y] = 1){}

            
        var OccupancyMap: [string]int = map{}
        for(I:OccupancyGrid):
            for(J:I):
                if(not OccupancyMap["{J}"]):
                    if(set OccupancyMap["{J}"] = 1){}
                else:
                    if(set OccupancyMap["{J}"] += 1){}

        for(K->V:OccupancyMap):
            Print("OccupancyMap {K} : {V}")

        #tilemapping
        tileMap := TileMap{ParentDungeon := Self, NorthProp:=CombatCube, EastProp:=BossCube, WestProp:=DebugCube}
        FinalTiles := tileMap.GenerateTileMapping(OccupancyGrid)

        for(I:FinalTiles):
            var PrintRow : string = ""
            for(J:I):
                if(J(0).Length = 1):
                    set PrintRow+= "{J(0)} "
                else:
                    set PrintRow+= "{J(0)}"
            Print("{PrintRow}")

        Print("\n\n")
        var TypeMap : [string]int = map{}
       

        for(IndexI -> I: FinalTiles):
            for(IndexJ -> J: I):
                tileType := J(0)
                rot := J(1)
                SpawnLocation := vector3{X := IndexI * PropSize, Y := IndexJ * PropSize, Z := 50.0}
                if(not TypeMap[tileType]):
                    if(set TypeMap[tileType] = 1){}
                else:
                    if(set TypeMap[tileType] += 1){}
                case(tileType):
                    "F" => {
                        Prop := SpawnTarget(SpawnLocation, TILE_ROOM_FLOOR_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
                    }
                    "W" => {
                        R := tileMap.GetWallRotation(IndexI, IndexJ)
                        Prop := SpawnTarget(SpawnLocation, TILE_ROOM_WALL_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(R * 1.0))]){}
                    }
                    "WC" => {
                        Prop := SpawnTarget(SpawnLocation, TILE_WALL_CORNER_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
                    }
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
                    "E" => {
                        Prop := SpawnTarget(SpawnLocation, TILE_CORRIDOR_ENTRANCE_PROP)
                        Sleep(0.04)
                        if(Prop.TeleportTo[SpawnLocation, Prop.GetTransform().Rotation.ApplyYaw(DegreesToRadians(rot * 1.0))]){}
                    }
                    _ =>
            
        
                
       
    IsCorridor(x: int, y: int)<transacts>: logic =
        if(OccupancyGrid[x][y] = 2):
            return true
        return false

    
        
    AStarAsync(MSTEdge: Edge, AStar: AStarV2, ?Final: logic = false)<suspends>: void =
        StartRoom := FindRoomContainingPoint(MSTEdge.Point1)
        EndRoom := FindRoomContainingPoint(MSTEdge.Point2)

        var SelectedStartPoint: Point = MSTEdge.Point1
        var SelectedEndPoint: Point = MSTEdge.Point2

        PathResult := AStar.Search(
            SelectedStartPoint, SelectedEndPoint,
            StartRoom.X, StartRoom.Y, StartRoom.Width, StartRoom.Height,
            EndRoom.X, EndRoom.Y, EndRoom.Width, EndRoom.Height
        )

        if(Final = true):
            for(index->I: PathResult(0)):
                SpawnLocation := vector3{X := I.X * PropSize, Y := I.Y * PropSize, Z := 75.0}
                SpawnTarget(SpawnLocation, BossCube)

       
    
    #
    FindRoomContainingPoint(point: Point): RoomV3=
        for(room : Rooms):
            Print("Room {room.UUID} {room.X} {room.Y} {room.Width} {room.Height} point {point.X} {point.Y}")
            if(point.X >= room.X and point.X < room.X + room.Width and point.Y >= room.Y and point.Y < room.Y + room.Height):
                Print("Found room {room.UUID} {room.X} {room.Y}")
                return room

        Print("Room not found for point {point.X} {point.Y}")
        return RoomV3{ X:=-1, Y:=-1, Width:=0, Height:=0, Type:="nil", Parent:=Self, UUID:="",TILE_ROOM_FLOOR_PROP:=TILE_ROOM_FLOOR_PROP, TILE_ROOM_WALL_PROP:=TILE_ROOM_WALL_PROP, TILE_WALL_CORNER_PROP:=TILE_WALL_CORNER_PROP, TILE_CORRIDOR_FLOOR_PROP:=TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP:=TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_ENTRANCE_PROP:=TILE_CORRIDOR_ENTRANCE_PROP }  # Return an empty room if not found        

    # Any additional functions needed for triangulation, MST, etc.
    InitOccupancyGrid(): void =
        for(I:=0..Width-1):
            set OccupancyGrid+= array{array{}}
            for(J:=0..Height-1):
                if(set OccupancyGrid[I] += array{0}){}
        W:= OccupancyGrid.Length
        Print("WIshto{W}")        
        if( H:= OccupancyGrid[0].Length) :      
            Print("Occupancy grid initialized with {W}x{H} dimensions.")

    # Checks if the specified area is free
    IsAreaFree(X:int, Y:int, _Width:int, _Height:int, Buffer:int)<transacts>: logic =
        # Adjust the bounds to include the buffer space
        StartX := Max(0, X - Buffer)
        EndX := Min(X + _Width + Buffer, Width)  # Ensure it doesn't go out of the grid boundaries
        StartY := Max(0, Y - Buffer)
        EndY := Min(Y + _Height + Buffer, Height)  # Ensure it doesn't go out of the grid boundaries

        # Iterate over the adjusted area to check for free space
        for (x := StartX .. EndX - 1):
            for (y := StartY .. EndY - 1):
                if (not OccupancyGrid[x][y] = 0):
                    return false  # The area is not free
        return true  # The area is free


        
     # Marks the specified area as occupied
    MarkAreaOccupied(X: int, Y: int, _Width: int, _Height: int, HalfBuffer: int, Value: int): void=
        # Mark the buffer zone around the room with `9`
        # for (x := Max(0, X - HalfBuffer) .. Min(X + _Width + HalfBuffer, Width) - 1):
        #     for (y := Max(0, Y - HalfBuffer) .. Min(Y + _Height + HalfBuffer, Height) - 1):
        #         if (set OccupancyGrid[x][y] = 9) {}
        #         # SpawnTarget(vector3{X := x * PropSize, Y := y * PropSize, Z := 450.0}, DebugCube)
    
        # Mark the inner room area with the specified `Value`
        for (x := X-1 .. X + _Width ):
            for (y := Y -1.. Y + _Height ):
                if (set OccupancyGrid[x][y] = Value) {}
                # SpawnTarget(vector3{X := x * PropSize, Y := y * PropSize, Z := 400.0}, CombatCube)

    
        # Mark corners specifically with `900`
        if (_Width > 1 and _Height > 1):
            # Bottom-left corner
            if (X >= 0 and Y >= 0, set OccupancyGrid[X-1][Y-1] = 90000000):
                SpawnTarget(vector3{X := (X-1)* PropSize, Y := (Y-1) * PropSize, Z := 400.0}, DebugCube)
            # Bottom-right corner
            if (X + _Width - 1 < Width and Y >= 0 , set OccupancyGrid[X + _Width ][Y-1] = 90000000):
                # SpawnTarget(vector3{X := (X + _Width ) * PropSize, Y := (Y-1) * PropSize, Z := 400.0}, CombatCube)
            # Top-left corner
            if (X >= 0 and Y + _Height + 1 < Height , set OccupancyGrid[X-1][Y + _Height ] = 90000000):
                SpawnTarget(vector3{X := (X-1) * PropSize, Y := (Y + _Height ) * PropSize, Z := 400.0}, BossCube)
            # Top-right corner
            if (X + _Width + 1 < Width and Y + _Height + 1 < Height , set OccupancyGrid[X + _Width ][Y + _Height ] = 90000000):
                SpawnTarget(vector3{X := (X + _Width ) * PropSize, Y := (Y + _Height ) * PropSize, Z := 400.0}, CombatCube)