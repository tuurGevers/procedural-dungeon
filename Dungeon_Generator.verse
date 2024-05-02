using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }

# Create a new room with the specified X and Y coordinates.
CreateRoom(X:int, Y:int, Type:int, ParentDungeon:Dungeon):Room=
    return Room{X:=X, Y:=Y, Type:=Type, ParentDungeon:=ParentDungeon}

# Create a new dungeon with the specified number of rooms.
CreateDungeon(MaxRooms:int,SpawnCube:creative_prop_asset, CombatCube:creative_prop_asset, BossCube:creative_prop_asset, CorridorAsset:creative_prop_asset, ?Rooms:[]Room = array{}):Dungeon=
    return Dungeon{MaxRooms:=MaxRooms, CombatCube:=CombatCube ,Rooms:=Rooms, SpawnCube:=SpawnCube, BossCube:=BossCube, CorridorAsset:=CorridorAsset}

CreateCorridor(Start:Room, End:Room, ParentDungeon:Dungeon):Corridor=
    return Corridor{StartRoom:=Start, EndRoom:=End, ParentDungeon:=ParentDungeon}

Room := class():
    var X:int
    var Y:int
    var Type:int
    var Connections: []Room = array{}
    var Size: float = 100.0
    var Prop: creative_prop = creative_prop{}
    ParentDungeon: Dungeon
    # Add a connection to another room.
    AddConnection(room:Room):void=
        set Connections += array{room}

    SpawnRoom():void=
        Spawn:= vector3{X:=ParentDungeon.SpawnPoint.X + X*(Size+ParentDungeon.RoomSize), Y :=ParentDungeon.SpawnPoint.Y + Y*(Size+ParentDungeon.RoomSize), Z:=ParentDungeon.SpawnPoint.Z}
        case (Type):
            0=>set Prop = SpawnTarget(Spawn, ParentDungeon.SpawnCube)
            1=>set Prop = SpawnTarget(Spawn, ParentDungeon.CombatCube)
            _=>set Prop = SpawnTarget(Spawn, ParentDungeon.BossCube)

Corridor := class():
    var StartRoom:Room
    var EndRoom:Room
    ParentDungeon: Dungeon
    var Prop: creative_prop = creative_prop{}


    AdjustPointsForCorridor(): vector3 =
        if(StartRoom.X < EndRoom.X): 
            # For horizontal corridors to the right
            return vector3{
                X:= StartRoom.Prop.GetTransform().Translation.X + ParentDungeon.RoomSize, 
                Y:= StartRoom.Prop.GetTransform().Translation.Y, 
                Z:= 50.0
            }
        else if(StartRoom.X > EndRoom.X):
            # For horizontal corridors to the left
            return vector3{
                X:= StartRoom.Prop.GetTransform().Translation.X - ParentDungeon.RoomSize, 
                Y:= StartRoom.Prop.GetTransform().Translation.Y, 
                Z:= 50.0
            }
        else if(StartRoom.Y < EndRoom.Y):
            # For vertical corridors upwards
            return vector3{
                X:= StartRoom.Prop.GetTransform().Translation.X, 
                Y:= StartRoom.Prop.GetTransform().Translation.Y + ParentDungeon.RoomSize, 
                Z:= 50.0
            }
        else:
            # For vertical corridors downwards
            return vector3{
                X:= StartRoom.Prop.GetTransform().Translation.X, 
                Y:= StartRoom.Prop.GetTransform().Translation.Y - ParentDungeon.RoomSize, 
                Z:= 50.0
            }
    

    GetRotation():rotation=
        if(StartRoom.X > EndRoom.X or StartRoom.X < EndRoom.X): 
            Print("X")
            Rad:=DegreesToRadians(90.0)
            return MakeRotationFromYawPitchRollDegrees(Rad, 0.0, 0.0)
        else:
            Print("Y")
            return MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)

    SpawnCorridor():void=
        Points := AdjustPointsForCorridor()
        StartRoom.Prop.GetTransform().Translation.Print(?Msg:="StartRoom")
        EndRoom.Prop.GetTransform().Translation.Print(?Msg:="EndRoom")
        Points.Print(?Msg:="Points")
        Print("\n\n\n")
        
        Rot:=GetRotation()
        if(Yaw:= Rot.GetYawPitchRollDegrees()[0]):
            Print("Yaw: {Yaw}")
            P := SpawnTarget(Points, ParentDungeon.CorridorAsset)
            if(P.TeleportTo[Points,P.GetTransform().Rotation.ApplyYaw(Yaw)]):
                Print("Teleported")

Dungeon := class():
    var Rooms: []Room = array{}
    var MaxRooms:int
    RoomSize: float = 100.0
    SpawnPoint : vector3 = vector3{X:=0.0, Y:=0.0, Z:=50.0}

    SpawnCube: creative_prop_asset 
    CombatCube: creative_prop_asset 
    BossCube: creative_prop_asset 
    CorridorAsset : creative_prop_asset 

    # Add a room to the dungeon.
    AddRoom(room:Room):void=
        set Rooms += array{room}

    CheckAccessibility():logic=
        #TODO: Implement this function.
        return true

    CalculateNextRoomCoordinates(currentRoom:Room): tuple(int, int)=
        # Determine a random direction for the next room
        direction := GetRandomInt(0, 3)
        var NextRoomCoordinates :tuple(int, int)= (currentRoom.X, currentRoom.Y)
        case (direction):
            0=>return (NextRoomCoordinates(0) + 1 , NextRoomCoordinates(1))
            1=>return (NextRoomCoordinates(0) - 1 , NextRoomCoordinates(1))
            2=>return (NextRoomCoordinates(0), NextRoomCoordinates(1) + 1 )
            _=>return (NextRoomCoordinates(0), NextRoomCoordinates(1) - 1)

    # Generate a dungeon.
    Generate(): void =
        # Add the spawn room
        var currentRoom :Room= CreateRoom(0, 0, 0, Self)
        AddRoom(currentRoom)
    
        # Generate additional rooms
        for(I:=0..MaxRooms-1):
            # Determine a random direction and position for the next room
            nextRoomCoordinates := CalculateNextRoomCoordinates(currentRoom)
            
            # Create the new room and corridor
            nextRoom := CreateRoom(nextRoomCoordinates(0), nextRoomCoordinates(1), 1, Self)
            AddRoom(nextRoom)
            corridor := CreateCorridor(currentRoom, nextRoom, Self)

            # Update the current room
            set currentRoom = nextRoom

            # Spawn the corridor and room
            corridor.SpawnCorridor()
            currentRoom.SpawnRoom()
    
        # Set the boss room as the furthest room from the spawn
        bossRoom := FindFarthestRoom()
        set bossRoom.Type = 2  # Assuming 2 denotes a boss room type
        bossRoom.SpawnRoom()

    FindFarthestRoom():Room=
        return CreateRoom(-1,-1,-1, Self)
