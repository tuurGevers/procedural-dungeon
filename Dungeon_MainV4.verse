using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }

DungeonAsset := class<concrete>:
    @editable Asset: creative_prop_asset = DefaultCreativePropAsset
    @editable Size: vector2 = vector2{X:=1.0, Y:=1.0}
    @editable Entrance:vector2 = vector2{X:=0.0, Y:=0.0}
    @editable Amount:int = 1

DungeonMainV4 := class(creative_device):
    @editable DungeonProps: []DungeonAsset = array{}
    @editable DebugProp: creative_prop_asset = DefaultCreativePropAsset
    @editable LinePropAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable CombatCube: creative_prop_asset = DefaultCreativePropAsset

    DungeonWidth: float = 20000.0  # Total width of the dungeon in world units
    DungeonHeight: float = 20000.0 # Total height of the dungeon
    TileSize: float = 500.0       # Size of each tile in world units
    var GridWidth: int =0
    var GridHeight: int =0
    var Rooms: []RoomV4 = array{}
    
    OnBegin<override>()<suspends>: void =
        dungeon:=DungeonV4{LinePropAsset:=LinePropAsset, DebugCube:=DebugProp, BossCube:=CombatCube}
        if:
            set GridWidth = Floor[DungeonWidth / TileSize]
            set GridHeight = Floor[DungeonHeight / TileSize]
        Print("GridWidth: {GridWidth}, GridHeight: {GridHeight}")    
        dungeon.InitOccupancyGrid(GridWidth, GridHeight)
        InitializeRooms(dungeon)

    InitializeRooms(dungeon:DungeonV4)<suspends>: void =
        for( asset : DungeonProps):
            for(I:=0..asset.Amount-1):
                Print("Placing room  Size: {asset.Size.X}x{asset.Size.Y}")
                if(FlooredEntranceX:=Floor[asset.Entrance.X], FlooredEntranceY:=Floor[asset.Entrance.Y]):
                    room := RoomV4{Asset := asset, TileSize := TileSize, EntrancePoint:=CreatePoint(FlooredEntranceX,FlooredEntranceY), Parent:=dungeon}
                    room.InitDimensions()
                    room.PlaceRandomly(DungeonWidth, DungeonHeight) 
                    room.RotateRandomly()
                    room.SpawnRoom()
                    room.RotateEntrance()
                    room.MarkEntrance(DebugProp)
                    set Rooms += array{room}
                    Print("Room placed at X: {room.StartPoint.X}, Y: {room.StartPoint.Y} with rotation {room.Rotation}")

        set dungeon.RoomList = Rooms
        dungeon.InitPathFinding()
