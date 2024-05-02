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
    return Room{X:=X, Y:=Y, Type:=Type, ParentDungeon:=ParentDungeon, UUID:=GenerateUUID()}

# Create a new dungeon with the specified number of rooms.
CreateDungeon(MaxRooms:int,SpawnCube:creative_prop_asset, CombatCube:creative_prop_asset, BossCube:creative_prop_asset, CorridorAsset:creative_prop_asset, ?Rooms:[]Room = array{}):Dungeon=
    return Dungeon{MaxRooms:=MaxRooms, CombatCube:=CombatCube ,Rooms:=Rooms, SpawnCube:=SpawnCube, BossCube:=BossCube, CorridorAsset:=CorridorAsset}

CreateCorridor(Start:Room, End:Room, ParentDungeon:Dungeon):Corridor=
    return Corridor{StartRoom:=Start, EndRoom:=End, ParentDungeon:=ParentDungeon}

Room := class():
    var X:int
    var Y:int
    var Type:int
    var Size: float = 100.0
    var Prop: creative_prop = creative_prop{}
    var PossibleConnections: []logic = array{true,  true , true ,true }
    var UUID:string 
    ParentDungeon: Dungeon
    # Add a connection to another room.
    
    HasRemainingConnections()<transacts>:logic=
        for (connection :PossibleConnections):
            if(connection = true):
                return true
        return false

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
            Rad:=DegreesToRadians(90.0)
            return MakeRotationFromYawPitchRollDegrees(Rad, 0.0, 0.0)
        else:
            return MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)

    SpawnCorridor():void=
        Points := AdjustPointsForCorridor()
        # StartRoom.Prop.GetTransform().Translation.Print(?Msg:="StartRoom")
        # EndRoom.Prop.GetTransform().Translation.Print(?Msg:="EndRoom")
        # Points.Print(?Msg:="Points")
        # Print("\n\n\n")
        
        Rot:=GetRotation()
        if(Yaw:= Rot.GetYawPitchRollDegrees()[0]):
            P := SpawnTarget(Points, ParentDungeon.CorridorAsset)
            if(P.TeleportTo[Points,P.GetTransform().Rotation.ApplyYaw(Yaw)]){}

