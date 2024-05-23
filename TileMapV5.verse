using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }

TileMapV5 := class:
    TILE_EMPTY: string = "O"
    TILE_CORRIDOR_FLOOR: string = "C"
    TILE_CORRIDOR_ENTRY: string = "E"
    TILE_CORRIDOR_CORNER: string = "CC"
    TILE_CORRIDOR_TPOINT: string = "CT"
    TILE_CORRIDOR_CROSSING: string = "X"
    TILE_CORRIDOR_CORNER_ENTRY : string = "CE"

    GridSlice: [][]int = array{}
    var GridWidth: int = 0
    var GridHeight: int = 0

    var tilemap: [][]string = array{}
    var tilemap_rotations: [][]int = array{}
    

    SetTile(x: int, y: int, tileType: string, Rotation: int)<transacts>: void =
        if (x >= 0 and x < GridWidth and y >= 0 and y < GridHeight):
            if (set tilemap[x][y] = tileType):
                if (set tilemap_rotations[x][y] = Rotation) {}
        else:
            Print("Tile out of bounds: X {x} Y {y}")

   

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

        if ((west = TILE_CORRIDOR_FLOOR   ) and (east = TILE_CORRIDOR_FLOOR  )  ):
            return 90  # Corridor running horizontally

        if ((north = TILE_CORRIDOR_FLOOR ) and (south = TILE_CORRIDOR_FLOOR )):
            return 0  # Corridor running vertically

        if (isFirstConnection = true):
            var NorthOccupied: int=0
            var SouthOccupied: int=0
            var EastOccupied: int=0
            var WestOccupied: int=0

            if (y + 1 < GridHeight):
                if (set NorthOccupied = GridSlice[x][y + 1] ){}
            if (y - 1 >= 0):
                if (set SouthOccupied = GridSlice[x][y - 1] ){}
            if (x + 1 < GridWidth):
                if (set EastOccupied = GridSlice[x + 1][y] ){}
            if (x - 1 >= 0):
                if (set WestOccupied = GridSlice[x - 1][y] ){}

            if (NorthOccupied = 1 or SouthOccupied = 1):
                return 0  # Corridor running vertically
            if (EastOccupied = 1 or WestOccupied = 1):
                return 90  # Corridor running horizontally


        return 0  # Default orientation


    GetCorridorCornerRotation(x: int, y: int, isFirstConnection:logic)<transacts>: int =
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

        if ((not north = TILE_EMPTY) and (not east = TILE_EMPTY)):
            return 180  # Corner pointing south-west
        if ((not south = TILE_EMPTY) and (not east = TILE_EMPTY)):
            return 90  # Corner pointing north-west
        if ((not south = TILE_EMPTY) and (not west = TILE_EMPTY)):
            return 0  # Corner pointing north-east
        if ((not north = TILE_EMPTY) and (not west = TILE_EMPTY)):
            return 270  # Corner pointing south-east

        

        return 0  # Default orientation

    AlignCorridorsToWallsAndCorners()<transacts>: void =
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):                    
                    # Check for corridor corners
                    if (tilemap[x][y] = TILE_CORRIDOR_FLOOR and IsCorridorCorner(x, y,true) = true):
                            SetTile(x, y, TILE_CORRIDOR_CORNER, GetCorridorCornerRotation(x, y, true))

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

        MarkEntries(OccupancyGrid)
        # Mark Corridor Floors
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):
                if (OccupancyGrid[x][y] = 2 or OccupancyGrid[x][y]=3):
                    SetTile(x, y, TILE_CORRIDOR_FLOOR, GetCorridorRotation(x, y, true))
        # Mark Corridor Floors
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):
                if (OccupancyGrid[x][y] = 2  or OccupancyGrid[x][y]=3):
                    SetTile(x, y, TILE_CORRIDOR_FLOOR, GetCorridorRotation(x, y, true))

        AlignCorridorsToWallsAndCorners()

       
        # Return the final tilemap
        var result: [][]tuple(string, int) = array{}
        for (x := 0 .. GridWidth - 1):
            var row: []tuple(string, int) = array{}
            for (y := 0 .. GridHeight - 1):
                if (set row += array{(tilemap[x][y], tilemap_rotations[x][y])}) {}
            set result += array{row}

        
        return result



    MarkEntries(OccupancyGrid: [][]int)<transacts>: void =
        for (x := 0 .. GridWidth - 1):
            for (y := 0 .. GridHeight - 1):
                if (OccupancyGrid[x][y] = 3):
                    var NorthOccupied: int=0
                    var SouthOccupied: int=0
                    var EastOccupied: int=0
                    var WestOccupied: int=0
        
                    if (y + 1 < GridHeight):
                        if (set NorthOccupied = GridSlice[x][y + 1] ){}
                    if (y - 1 >= 0):
                        if (set SouthOccupied = GridSlice[x][y - 1] ){}
                    if (x + 1 < GridWidth):
                        if (set EastOccupied = GridSlice[x + 1][y] ){}
                    if (x - 1 >= 0):
                        if (set WestOccupied = GridSlice[x - 1][y] ){}
                    
                    if (NorthOccupied = 1):
                        SetTile(x, y+1, TILE_CORRIDOR_CORNER_ENTRY, GetCorridorCornerRotation(x, y, true))

                    if (SouthOccupied = 1):
                        SetTile(x, y-1, TILE_CORRIDOR_CORNER_ENTRY, GetCorridorCornerRotation(x, y, true))
                    if (EastOccupied = 1):
                        SetTile(x+1, y, TILE_CORRIDOR_CORNER_ENTRY, GetCorridorCornerRotation(x, y, true))
                    if (WestOccupied = 1):
                        SetTile(x-1, y, TILE_CORRIDOR_CORNER_ENTRY, GetCorridorCornerRotation(x, y, true))

                    
    IsCorridorCorner(x: int, y: int,isFirstConnection:logic)<transacts>: logic =
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

            if (not north = TILE_EMPTY ):
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
        
   
  

   

