using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }

# Function to create a room
CreateRoomV2(X:int, Y:int, Width:int, Height:int, Type:string, Parent:DungeonV2)<suspends>: RoomV2 =
    # Implementation to initialize a room
    room:=  RoomV2{X:=X, Y:=Y, Width:=Width, Height:=Height, Type:=Type, ID:=GenerateUUID(), Parent:=Parent}
    room.Init()
    return room

CreateDungeonV2(PreferredRooms:int, MinRoomSize:int, MaxRoomSize:int, MinBuffer:int, CombatCube : creative_prop_asset, LinePropAsset:creative_prop_asset, BossCube:creative_prop_asset,DebugCube:creative_prop_asset,    
DebugLinePropAsset: creative_prop_asset,     AStarLinePropAsset:creative_prop_asset
): DungeonV2 =
    # Implementation to create a dungeon
    dungeon:= DungeonV2{Width:=75, Height:=75, PreferedRooms:=PreferredRooms, CombatCube:=CombatCube, 
    LinePropAsset:=LinePropAsset, BossCube:=BossCube, DebugCube:=DebugCube, DebugLinePropAsset:=DebugLinePropAsset, AStarLinePropAsset:=AStarLinePropAsset}
    spawn. dungeon.Generate(MinRoomSize, MaxRoomSize, MinBuffer)
    return dungeon


# Function to draw a line between any two grid points
DrawGridLine(Start: Point, End: Point, LineProp: creative_prop_asset, ParentDungeon:DungeonV2, ?Z:float=50.0, ?Value:int=1, ?ShouldSpawn:logic=true)<suspends>: void=
    # Creating local copies of Start and End to avoid modifying the original points
    var LocalStart: Point = Start
    var LocalEnd: Point = End
    dx := Abs(LocalEnd.X - LocalStart.X)
    dy := -Abs(LocalEnd.Y - LocalStart.Y)
    var sx:int = 0
    var sy:int = 0
    if(Start.X < End.X):
        set sx = 1
    else:
        set sx = -1

    if(Start.Y < End.Y):
        set sy = 1
    else:
        set sy = -1
    var err: int = dx + dy

    loop:
        # Calculate spawn location based on the current LocalStart position
        SpawnLocation := vector3{X:=LocalStart.X * 100.0, Y:=LocalStart.Y * 100.0, Z:=Z}
        Scale := vector3{X:=1.0, Y:=1.0, Z:=1.0}
        if(ParentDungeon.OccupancyGrid[LocalStart.X][LocalStart.Y] = 0 or ParentDungeon.OccupancyGrid[LocalStart.X][LocalStart.Y] = 9 or ParentDungeon.OccupancyGrid[LocalStart.X][LocalStart.Y] = 1 ):
            if(ShouldSpawn=true):
                Sleep(1.0/26.0)
                Prop := SpawnTarget(SpawnLocation, LineProp, ?Scale:=Scale)
            if(set ParentDungeon.OccupancyGrid[LocalStart.X][LocalStart.Y] = Value){}
        if (LocalStart.X = LocalEnd.X and LocalStart.Y = LocalEnd.Y):
            break
        var e2 :int= 2 * err
        if (e2 >= dy): # e_xy+e_x > 0
            set err += dy
            set LocalStart.X += sx
        if (e2 <= dx): # e_xy+e_y < 0
            set err += dx
            set LocalStart.Y += sy