Dungeon := class():
    var Rooms: []Room = array{}
    var Corridors: []Corridor = array{}
    var MaxRooms:int
    RoomSize: float = 100.0
    SpawnPoint : vector3 = vector3{X:=0.0, Y:=0.0, Z:=50.0}

    SpawnCube: creative_prop_asset 
    CombatCube: creative_prop_asset 
    BossCube: creative_prop_asset 
    CorridorAsset : creative_prop_asset 

    InvertConnection(Direction:int): int =
        # Assuming 0: north, 1: east, 2: south, 3: west
        if(Res:=Mod[(Direction + 2), 4]):
            return Res
        else:
            return -1

    # Add a room to the dungeon.
    AddRoom(room:Room):void=
        set Rooms += array{room}
        Print("Room added at coordinates: X= {room.X},  Y={room.Y}, Type=, {room.Type}")
    

    CheckAccessibility():logic=
        #TODO: Implement this function.
        return true

    CalculateNextRoomCoordinates(currentRoom:Room, Direction:int): tuple(int, int) =
        # Make multiple attempts to find a valid position
        for (attempts := 0.. 10):
            var NextRoomX :int= currentRoom.X
            var NextRoomY :int= currentRoom.Y
            
            case (Direction):
                0=> set NextRoomX += 1
                1=> set NextRoomX -= 1
                2=> set NextRoomY += 1
                _=> set NextRoomY -= 1
            
            # Check if the room is occupied
            if (IsRoomOccupied(NextRoomX, NextRoomY) = false):
                return (NextRoomX, NextRoomY)
        
        # If no unoccupied space is found, return current coordinates as fallback
        return (currentRoom.X, currentRoom.Y)

    IsRoomOccupied(X:int, Y:int)<transacts>: logic =
        for(room :Rooms):
            if (room.X = X and room.Y = Y):
                return true
        return false

    PickRandomRoomAndConnection()<suspends>: tuple(Room, int) =
        TempRoom:=CreateRoom(-1,-1,-1,Self)
        var ReturnValues: tuple(Room, int) = (TempRoom, -8)
        # Pick a random room
        var Complete: logic = false
        var attempts: int = 0

        loop:
            Sleep(0.02)
            if(Complete = true or attempts > 50):
                break
            if(room :Room = Rooms[GetRandomInt(0, Rooms.Length-1)], room.HasRemainingConnections() = true):

                # Pick a random connection
                var TriedDirections: []logic = array{false, false, false, false}
                loop:
                    if( room.HasRemainingConnections() = false):
                        break
                    Sleep(0.01)
                    Index:= GetRandomInt(0,TriedDirections.Length-1)
                    if(TriedDirections[Index] = false):
                        if(set TriedDirections[Index] = true){}
                   
                    if( connection := room.PossibleConnections[Index] = true ):
                        C:= CalculateNextRoomCoordinates(room, Index)
                         # Print("Connection found at index: {Index}")
                         if(set room.PossibleConnections[Index] = false){}
                        if(IsRoomOccupied( C(0), C(1))= false):
                           
                            set ReturnValues = (room, Index)
                            set Complete = true
                            break
            set attempts += 1

        return ReturnValues

    # Generate a dungeon.
    Generate()<suspends>: void =
        # Add the spawn room
        var currentRoom :Room= CreateRoom(0, 0, 0, Self)
        AddRoom(currentRoom)
    
        var I:int = 0
        # Generate additional rooms
        loop:
            if(I>MaxRooms-2):
                Print("Max Rooms Reached")
                break
            
            set I+=1
            # Determine a random direction and position for the next room
            RoomAndConnection := PickRandomRoomAndConnection()
            
            nextRoomCoordinates := CalculateNextRoomCoordinates(RoomAndConnection(0), RoomAndConnection(1))
            # Check if we didn't find a new position
            # if( nextRoomCoordinates = (RoomAndConnection(0).X, RoomAndConnection(0).Y)):
            #     Print("Could not find position for new room.")
            #     break
            # Create the new room and corridor
            var nextRoom: Room = CreateRoom(nextRoomCoordinates(0), nextRoomCoordinates(1), 1, Self)
            if(I >= MaxRooms-1):
                Print("Boss Room Created")
                set nextRoom.Type = 2
           
            var invertedIndex: int = InvertConnection(RoomAndConnection(1))
            if(set nextRoom.PossibleConnections[invertedIndex] = false){}
            if(set RoomAndConnection(0).PossibleConnections[RoomAndConnection(1)] = false){}

            corridor := CreateCorridor(currentRoom, nextRoom, Self)
            set Corridors += array{corridor}
            AddRoom(nextRoom)

            # Update the current room
            set currentRoom = nextRoom

        Print("Dungeon generation complete. {Rooms.Length} rooms and {Corridors.Length} corridors created.")
        #check if there are cubes stacked 
        for(Index->room :Rooms):
            Sleep(0.15)
            room.SpawnRoom()
            if(corridor :=Corridors[Index]):
                Sleep(0.05)
                corridor.SpawnCorridor()
        
        for(room:Rooms):
            var StackIndex:int = 0
            for(OtherRoom:Rooms):
                if(not room.UUID = OtherRoom.UUID):
                    if(room.Prop.GetTransform().Translation.IsEqual(OtherRoom.Prop.GetTransform().Translation) = true):
                        set StackIndex += 1
                        Print("Cubes stacked at coordinates: X= {room.X},  Y={room.Y}, StackIndex=, {StackIndex}")
                        if(OtherRoom.Prop.TeleportTo[vector3{X:=OtherRoom.Prop.GetTransform().Translation.X, Y:=OtherRoom.Prop.GetTransform().Translation.Y, Z:=OtherRoom.Prop.GetTransform().Translation.Z + 50.0}, OtherRoom.Prop.GetTransform().Rotation]){}
        
    SpawnCorridorsAsync()<suspends>:void=
        for(corridor :Corridors):
            Sleep(0.2)
            corridor.SpawnCorridor()
    FindFarthestRoom():Room=
        return CreateRoom(-1,-1,-1, Self)
