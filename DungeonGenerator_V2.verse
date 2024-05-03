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

CreateDungeonV2(PreferredRooms:int, MinRoomSize:int, MaxRoomSize:int, MinBuffer:int, CombatCube : creative_prop_asset, LinePropAsset:creative_prop_asset, BossCube:creative_prop_asset,DebugCube:creative_prop_asset,    DebugLinePropAsset: creative_prop_asset
): DungeonV2 =
    # Implementation to create a dungeon
    dungeon:= DungeonV2{Width:=100, Height:=100, PreferedRooms:=PreferredRooms, CombatCube:=CombatCube, LinePropAsset:=LinePropAsset, BossCube:=BossCube, DebugCube:=DebugCube, DebugLinePropAsset:=DebugLinePropAsset}
    spawn. dungeon.Generate(MinRoomSize, MaxRoomSize, MinBuffer)
    return dungeon


 # Helper function to draw a line between two points using a specified prop asset
DrawLine(Start: Point, End: Point, LineProp: creative_prop_asset)<suspends>: void=
    # Calculate midpoint for the line prop
    MidPointX := (Start.X + End.X) / 2.0
    MidPointY := (Start.Y + End.Y) / 2.0
    MidPointZ := 50.0  # Assuming a fixed height above ground
    SpawnLocation := vector3{X:=MidPointX, Y:=MidPointY, Z:=MidPointZ}

    # Calculate the distance between the points to set the scale of the line prop
    LineLength := Sqrt(Pow(Abs(End.X - Start.X), 2.0) + Pow(Abs(End.Y - Start.Y), 2.0))
    
    
    var Scale :vector3= vector3{X:=LineLength / 40.0, Y:=0.1, Z:=0.1}  # Adjust Y and Z for thickness
    if(LineLength>0.1):

        # Calculate the angle to rotate the line prop
        Angle := ArcTan(End.Y - Start.Y, End.X - Start.X)
        Rotation := MakeRotationFromYawPitchRollDegrees( RadiansToDegrees(Angle), 0.0, 0.0)

        # Spawn the line prop at the calculated location with the appropriate rotation and scale
        Prop := SpawnTarget(SpawnLocation, LineProp, ?Scale := Scale)
        Sleep(0.005)
        if(Prop.TeleportTo[SpawnLocation,Prop.GetTransform().Rotation.ApplyYaw(Angle)]){}    
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
        set MiddleLocation = vector3{X:=(X*1.0 + Width*1.0 / 2.0) * 100.0, Y:=(Y*1.0 + Height*1.0 / 2.0) * 100.0, Z:=50.0}


        # Implementation to initialize the room

    
        

DungeonV2 := class():
    CombatCube: creative_prop_asset 
    LinePropAsset : creative_prop_asset
    BossCube : creative_prop_asset
    DebugCube: creative_prop_asset
    DebugLinePropAsset: creative_prop_asset

    var OccupancyGrid: [][]logic = array{}

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
            set Points += array{CreatePoint(Location.X, Location.Y)}
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
            DrawLine(Value(0), Value(1), LinePropAsset)

        # Create a minimum spanning tree from the triangulation
        var MST :[]Edge= KruskalMST(Points, Edges)  # Ensure LinePropAsset is defined or passed appropriately 
        Print("edges: {Edges.Length}, mst: {MST.Length}")       
        

        for(edge:MST):
            Print("Drawing edge")
            DrawLine(edge.Point1, edge.Point2, DebugLinePropAsset)



    # Function to add a room to the dungeon
    AddRoom(room:RoomV2): void =
        set Rooms += array{room}

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
                set RoomX = GetRandomInt(0, Width - RoomWidth)
                set RoomY = GetRandomInt(0, Height - RoomHeight)

                if(IsAreaFree(RoomX, RoomY, RoomWidth, RoomHeight, MinBuffer) = true):
                    set FoundSpot = true
                    break

            if(FoundSpot= true):
                var NewRoom:RoomV2 = CreateRoomV2(RoomX, RoomY, RoomWidth, RoomHeight, "normal", Self)
                if(HalfBuffer:=Floor(MinBuffer/2)):
                    MarkAreaOccupied(RoomX, RoomY, RoomWidth, RoomHeight,HalfBuffer)
                    AddRoom(NewRoom)
                    set RoomsCreated += 1
            else:
                Print("No more space available for new rooms.")
                break

        Print("Dungeon generation complete. Created {RoomsCreated} rooms. Starting triangulation.")
        TriangulateRooms()
        Print("Triangulation complete.")

        

    # Any additional functions needed for triangulation, MST, etc.
    InitOccupancyGrid(): void =
        for(I:=0..Width-1):
            if(set OccupancyGrid[I] = array{}){}
            for(J:=0..Height-1):
                if(set OccupancyGrid[I][J] = false){}

     # Checks if the specified area is free
    # Checks if the specified area is free
    IsAreaFree(X:int, Y:int, _Width:int, _Height:int, Buffer:int)<transacts>: logic =
        # Adjust the bounds to include the buffer space
        StartX := Max(0, X - Buffer)
        EndX := Min(_Width - 1 + X + Buffer, _Width - 1)
        StartY := Max(0, Y - Buffer)
        EndY := Min(_Height - 1 + Y + Buffer, _Height - 1)

        # Iterate over the adjusted area to check for free space
        for (x := StartX.. EndX):
            for (y := StartY.. EndY):
                if (OccupancyGrid[x][y] = true):
                    return false  # The area is not free
        return true  # The area is free

        
     # Marks the specified area as occupied
    MarkAreaOccupied(X:int, Y:int, _Width:int, _Height:int, HalfBuffer:int): void =
        for (x := X-HalfBuffer..X + _Width+HalfBuffer):
            for (y := Y-HalfBuffer..Y + _Height+HalfBuffer):
                if(set OccupancyGrid[x][y] = true){}
                # Calculate position for each grid cell
                Spawn:= vector3{X:=x*100.0, Y:=y*100.0, Z:=75.0}  # Adjusted to use x and y
                # Spawn a transparent debug cube at calculated position
                # Prop:=SpawnTarget(Spawn, DebugCube)

