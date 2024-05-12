using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }

TileMap := class:
    TILE_EMPTY: string = "O"
    TILE_ROOM_FLOOR: string = "F"
    TILE_WALL_CORNER: string = "WC"
    TILE_ROOM_WALL: string = "W"
    TILE_CORRIDOR_FLOOR: string = "C"
    TILE_CORRIDOR_ENTRY: string = "E"
    TILE_CORRIDOR_CORNER: string = "CC"
    TILE_CORRIDOR_TPOINT: string = "CT"
    TILE_CORRIDOR_CROSSING: string = "X"

    NorthProp:creative_prop_asset
    EastProp:creative_prop_asset
    WestProp:creative_prop_asset

    ParentDungeon: DungeonV3
    var GridWidth: int = 0
    var GridHeight: int = 0

    var tilemap: [][]string = array{}
    var tilemap_rotations: [][]int = array{}
    
    DetectProblematicConnections()<transacts>: [][]int =
        var problematicConnections: [][]int = array{}
        var roomConnections: [string]tuple(int, int) = map{}  # Dictionary to track first corridor connection for each room
        
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):
                if (array{TILE_CORRIDOR_FLOOR, TILE_CORRIDOR_ENTRY, TILE_CORRIDOR_CORNER, TILE_CORRIDOR_TPOINT, TILE_CORRIDOR_CROSSING}.Find[tilemap[x][y]]):
                    var isProblematic: logic = false
                    var roomKey: string = ""
                    # Check each direction for room walls and identify the room by constructing a unique key (e.g., x-y coordinates of the room wall)
                    if (y + 1 < GridHeight and tilemap[x][y + 1] = TILE_ROOM_WALL):
                        set roomKey = "x{x}y{y+1}"
                    else if (y - 1 >= 0 and tilemap[x][y - 1] = TILE_ROOM_WALL):
                        set roomKey = "x{x}y{y-1}"
                    else if (x + 1 < GridWidth and tilemap[x + 1][y] = TILE_ROOM_WALL):
                        set roomKey = "x{x+1}y{y}"
                    else if (x - 1 >= 0 and tilemap[x - 1][y] = TILE_ROOM_WALL):
                        set roomKey = "x{x-1}y{y}"
                    
                    if (not roomKey = ""):
                        # Check if this is the first connection recorded for the room
                        if (Conn:=roomConnections[roomKey]):
                            Print("Room {roomKey} already has a connection at x {Conn(0)} y {Conn(1)}")
                            set isProblematic = true  # Not the first connection, hence problematic
                        else:
                            # Record this tile as the first connection to the room
                            if(set roomConnections[roomKey] = (x, y)):
                                Print("First connection for room {roomKey} at x {x} y {y}")
                    
                    if (isProblematic = true):
                        SpawnTarget(vector3{X:=x*500.0, Y:=y*500.0, Z:=400.0}, WestProp)
                        set problematicConnections += array{array{x, y}}
    
        return problematicConnections
    
    
        

    
    SetTile(x: int, y: int, tileType: string, Rotation: int)<transacts>: void =
        if (x >= 0 and x < GridWidth and y >= 0 and y < GridHeight):
            if (set tilemap[x][y] = tileType):
                if (set tilemap_rotations[x][y] = Rotation) {}
        else:
            Print("Tile out of bounds: X {x} Y {y}")

    GetWallRotation(x: int, y: int): int =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}

        if ((not north = TILE_EMPTY and not north = TILE_ROOM_FLOOR) and (not south = TILE_EMPTY and not south = TILE_ROOM_FLOOR) and west = TILE_ROOM_FLOOR):
            return 180  # Wall up and down, pointing east
        if ((not west = TILE_EMPTY and not west = TILE_ROOM_FLOOR) and (not east = TILE_EMPTY and not east = TILE_ROOM_FLOOR) and south = TILE_ROOM_FLOOR):
            return -90  # Wall left and right, pointing north
        if ((not west = TILE_EMPTY and not west = TILE_ROOM_FLOOR) and (not east = TILE_EMPTY and not east = TILE_ROOM_FLOOR)):
            return 90  # Wall to left and right
        if ((not north = TILE_EMPTY and not north = TILE_ROOM_FLOOR) and (not south = TILE_EMPTY and not south = TILE_ROOM_FLOOR)):
            return 0  # Wall up and down

        return 0  # Default orientation

    GetCornerRotation(x: int, y: int): int =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}

        if ((not south = TILE_EMPTY) and (not east = TILE_EMPTY)):
            return 90  # Corner pointing north-west
        if ((not north = TILE_EMPTY) and (not east = TILE_EMPTY)):
            return 180  # Corner pointing south-west
        if ((not west = TILE_EMPTY) and (not south = TILE_EMPTY)):
            return 0  # Corner pointing north-east
        if ((not north = TILE_EMPTY) and (not west = TILE_EMPTY)):
            return 270  # Corner pointing south-east

        return 0  # Default orientation

    GetTPointRotation(x: int, y: int)<transacts>: int =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) :
                # SpawnTarget(vector3{X:=x*500.0, Y:=(y+1)*500.0, Z:=400.0}, NorthProp)

        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]):
                # SpawnTarget(vector3{X:=(x+1)*500.0, Y:=(y)*500.0, Z:=400.0}, EastProp)

        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) :
                # SpawnTarget(vector3{X:=(x-1)*500.0, Y:=(y)*500.0, Z:=400.0}, WestProp)


        # Determine T-junction rotation
        if ((not north = TILE_EMPTY) and
            (not east = TILE_EMPTY) and
            (not west = TILE_EMPTY)):
                return 270  # T-junction pointing south
        if ((not south = TILE_EMPTY) and
            (not east = TILE_EMPTY) and
            (not west = TILE_EMPTY)):
                return 90  # T-junction pointing north
        if ((not north = TILE_EMPTY) and
            (not south = TILE_EMPTY) and
            (not east = TILE_EMPTY)):
                return 180  # T-junction pointing west
        if ((not north = TILE_EMPTY) and
            (not south = TILE_EMPTY) and
            (not west = TILE_EMPTY)):
                return 0    # T-junction pointing east

        return 0  # Default orientation


    GetCorridorRotation(x: int, y: int, isFirstConnection: logic)<transacts>: int =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}

        if ((west = TILE_CORRIDOR_FLOOR or west = TILE_ROOM_WALL or west = TILE_WALL_CORNER) and (east = TILE_CORRIDOR_FLOOR or east = TILE_ROOM_WALL or east = TILE_WALL_CORNER)  ):
            return 90  # Corridor running horizontally

        if ((north = TILE_CORRIDOR_FLOOR or north = TILE_ROOM_WALL) and (south = TILE_CORRIDOR_FLOOR or south = TILE_ROOM_WALL)):
            return 0  # Corridor running vertically

        if (isFirstConnection = true):
            if (west = TILE_ROOM_WALL or east = TILE_ROOM_WALL):
                return 90
            if (north = TILE_ROOM_WALL or south = TILE_ROOM_WALL):
                return 0

        return 0  # Default orientation

    GetEntranceRotation(x: int, y: int)<transacts>: int =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}

        if ((west = TILE_CORRIDOR_FLOOR or west = TILE_CORRIDOR_CORNER or west = TILE_CORRIDOR_CROSSING or west =TILE_CORRIDOR_TPOINT) or (east = TILE_CORRIDOR_FLOOR or east = TILE_CORRIDOR_CORNER or east = TILE_CORRIDOR_CROSSING or east =TILE_CORRIDOR_TPOINT) ):
            return 90  # Corridor running horizontally


        return 0  # Default orientation

    GetCorridorCornerRotation(x: int, y: int)<transacts>: int =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}

        if ((north = TILE_CORRIDOR_FLOOR or north = TILE_ROOM_WALL or north = TILE_CORRIDOR_CORNER) and (east = TILE_CORRIDOR_FLOOR or east = TILE_ROOM_WALL or east = TILE_CORRIDOR_CORNER)):
            return 180  # Corner pointing south-west
        if ((south = TILE_CORRIDOR_FLOOR or south = TILE_ROOM_WALL or south = TILE_CORRIDOR_CORNER) and (east = TILE_CORRIDOR_FLOOR or east = TILE_ROOM_WALL or east = TILE_CORRIDOR_CORNER)):
            return 90  # Corner pointing north-west
        if ((south = TILE_CORRIDOR_FLOOR or south = TILE_ROOM_WALL or south = TILE_CORRIDOR_CORNER) and (west = TILE_CORRIDOR_FLOOR or west = TILE_ROOM_WALL or west = TILE_CORRIDOR_CORNER)):
            return 0  # Corner pointing north-east
        if ((north = TILE_CORRIDOR_FLOOR or north = TILE_ROOM_WALL or north = TILE_CORRIDOR_CORNER) and (west = TILE_CORRIDOR_FLOOR or west = TILE_ROOM_WALL or west = TILE_CORRIDOR_CORNER)):
            return 270  # Corner pointing south-east

        return 0  # Default orientation

    AlignCorridorsToWallsAndCorners()<transacts>: void =
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):                    
                    if (tilemap[x][y] = TILE_CORRIDOR_FLOOR and GetCorridorPrimaryConnection(x, y) = true):
                        var primaryRotation: int = GetCorridorRotation(x, y, true)
                        if (set tilemap_rotations[x][y] = primaryRotation) {}

                    # Check for corridor corners
                    if (tilemap[x][y] = TILE_CORRIDOR_FLOOR and IsCorridorCorner(x, y) = true):
                        SetTile(x, y, TILE_CORRIDOR_CORNER, GetCorridorCornerRotation(x, y))

                    # Check for corridor corners
                    if ((tilemap[x][y] = TILE_CORRIDOR_FLOOR or tilemap[x][y] = TILE_CORRIDOR_CORNER)  and IsTPoint(x, y) = true):
                        SetTile(x, y, TILE_CORRIDOR_TPOINT, GetTPointRotation(x, y))
                    # Check for corridor corners
                    if ((tilemap[x][y] = TILE_CORRIDOR_FLOOR or tilemap[x][y] = TILE_CORRIDOR_CORNER or tilemap[x][y] = TILE_CORRIDOR_TPOINT)  and IsCrossingt(x, y) = true):
                        SetTile(x, y, TILE_CORRIDOR_CROSSING, GetTPointRotation(x, y))

    

    GenerateTileMapping(OccupancyGrid: [][]int)<suspends>: [][]tuple(string, int) =
        set GridWidth = OccupancyGrid.Length
        if (set GridHeight = OccupancyGrid[0].Length) {}

        # Initialize the empty tilemap grid
        for (x := 0 .. GridWidth - 1):
            set tilemap += array{array{}}
            set tilemap_rotations += array{array{}}
            for (y := 0 .. GridHeight - 1):
                if (set tilemap[x] += array{TILE_EMPTY}, set tilemap_rotations[x] += array{0}) {}

        # Mark Room Floors and Walls
        for (room: ParentDungeon.Rooms):
            # Mark Room Floors
            for (i := 0 .. room.Width - 1):
                for (j := 0 .. room.Height - 1):
                    SetTile(room.X + i, room.Y + j, TILE_ROOM_FLOOR, 0)

            # Mark Room Walls
            for (i := -1 .. room.Width):
                SetTile(room.X + i, room.Y - 1, TILE_ROOM_WALL, 0)
                SetTile(room.X + i, room.Y + room.Height, TILE_ROOM_WALL, 0)
            for (j := -1 .. room.Height):
                SetTile(room.X - 1, room.Y + j, TILE_ROOM_WALL, 0)
                SetTile(room.X + room.Width, room.Y + j, TILE_ROOM_WALL, 0)

            # Mark Wall Corners
            SetTile(room.X - 1, room.Y - 1, TILE_WALL_CORNER, GetCornerRotation(room.X - 1, room.Y - 1))
            SetTile(room.X - 1, room.Y + room.Height, TILE_WALL_CORNER, GetCornerRotation(room.X - 1, room.Y + room.Height))
            SetTile(room.X + room.Width, room.Y - 1, TILE_WALL_CORNER, GetCornerRotation(room.X + room.Width, room.Y - 1))
            SetTile(room.X + room.Width, room.Y + room.Height, TILE_WALL_CORNER, GetCornerRotation(room.X + room.Width, room.Y + room.Height))

        # Mark Corridor Floors
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):
                if (OccupancyGrid[x][y] = 2):
                    SetTile(x, y, TILE_CORRIDOR_FLOOR, GetCorridorRotation(x, y, true))
        # Mark Corridor Floors
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):
                if (OccupancyGrid[x][y] = 2):
                    SetTile(x, y, TILE_CORRIDOR_FLOOR, GetCorridorRotation(x, y, true))

        AlignCorridorsToWallsAndCorners()
        normalEntrances := IdentifyNormalEntrances()
    
       
        # Return the final tilemap
        var result: [][]tuple(string, int) = array{}
        for (x := 0 .. GridWidth - 1):
            var row: []tuple(string, int) = array{}
            for (y := 0 .. GridHeight - 1):
                if (set row += array{(tilemap[x][y], tilemap_rotations[x][y])}) {}
            set result += array{row}

        
        return result

    

    GetCorridorPrimaryConnection(x: int, y: int)<transacts>: logic =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}

        if((north = TILE_ROOM_WALL or north = TILE_WALL_CORNER) or
            (south = TILE_ROOM_WALL or south = TILE_WALL_CORNER) or
            (east = TILE_ROOM_WALL or east = TILE_WALL_CORNER) or
            (west = TILE_ROOM_WALL or west = TILE_WALL_CORNER)):
                return true
            else:
                return false


    IsCorridorCorner(x: int, y: int)<transacts>: logic =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY
    
        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}
    
        # Check if the adjacent tiles are not empty and form a corner pattern
        if ((not north = TILE_EMPTY and not east = TILE_EMPTY) or
            (not south = TILE_EMPTY and not east = TILE_EMPTY) or
            (not south = TILE_EMPTY and  not west = TILE_EMPTY) or
            (not north = TILE_EMPTY and not west = TILE_EMPTY)):
                return true
        else:
                return false
                

    IsTPoint(x: int, y: int)<transacts>: logic =
        var north: string = TILE_EMPTY
        var south: string = TILE_EMPTY
        var east: string = TILE_EMPTY
        var west: string = TILE_EMPTY

        if (y + 1 < GridHeight):
            if (set north = tilemap[x][y + 1]) {}
        if (y - 1 >= 0):
            if (set south = tilemap[x][y - 1]) {}
        if (x + 1 < GridWidth):
            if (set east = tilemap[x + 1][y]) {}
        if (x - 1 >= 0):
            if (set west = tilemap[x - 1][y]) {}

        var connectedDirections: int = 0

        if (not north = TILE_EMPTY):
            set connectedDirections += 1
        if (not south = TILE_EMPTY):
            set connectedDirections += 1
        if (not east = TILE_EMPTY):
            set connectedDirections += 1
        if (not west = TILE_EMPTY):
            set connectedDirections += 1

        if (connectedDirections = 3):
            return true
        else:
            return false

    IsEntrance(x: int, y: int)<transacts>: logic =
        if(tilemap[x][y] = TILE_ROOM_WALL or tilemap[x][y] = TILE_WALL_CORNER):
            var north: string = TILE_EMPTY
            var south: string = TILE_EMPTY
            var east: string = TILE_EMPTY
            var west: string = TILE_EMPTY

            if (y + 1 < GridHeight):
                if (set north = tilemap[x][y + 1]) {}
            if (y - 1 >= 0):
                if (set south = tilemap[x][y - 1]) {}
            if (x + 1 < GridWidth):
                if (set east = tilemap[x + 1][y]) {}
            if (x - 1 >= 0):
                if (set west = tilemap[x - 1][y]) {}

            var connectedDirections: int = 0

            if (not north = TILE_EMPTY):
                set connectedDirections += 1
            if (not south = TILE_EMPTY):
                set connectedDirections += 1
            if (not east = TILE_EMPTY):
                set connectedDirections += 1
            if (not west = TILE_EMPTY):
                set connectedDirections += 1

            if (connectedDirections = 4):
                return true
            else:
                return false
        return false

    IsCrossingt(x: int, y: int)<transacts>: logic =
            var north: string = TILE_EMPTY
            var south: string = TILE_EMPTY
            var east: string = TILE_EMPTY
            var west: string = TILE_EMPTY

            if (y + 1 < GridHeight):
                if (set north = tilemap[x][y + 1]) {}
            if (y - 1 >= 0):
                if (set south = tilemap[x][y - 1]) {}
            if (x + 1 < GridWidth):
                if (set east = tilemap[x + 1][y]) {}
            if (x - 1 >= 0):
                if (set west = tilemap[x - 1][y]) {}

            var connectedDirections: int = 0

            if (north = TILE_CORRIDOR_FLOOR or north = TILE_ROOM_WALL or north = TILE_CORRIDOR_CORNER):
                set connectedDirections += 1
            if (south = TILE_CORRIDOR_FLOOR or south = TILE_ROOM_WALL or south = TILE_CORRIDOR_CORNER):
                set connectedDirections += 1
            if (east = TILE_CORRIDOR_FLOOR or east = TILE_ROOM_WALL or east = TILE_CORRIDOR_CORNER):
                set connectedDirections += 1
            if (west = TILE_CORRIDOR_FLOOR or west = TILE_ROOM_WALL or west = TILE_CORRIDOR_CORNER):
                set connectedDirections += 1

            if (connectedDirections = 4):
                return true
            else:
                return false
        


    ###
    # Function to identify corner entrances
   

    # Function to identify normal entrances
    IdentifyNormalEntrances()<transacts>: []tuple(int,int) =
        var normalEntrances: []tuple(int,int) = array{}
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):
               if(IsEntrance(x, y) = true):
                    var north: string = TILE_EMPTY
                    var south: string = TILE_EMPTY
                    var east: string = TILE_EMPTY
                    var west: string = TILE_EMPTY

                    if (y + 1 < GridHeight):
                        if (set north = tilemap[x][y + 1]) {}
                    if (y - 1 >= 0):
                        if (set south = tilemap[x][y - 1]) {}
                    if (x + 1 < GridWidth):
                        if (set east = tilemap[x + 1][y]) {}
                    if (x - 1 >= 0):
                        if (set west = tilemap[x - 1][y]) {}

                    if(not north = TILE_CORRIDOR_ENTRY and not south = TILE_CORRIDOR_ENTRY and not east = TILE_CORRIDOR_ENTRY and not west = TILE_CORRIDOR_ENTRY):
                        set normalEntrances += array{(x, y)}
                        SetTile(x, y, TILE_CORRIDOR_ENTRY, GetEntranceRotation(x, y))
                        Print("Normal entrance found at X:{x}, Y:{y}")
        return normalEntrances

   

