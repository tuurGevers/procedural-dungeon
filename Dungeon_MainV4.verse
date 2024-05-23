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
    @editable var Entrance:[]vector2 = array{vector2{X:=0.0, Y:=0.0}}
    @editable Amount:int = 1

ConnectionAsset := class<concrete>:
    @editable Asset: creative_prop_asset = DefaultCreativePropAsset
    @editable Size: vector2 = vector2{X:=1.0, Y:=1.0}
    @editable EntranceBottom:[]vector2 = array{vector2{X:=0.0, Y:=0.0}}
    @editable EntranceTop:[]vector2 = array{vector2{X:=0.0, Y:=0.0}}
    @editable Amount:int = 1
    var FirstLoop:logic = true

DungeonMainV4 := class(creative_device):
    @editable DungeonProps: []DungeonAsset = array{}
    @editable ConnectionProps: []ConnectionAsset = array{}
    @editable DebugProp: creative_prop_asset = DefaultCreativePropAsset
    @editable LinePropAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable CombatCube: creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_FLOOR_PROP:creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_CROSSING_PROP : creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_CORNER_PROP: creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_TPOINT_PROP: creative_prop_asset= DefaultCreativePropAsset

    DungeonWidth: float = 20000.0  # Total width of the dungeon in world units
    DungeonHeight: float = 20000.0 # Total height of the dungeon
    TileSize: float = 500.0       # Size of each tile in world units
    var GridWidth: int =0
    var GridHeight: int =0
    
    
    OnBegin<override>()<suspends>: void =
        dungeon:=DungeonV4{FloorHeight:=0, Parent:=Self, LinePropAsset:=LinePropAsset, DebugCube:=DebugProp, BossCube:=CombatCube, TILE_CORRIDOR_FLOOR_PROP:=TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP:=TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_CORNER_PROP:=TILE_CORRIDOR_CORNER_PROP, TILE_CORRIDOR_TPOINT_PROP:=TILE_CORRIDOR_TPOINT_PROP}
        dungeon2:=DungeonV4{FloorHeight:=1, Parent:=Self, LinePropAsset:=LinePropAsset, DebugCube:=DebugProp, BossCube:=CombatCube, TILE_CORRIDOR_FLOOR_PROP:=TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP:=TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_CORNER_PROP:=TILE_CORRIDOR_CORNER_PROP, TILE_CORRIDOR_TPOINT_PROP:=TILE_CORRIDOR_TPOINT_PROP}
        if:
            set GridWidth = Floor[DungeonWidth / TileSize]
            set GridHeight = Floor[DungeonHeight / TileSize]
        Print("GridWidth: {GridWidth}, GridHeight: {GridHeight}")    
       
        dungeon.InitOccupancyGrid(GridWidth, GridHeight)
        InitializeRooms(dungeon)

        Print("dungeon2")
        dungeon2.InitOccupancyGrid(GridWidth, GridHeight)
        InitializeRooms(dungeon2, ?IsTopFLoor:=true)
       
    InitializeRooms(dungeon:DungeonV4, ?IsTopFLoor:logic=false)<suspends>: void =
        var Rooms: []RoomV4 = array{}
        if(IsTopFLoor=false):
            #spawn connection rooms
            for( asset : ConnectionProps):
                for(I:=0..asset.Amount-1):
                    Print("Placing room  Size: {asset.Size.X}x{asset.Size.Y}")
                    var FlooredPoints:[]Point = array{}
                    var NormalAsset :DungeonAsset= DungeonAsset{Asset:=asset.Asset, Size:=asset.Size, Entrance:=asset.EntranceTop, Amount:=1}

                    if(asset.FirstLoop = true):
                        set asset.FirstLoop = false
                        for(EntrancePoint:asset.EntranceBottom):
                            if(set FlooredPoints += array{CreatePoint(X:=Floor[EntrancePoint.X], Y:=Floor[EntrancePoint.Y])}){}
                            set NormalAsset.Entrance = asset.EntranceBottom
                    else:
                        for(EntrancePoint:asset.EntranceTop):
                            if(set FlooredPoints += array{CreatePoint(X:=Floor[EntrancePoint.X], Y:=Floor[EntrancePoint.Y])}){}
                            set NormalAsset.Entrance = asset.EntranceTop

                    room := RoomV4{Asset := NormalAsset, TileSize := TileSize, EntrancePoints:=FlooredPoints, Parent:=dungeon}
                    room.InitDimensions()
                    room.PlaceRandomly(DungeonWidth, DungeonHeight) 
                    room.RotateRandomly()
                    room.SpawnRoom()
                    room.RotateEntrance()
                    room.MarkEntrance(DebugProp)
                    set Rooms += array{room}
                    Print("Room placed at X: {room.StartPoint.X}, Y: {room.StartPoint.Y} with rotation {room.Rotation}")

        for( asset : DungeonProps):
            for(I:=0..asset.Amount-1):
                Print("Placing room  Size: {asset.Size.X}x{asset.Size.Y}")
                var FlooredPoints:[]Point = array{}
                for(EntrancePoint:asset.Entrance):
                    if(set FlooredPoints += array{CreatePoint(X:=Floor[EntrancePoint.X], Y:=Floor[EntrancePoint.Y])}){}
                room := RoomV4{Asset := asset, TileSize := TileSize, EntrancePoints:=FlooredPoints, Parent:=dungeon}
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
