using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }

DungeonAssetV5 := class<concrete>:
    @editable Asset: creative_prop_asset = DefaultCreativePropAsset
    @editable Size: vector3 = vector3{X:=1.0, Y:=1.0, Z:=2.0}
    @editable Entrance:[]vector3 = array{vector3{X:=0.0, Y:=0.0}}
    @editable Amount:int = 1


DungeonMainV5 := class(creative_device):
    @editable DungeonProps: []DungeonAssetV5 = array{}
    @editable DebugProp: creative_prop_asset = DefaultCreativePropAsset
    @editable LinePropAsset: creative_prop_asset = DefaultCreativePropAsset
    @editable CombatCube: creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_FLOOR_PROP: creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_CROSSING_PROP: creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_CORNER_PROP: creative_prop_asset = DefaultCreativePropAsset
    @editable TILE_CORRIDOR_TPOINT_PROP: creative_prop_asset = DefaultCreativePropAsset

    DungeonWidth: float = 20000.0  # Total width of the dungeon in world units
    DungeonHeight: float = 20000.0 # Total height of the dungeon
    DungeonDepth: float = 5000.0   # Total depth or number of floors in the dungeon
    TileSize: float = 500.0        # Size of each tile in world units
    TileHeight: float = 1000.0        # Size of each tile in world units

    var GridWidth: int = 0
    var GridHeight: int = 0
    var GridDepth: int = 0  # New property for the number of levels/floors

    var Rooms: []RoomV5 = array{}

    OnBegin<override>()<suspends>: void =
        dungeon := DungeonV5{Parent:=Self, LinePropAsset:=LinePropAsset, DebugCube:=DebugProp, BossCube:=CombatCube, TILE_CORRIDOR_FLOOR_PROP:=TILE_CORRIDOR_FLOOR_PROP, TILE_CORRIDOR_CROSSING_PROP:=TILE_CORRIDOR_CROSSING_PROP, TILE_CORRIDOR_CORNER_PROP:=TILE_CORRIDOR_CORNER_PROP, TILE_CORRIDOR_TPOINT_PROP:=TILE_CORRIDOR_TPOINT_PROP}
        if:
            set GridWidth = Floor[DungeonWidth / TileSize]
            set GridHeight = Floor[DungeonHeight / TileSize]
            set GridDepth = Floor[DungeonDepth / TileHeight]
        Print("GridWidth: {GridWidth}, GridHeight: {GridHeight}, GridDepth: {GridDepth}")    
        dungeon.InitOccupancyGrid(GridWidth, GridHeight, GridDepth)
        InitializeRooms(dungeon)

    InitializeRooms(dungeon:DungeonV5)<suspends>: void =
        for(asset: DungeonProps):
            for(I:=0..asset.Amount-1):
                Print("Placing room  Size: {asset.Size.X}x{asset.Size.Y}x{asset.Size.Z}")
                var FlooredPoints: []Point3D = array{}
                for(EntrancePoint: asset.Entrance):
                    if(FlooredX:=Floor[EntrancePoint.X], FlooredY:=Floor[EntrancePoint.Y], FlooredZ:=Floor[EntrancePoint.Z]):
                        set FlooredPoints += array{Point3D{X:=FlooredX, Y:=FlooredY, Z:=FlooredZ}}
                room := RoomV5{Asset := asset, TileSize := TileSize,TileHeight:=TileHeight ,EntrancePoints:=FlooredPoints, Parent:=dungeon}
                room.InitDimensions()
                room.PlaceRandomly(DungeonWidth, DungeonHeight, DungeonDepth) 
                room.RotateRandomly()
                room.SpawnRoom()
                room.RotateEntrance()
                room.MarkEntrance(DebugProp)
                set Rooms += array{room}
                Print("Room placed at X: {room.StartPoint.X}, Y: {room.StartPoint.Y}, Z: {room.StartPoint.Z} with rotation {room.Rotation}")

        set dungeon.RoomList = Rooms
        # dungeon.InitPathFinding()