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
CreateRoomV3(X:int, Y:int, Width:int, Height:int, Type:string, Parent:DungeonV3)<suspends>: RoomV3 =
    # Implementation to initialize a room
    room:=  RoomV3{X:=X, Y:=Y, Width:=Width, Height:=Height, Type:=Type, UUID:=GenerateUUID(), Parent:=Parent}
    room.Init()
    return room

CreateDungeonV3(PreferredRooms:int, MinRoomSize:int, MaxRoomSize:int, MinBuffer:int, CombatCube : creative_prop_asset, LinePropAsset:creative_prop_asset, BossCube:creative_prop_asset,DebugCube:creative_prop_asset,    
DebugLinePropAsset: creative_prop_asset,     AStarLinePropAsset:creative_prop_asset
): DungeonV3 =
    # Implementation to create a dungeon
    dungeon:= DungeonV3{Width:=75, Height:=75, PreferedRooms:=PreferredRooms, CombatCube:=CombatCube, 
    LinePropAsset:=LinePropAsset, BossCube:=BossCube, DebugCube:=DebugCube, DebugLinePropAsset:=DebugLinePropAsset, AStarLinePropAsset:=AStarLinePropAsset}
    spawn. dungeon.Generate(MinRoomSize, MaxRoomSize, MinBuffer)
    return dungeon

RoomV3:=class:
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
        for(i := 0..Width):
            for(j := 0..Height):
                Sleep(0.003)
                # Print("Spawning tile at {X*1.0+i*100.0}, {Y*1.0+j*100.0}, 50.0")
                Spawn:= vector3{X:=(X+i)*100.0, Y:=(Y+j)*100.0, Z:=50.0}
                # Spawn a floor tile at the given position
                Prop:=SpawnTarget(Spawn, Parent.CombatCube)
                set Props += array{Prop}

     


        # Implementation to initialize the room

            
DungeonV3:= class:

    CombatCube: creative_prop_asset 
    LinePropAsset : creative_prop_asset
    BossCube : creative_prop_asset
    DebugCube: creative_prop_asset
    DebugLinePropAsset: creative_prop_asset
    AStarLinePropAsset:creative_prop_asset
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
                var NewRoom:RoomV3 = CreateRoomV3(RoomX, RoomY, RoomWidth, RoomHeight, "normal", Self)
                if(HalfBuffer:=Floor(MinBuffer/2)):
                    MarkAreaOccupied(RoomX, RoomY, RoomWidth, RoomHeight,HalfBuffer, 1)
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

        #astar
        AStar := AStarV2{OccupancyGrid:= OccupancyGrid, DebugCube:= DebugCube, FinalCube:=BossCube}
        AStar.Init(OccupancyGrid)

        # Prepare room entry points for MST
        var RoomEntryPoints: []Point = array{}
        var RoomPairs: []tuple(Point, Point) = array{}

        for(room : Rooms):
            if(EntryPoint := CreatePoint(room.X + Floor(room.Width / 2), room.Y +Floor( room.Height / 2))):
                set RoomEntryPoints += array{EntryPoint}

        # Create all pairs for MST edges
        for(i := 0 .. RoomEntryPoints.Length - 1):
            for(j := i + 1 .. RoomEntryPoints.Length - 1):
                if(set RoomPairs += array{(RoomEntryPoints[i], RoomEntryPoints[j])}){}

        # Apply Kruskal's MST algorithm to connect all rooms
        var MSTEdges: []Edge = KruskalMST(RoomEntryPoints, RoomPairs)

        # Connect rooms using A*
        for(MSTEdge : MSTEdges):
            StartRoom := FindRoomContainingPoint(MSTEdge.Point1)
            EndRoom := FindRoomContainingPoint(MSTEdge.Point2)

            PathResult := AStar.Search(
                MSTEdge.Point1, MSTEdge.Point2,
                StartRoom.X, StartRoom.Y, StartRoom.Width, StartRoom.Height,
                EndRoom.X, EndRoom.Y, EndRoom.Width, EndRoom.Height
            )

            for(index->I: PathResult(0)):
                SpawnLocation := vector3{X := I.X * 100.0, Y := I.Y * 100.0, Z := 75.0}
                SpawnTarget(SpawnLocation, BossCube)
                Print("Path point {index} : {I.X}, {I.Y}")

        Print("All rooms connected successfully.")
       

       

    #
    FindRoomContainingPoint(point: Point): RoomV3=
        for(room : Rooms):
            if(point.X >= room.X and point.X < room.X + room.Width and point.Y >= room.Y and point.Y < room.Y + room.Height):
                return room
        return RoomV3{ X:=-1, Y:=-1, Width:=0, Height:=0, Type:="nil", Parent:=Self, UUID:=""}  # Return an empty room if not found        

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

    # Find Room by UUID
    FindRoomByUUID(UUID: string): RoomV3=
        for(room : Rooms):
            if(room.UUID = UUID):
                return room
        return RoomV3{ X:=-1, Y:=-1, Width:=0, Height:=0, Type:="nil", Parent:=Self, UUID:=""}  # Return an empty room if not found