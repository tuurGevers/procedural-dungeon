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
CreateRoomV2(X:int, Y:int, Width:int, Height:int, Type:string, Parent:DungeonV2): RoomV2 =
    Print("todo: create room")
    # Implementation to initialize a room
    room:=  RoomV2{X:=X, Y:=Y, Width:=Width, Height:=Height, Type:=Type, ID:=GenerateUUID(), Parent:=Parent}
    room.Init()
    return room

CreateDungeonV2(PreferredRooms:int, MinRoomSize:int, MaxRoomSize:int, MinBuffer:int, CombatCube : creative_prop_asset, LinePropAsset:creative_prop_asset): DungeonV2 =
    # Implementation to create a dungeon
    dungeon:= DungeonV2{Width:=100, Height:=100, PreferedRooms:=PreferredRooms, CombatCube:=CombatCube, LinePropAsset:=LinePropAsset}
    dungeon.Generate(PreferredRooms, MinRoomSize, MaxRoomSize, MinBuffer)
    return dungeon

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

    Init():void=
        for(i := 0..Width-1):
            for(j := 0..Height-1):
                # Print("Spawning tile at {X*1.0+i*100.0}, {Y*1.0+j*100.0}, 50.0")
                Spawn:= vector3{X:=(X+i)*100.0, Y:=(Y+j)*100.0, Z:=50.0}
                # Spawn a floor tile at the given position
                Prop:=SpawnTarget(Spawn, Parent.CombatCube)
                set Props += array{Prop}

        # Calculate the middle location of the room
        if(Cube:= Props[Floor(Width/2)-Floor(1*Height/2)]):
            set MiddleLocation = Cube.GetTransform().Translation

        # Implementation to initialize the room

    
        

DungeonV2 := class():
    CombatCube: creative_prop_asset 
    LinePropAsset : creative_prop_asset
    var OccupancyGrid: [][]logic = array{}

    # List of all rooms in the dungeon
    var Rooms: []RoomV2 = array{}
    
    # Dungeon width and height for boundary checks
    var Width:int
    var Height:int

    PreferedRooms:int
    
    # Function to calculate the midpoints of rooms and triangulate them
    TriangulateRooms(): void =
        # Collect the midpoint of each room in the dungeon
        var Points: []Point = array{}
        for(room :Rooms):
            Location:= vector2{X:=room.MiddleLocation.X, Y:=room.MiddleLocation.Y}
            set Points += array{CreatePoint(Location.X, Location.Y)}

        # Initialize the Delaunay triangulation with these points
        Triangulation := DelaunayTriangulation{LinePropAsset:= LinePropAsset}  # Ensure LinePropAsset is defined or passed appropriately
        Triangulation.Initialize(Points)

        # Perform the triangulation
        Triangulation.Triangulate(Points)

        # Optionally, you can draw the triangles for visualization purposes
        Triangulation.DrawTriangles()

    # Function to add a room to the dungeon
    AddRoom(room:RoomV2): void =
        set Rooms += array{room}

    # Function to generate the dungeon
    Generate(PreferredRooms:int, MinRoomSize:int, MaxRoomSize:int, MinBuffer:int): void =
        InitOccupancyGrid()
        var RoomsCreated:int = 0

        loop:
            Print("Creating room {RoomsCreated+1}")
            if(RoomsCreated >PreferredRooms):
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
                MarkAreaOccupied(RoomX, RoomY, RoomWidth, RoomHeight)
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
    IsAreaFree(X:int, Y:int, _Width:int, _Height:int, Buffer:int)<transacts>: logic =
        for (x := Max(0, X - Buffer)..Min(_Width-1, X + _Width + Buffer)):
            for (y := Max(0, Y - Buffer)..Min(_Height-1, Y + _Height + Buffer)):
                if (OccupancyGrid[x][y] = true):
                    return false
        return true
        
     # Marks the specified area as occupied
    MarkAreaOccupied(X:int, Y:int, _Width:int, _Height:int): void =
        for (x := X..X + _Width-1):
            for (y := Y..Y + _Height-1):
                if(set OccupancyGrid[x][y] = true){}