RoomV2 := class():
    # Unique identifier for the room
    var ID: string 

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
    
    # Properties for the room like 'hasTreasure', 'hasEnemies', etc.
    var Properties: [string]logic = map{}

    var Props: []creative_prop = array{}
    Parent: DungeonV2

    var MiddleLocation: vector3 = vector3{X:=0.0, Y:=0.0, Z:=0.0}

    var ConnectX:int =0
    var ConnectY:int =0
    Init()<suspends>:void=
        for(i := 0..Width):
            for(j := 0..Height):
                Sleep(0.003)
                # Print("Spawning tile at {X*1.0+i*100.0}, {Y*1.0+j*100.0}, 50.0")
                Spawn:= vector3{X:=(X+i)*100.0, Y:=(Y+j)*100.0, Z:=50.0}
                # Spawn a floor tile at the given position
                Prop:=SpawnTarget(Spawn, Parent.CombatCube)
                set Props += array{Prop}

        # Calculate the middle location of the room
        set MiddleLocation = vector3{X:=(X*1.0 + Width*1.0 / 2.0) * 100.0, Y:= Y*100.0, Z:=50.0}
        if(set ConnectX = X + Floor(Width/2)){}
        set ConnectY = Y


        # Implementation to initialize the room

    
        

DungeonV2 := class():
    CombatCube: creative_prop_asset 
    LinePropAsset : creative_prop_asset
    BossCube : creative_prop_asset
    DebugCube: creative_prop_asset
    DebugLinePropAsset: creative_prop_asset
    AStarLinePropAsset:creative_prop_asset
    var OccupancyGrid: [][]int = array{}

    # List of all rooms in the dungeon
    var Rooms: []RoomV2 = array{}
    
    # Dungeon width and height for boundary checks
    var Width:int
    var Height:int

    PreferedRooms:int
    # Function to sort edge points by ID to ensure consistency
    SortEdgePoints(edge: tuple(Point, Point)): tuple(Point, Point) =
        if (edge(0).UUID.GetIntValue() < edge(1).UUID.GetIntValue()):
            return (edge(0), edge(1))
        else:
            return (edge(1), edge(0))

    # Function to calculate the midpoints of rooms and triangulate them
    TriangulateRooms()<suspends>: void =
        # Collect the midpoint of each room in the dungeon
        var Points: []Point = array{}
        for(room :Rooms):
            Location:= vector2{X:=room.MiddleLocation.X, Y:=room.MiddleLocation.Y}
            set Points += array{CreatePoint(room.ConnectX, room.ConnectY)}
            SpawnTarget(vector3{X:=Location.X, Y:=Location.Y, Z:=100.0},BossCube)

        # Initialize the Delaunay triangulation with these points
        Triangulation := DelaunayTriangulation{LinePropAsset:= LinePropAsset, BossCube:=BossCube}  # Ensure LinePropAsset is defined or passed appropriately
        StartingTriangles:= Triangulation.Initialize(Points)

        # Perform the triangulation
        Triangles := Triangulation.Triangulate(Points)

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

        # Create a minimum spanning tree from the triangulation
        var MST :[]Edge= KruskalMST(Points, Edges)  # Ensure LinePropAsset is defined or passed appropriately 
        Print("edges: {Edges.Length}, mst: {MST.Length}")       
        var MSTMap: [string]logic = map{}
        for(edge : MST):
            MSTKey := "{edge.Point1.UUID}-{edge.Point2.UUID}"
            if(set MSTMap[MSTKey] = true,
            set MSTMap["{edge.Point2.UUID}-{edge.Point1.UUID}"] = true){}  # For undirected edges


        for(Key->Value : UniqueEdges):
            if (not MSTMap[Key]):  # Check if the edge is not in the MST
                if (GetRandomFloat(0.0,1.0) < 0.125):
                    set MST += array{CreateEdge(Value(0), Value(1))}

        Print("total mst with random edges: {MST.Length}")
        for(edge:MST):
            Print("Drawing MST")
            DrawGridLine(edge.Point1, edge.Point2, DebugLinePropAsset, Self, ?Z:=75.0)


        
        # pathfinder := AStarContinuous{GridWidth:=Width, GridHeight:=Height, DebugCube:=BossCube}
        # var Buffer:int = 0
        # for(I:OccupancyGrid):
        #     for(J:I):
        #         if(J = 9):
        #             set Buffer+=1
        # Print("Buffer tiles left: {Buffer}")
        # pathfinder.Init(MST, OccupancyGrid)
        # Print("Pathfinder initialized")
        # Print("Points: {Points.Length}")
        # for(I:= 0.. Points.Length-1):

        # # Assuming start and goal are defined, for example:
        # for (edge : MST):
        #     start_room_center := edge.Point1  # Assume Points is a list of room center positions indexed by point IDs
        #     end_room_center := edge.Point2

        #         # Perform A* search between the centers of the connected rooms
        #         path := pathfinder.Search(start_room_center, end_room_center)
        #         for(point:path(0)):
        #             Print("Path point: {point.X}, {point.Y}")

        #         # Draw the path using a corridor visual
        #         if (path(0).Length>0):
        #             var last_point :Point= start_room_center
        #             for (point : path(0)):
        #                 DrawGridLine(last_point, point, LinePropAsset, Self, ?Z:=50.0, ?Value:=3)  # Assume LinePropAsset is suitable for corridors
        #                 set last_point = point
        #             DrawGridLine(last_point, end_room_center, LinePropAsset, Self, ?Z:=50.0, ?Value:=3)

       



    # Function to add a room to the dungeon
    AddRoom(room:RoomV2): void =
        set Rooms += array{room}

    # Helper function to calculate density of a proposed room area
    CalculateAreaDensity(X: int, Y: int, RoomWidth: int, RoomHeight: int): int =
        var count: int = 0
        for (x := X - 4 .. X + RoomWidth + 4):
            for (y := Y - 4 .. Y + RoomHeight + 4):
                if (x >= 0 and x < Width and y >= 0 and y < Height):
                    if (OccupancyGrid[x][y]= 1):
                        set count += 1
        return count

    # Function to generate the dungeon
    Generate( MinRoomSize:int, MaxRoomSize:int, MinBuffer:int)<suspends>: void =
        InitOccupancyGrid()
        var RoomsCreated:int = 0

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
                if(attempts > 100):
                    break
                set attempts += 1
                set RoomX = GetRandomInt(5, Width - RoomWidth-2)
                set RoomY = GetRandomInt(5, Height - RoomHeight-2)

                if(IsAreaFree(RoomX, RoomY, RoomWidth, RoomHeight, MinBuffer) = true):
                    set FoundSpot = true
                    break

            if(FoundSpot= true):
                var NewRoom:RoomV2 = CreateRoomV2(RoomX, RoomY, RoomWidth, RoomHeight, "normal", Self)
                if(HalfBuffer:=Floor(MinBuffer/2)):
                    MarkAreaOccupied(RoomX, RoomY, RoomWidth, RoomHeight,HalfBuffer, 5)
                    AddRoom(NewRoom)
                    set RoomsCreated += 1
            else:
                Print("No more space available for new rooms.")
                break

        Print("Dungeon generation complete. Created {RoomsCreated} rooms. Starting triangulation.")
        for(indexI->I:OccupancyGrid):
            for(indexJ->J:I):
                if(J = 9):
                    if(set OccupancyGrid[indexI][indexJ]= 0){}

        for(room:Rooms):
            Print("Room {room.ID} at {room.X}, {room.Y} with width {room.Width} and height {room.Height}.")
        TriangulateRooms()
        Print("Triangulation complete.")

        

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
                    Print("Area is not free at {x}, {y}")
                    return false  # The area is not free
        return true  # The area is free


        
     # Marks the specified area as occupied
    MarkAreaOccupied(X:int, Y:int, _Width:int, _Height:int, HalfBuffer:int, Value: int): void =
        for (x := X-HalfBuffer..X + _Width+HalfBuffer):
            for (y := Y-HalfBuffer..Y + _Height+HalfBuffer):
                
                if(set OccupancyGrid[x][y] = 9){}

        for(x:=X..X+_Width):
            for(y:=Y..Y+_Height):
                if(set OccupancyGrid[x][y] = Value){}
                # # Calculate position for each grid cell
                # Spawn:= vector3{X:=x*100.0, Y:=y*100.0, Z:=75.0}  # Adjusted to use x and y
                # # Spawn a transparent debug cube at calculated position
                # # Prop:=SpawnTarget(Spawn, DebugCube)

