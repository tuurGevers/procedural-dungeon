using { /Fortnite.com/Devices }

TileMap := class:
    TILE_EMPTY: string = "O"
    TILE_ROOM_FLOOR: string = "F"
    TILE_ROOM_WALL: string = "W"
    TILE_CORRIDOR_FLOOR: string = "C"

    ParentDungeon: DungeonV3
    var GridWidth: int = 0
    var GridHeight: int = 0

    var tilemap: [][]string = array{}
    var tilemap_rotations: [][]int = array{}

    SetTile(x: int, y: int, tileType: string, rotation: int)<transacts>: void=
        if(x >= 0 and x < GridWidth and y >= 0 and y < GridHeight):
            if(set tilemap[x][y] = tileType):
                if(set tilemap_rotations[x][y] = rotation){}

    GetWallRotation(x: int, y: int): int=
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if(y + 1 < GridHeight):
            if(set north = tilemap[x][y + 1]){}
        if(y - 1 >= 0):
            if(set south = tilemap[x][y - 1]){}
        if(x + 1 < GridWidth):
            if(set east = tilemap[x + 1][y]){}
        if(x - 1 >= 0):
            if(set west = tilemap[x - 1][y]){}

        if((not north = TILE_EMPTY and not north = TILE_ROOM_FLOOR) and (not south = TILE_EMPTY and not south = TILE_ROOM_FLOOR) and west = TILE_ROOM_FLOOR):
            return 180  # Wall up and down, pointing east
        if((not west = TILE_EMPTY and not west = TILE_ROOM_FLOOR) and (not east = TILE_EMPTY and not east = TILE_ROOM_FLOOR) and south = TILE_ROOM_FLOOR):
            return -90  # Wall left and right, pointing north
        if((not west = TILE_EMPTY and not west = TILE_ROOM_FLOOR) and (not east = TILE_EMPTY and not east = TILE_ROOM_FLOOR)):
            return 90  # Wall to left and right
        if((not north = TILE_EMPTY and not north = TILE_ROOM_FLOOR) and (not south = TILE_EMPTY and not south = TILE_ROOM_FLOOR)):
            return 0  # Wall up and down

        return 0  # Default orientation

    GenerateTileMapping(OccupancyGrid: [][]int)<suspends>: [][]tuple(string, int)=
        set GridWidth = OccupancyGrid.Length
        if(set GridHeight = OccupancyGrid[0].Length):
    
            # Initialize the empty tilemap grid
            for(x := 0 .. GridWidth - 1):
                set tilemap += array{array{}}
                set tilemap_rotations += array{array{}}
                for(y := 0 .. GridHeight - 1):
                    if(set tilemap[x] += array{TILE_EMPTY}, set tilemap_rotations[x] += array{0}){}
    
            # Mark Room Floors and Walls
            for(room: ParentDungeon.Rooms):
                # Mark Room Floors
                for(x := room.X .. room.X + room.Width - 1):
                    for(y := room.Y .. room.Y + room.Height - 1):
                        SetTile(x, y, TILE_ROOM_FLOOR, 0)
    
                # Mark Room Walls
                for(x := room.X - 1 .. room.X + room.Width):
                    SetTile(x, room.Y - 1, TILE_ROOM_WALL, GetWallRotation(x, room.Y - 1))
                    SetTile(x, room.Y + room.Height, TILE_ROOM_WALL, GetWallRotation(x, room.Y + room.Height))
                for(y := room.Y - 1 .. room.Y + room.Height):
                    SetTile(room.X - 1, y, TILE_ROOM_WALL, GetWallRotation(room.X - 1, y))
                    SetTile(room.X + room.Width, y, TILE_ROOM_WALL, GetWallRotation(room.X + room.Width, y))
    
            # Mark Corridor Floors
            for(x := 0 .. GridWidth - 1):
                for(y := 0 .. GridHeight - 1):
                    if(OccupancyGrid[x][y] = 2):
                        SetTile(x, y, TILE_CORRIDOR_FLOOR, 0)
    
        # Return the final tilemap
        var result: [][]tuple(string, int) = array{}
        for(x := 0 .. GridWidth - 1):
            var row: []tuple(string, int) = array{}
            for(y := 0 .. GridHeight - 1):
                if(set row += array{(tilemap[x][y], tilemap_rotations[x][y])}){}
            set result += array{row}
        return result
        
