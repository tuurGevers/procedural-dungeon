using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Check if a point is in a list
(Points: []Point).Contains(point: Point)<transacts>: logic=
    for(p: Points):
        if(p.X = point.X and p.Y = point.Y):
            return true
    return false

# Remove a point from a list
(Points: []Point).RemovePoint(P: Point): []Point=
    var result: []Point = array{}
    for(p: Points):
        if(not p.UUID = P.UUID):
            set result += array{p}
    return result

#
# Check if a point-direction tuple is in the list
(Points: []tuple(Point, tuple(int, int))).Contains(tupleToCheck: tuple(Point, tuple(int, int)))<transacts>: logic=
    for(p : Points):
        if(p(0).X = tupleToCheck(0).X and p(0).Y = tupleToCheck(0).Y and p(1)(0) = tupleToCheck(1)(0) and p(1)(1) = tupleToCheck(1)(1)):
            return true
    return false

# Remove a point-direction tuple from the list
(Points: []tuple(Point, tuple(int, int))).RemovePoint(T: tuple(Point, tuple(int, int))): []tuple(Point, tuple(int, int))=
    var result: []tuple(Point, tuple(int, int)) = array{}
    for(p: Points):
        if(not (p(0).UUID = T(0).UUID and p(1)(0) = T(1)(0) and p(1)(1) = T(1)(1))):
            set result += array{p}
    return result


# Updated A* for grid-based pathfinding
AStarV2 := class:
    var OccupancyGrid: [][]int = array{}  # Assume 0 for open, 1 for corridor, 5 for room
    var GridWidth: int = 0
    var GridHeight: int = 0
    DebugCube: creative_prop_asset
    FinalCube: creative_prop_asset
    HeuristicWeight: float = 15.0
    TurnPenalty: float = 20.0
    AdjacentRoomPenalty:float = 10000.0
    var CostMap: [string]int = map{}

    PrintCostMap(): void=
        for(key->Value: CostMap):
            Print("Cost: {key}, Count: {Value}")

    # Initialize the occupancy grid
    Init(_OccupancyGrid: [][]int): void=
        set OccupancyGrid = _OccupancyGrid
        set GridWidth = OccupancyGrid.Length
        if(set GridHeight = OccupancyGrid[0].Length){}
        set CostMap = map{}

    # Heuristic function using Euclidean distance
    Heuristic(node1: Point, node2: Point)<transacts>: float=
        return Sqrt(Pow(node1.X * 1.0 - node2.X * 1.0, 2.0) + Pow(node1.Y * 1.0 - node2.Y * 1.0, 2.0))

    
     # Check if a tile is adjacent to a room
    IsAdjacentToRoom(x: int, y: int)<transacts>: logic=
        var directions: []tuple(int, int) = array{(0, 1), (0, -1), (1, 0), (-1, 0)}
        for(direction: directions):
            adjX := x + direction(0)
            adjY := y + direction(1)
            if(adjX >= 0 and adjX < GridWidth and adjY >= 0 and adjY < GridHeight):
                if(OccupancyGrid[adjX][adjY] = 5):  # Room tile
                    return true
        return false

    # Get neighbors considering open grid
    GetNeighbors(node: Point, prevDirection: tuple(int, int)): []tuple(Point, float, tuple(int, int))=
        var neighbors: []tuple(Point, float, tuple(int, int)) = array{}
        var directions: []tuple(int, int) = array{(0, 1), (0, -1), (1, 0), (-1, 0)}

        for(direction: directions):
            newX := node.X + direction(0)
            newY := node.Y + direction(1)
            if(newX >= 0 and newX < GridWidth and newY >= 0 and newY < GridHeight):
                if(var Cost: float = OccupancyGrid[newX][newY] * 1.0, FlooredCost:= Floor[Cost]):
                    # Apply the turn penalty if changing direction
                    if(not direction(0) = prevDirection(0) or not direction(1) = prevDirection(1)):
                        set Cost += TurnPenalty

                    case (FlooredCost):
                        2 => set Cost -= 5.0  # Corridor
                        0 => set Cost += 0.2  # Open space
                        9 => set Cost += 0.3  # Buffer zone
                        1 => set Cost += 0.0  # Room goal point
                        _   => 

                    # Apply the adjacent room penalty
                    if(IsAdjacentToRoom(newX, newY) = true):
                        Print("Adjacent room penalty applied")
                        set Cost *= AdjacentRoomPenalty
                    CostKey := "{Cost}"
                    if(CostMap[CostKey]):
                        if(set CostMap[CostKey] += 1){}
                    else:
                        if(set CostMap[CostKey] = 1){}

                    NewPoint := CreatePoint(newX, newY)
                    set neighbors += array{(NewPoint, Cost, direction)}
        return neighbors

    

    # The core A* search algorithm incorporating variable costs
    Search(start: Point, goal: Point, StartRoomX: int, StartRoomY: int, StartRoomWidth: int, StartRoomHeight: int, EndRoomX: int, EndRoomY: int, EndRoomWidth: int, EndRoomHeight: int)<suspends>: tuple([]Point, [string]Point)=
        var openSet: []tuple(Point, tuple(int, int)) = array{(start, (0, 0))}
        var closedSet: []Point = array{}
        var cameFrom: [string]Point = map{}
        var gScore: [string]float = map{start.UUID => 0.0}
        var fScore: [string]float = map{start.UUID => HeuristicWeight * Heuristic(start, goal)}
        var SpawnedCubes: []creative_prop = array{}

        loop:
            Sleep(1.0 / 120.0)  # Reduce sleep interval to speed up pathfinding

            if(openSet.Length = 0):
                break
            if(var currentTuple: tuple(Point, tuple(int, int)) = openSet[0]):
                var current :Point = currentTuple(0)
                var prevDirection :tuple(int,int) = currentTuple(1)

                for(nodeTuple : openSet):
                    node := nodeTuple(0)
                    if(fScore[node.UUID] < fScore[current.UUID]):
                        set current = node
                        set prevDirection = nodeTuple(1)

                # Check goal by comparing coordinates
                if((current.X = goal.X and current.Y = goal.Y) or IsNonCornerTileInRoom(current, EndRoomX, EndRoomY, EndRoomWidth, EndRoomHeight) = true):
                    for(cube: SpawnedCubes):
                        cube.Dispose()
                    return (FilterPath(ReconstructPath(cameFrom, current), StartRoomX, StartRoomY, StartRoomWidth, StartRoomHeight, EndRoomX, EndRoomY, EndRoomWidth, EndRoomHeight), cameFrom)

                set openSet = openSet.RemovePoint((current, prevDirection))
                set closedSet += array{current}

                var neighbors: []tuple(Point, float, tuple(int, int)) = GetNeighbors(current, prevDirection)
                for(neighborTuple: neighbors):
                    neighbor := neighborTuple(0)
                    moveCost := neighborTuple(1)
                    direction := neighborTuple(2)
                    if(not closedSet.Contains(neighbor) = true):
                        if(tentativeGScore := gScore[current.UUID] + moveCost):
                            if(tentativeGScore < gScore.Get(neighbor.UUID, 999999.0)):
                                if(
                                    set cameFrom[neighbor.UUID] = current
                                    set gScore[neighbor.UUID] = tentativeGScore
                                    set fScore[neighbor.UUID] = tentativeGScore + HeuristicWeight * Heuristic(neighbor, goal)
                                ):
                                    if(not openSet.Contains((neighbor, direction)) = true):
                                        # Print("Adding neighbor to open set at {neighbor.X} {neighbor.Y}, open set length: {openSet.Length}")
                                        SpawnLocation := vector3{X := neighbor.X * 500.0, Y := neighbor.Y * 500.0, Z := 75.0}
                                        set SpawnedCubes += array{SpawnTarget(SpawnLocation, DebugCube)}
                                        set openSet += array{(neighbor, direction)}
            else:
                Print("No path found")
                break

        Print("No path found")
        return (array{}, cameFrom)  # Return an empty path if no path is found


    # Reconstruct the path from the cameFrom map
    ReconstructPath(cameFrom: [string]Point, current: Point)<suspends>: []Point=
        var totalPath: []Point = array{current}
        var LocalCurrent: Point = current
        loop:
            if(cameFrom.ContainsKey(LocalCurrent.UUID) = false):
                break
            if(set LocalCurrent = cameFrom[LocalCurrent.UUID]):
                if(OccupancyGrid[LocalCurrent.X][LocalCurrent.Y] = 0 or OccupancyGrid[LocalCurrent.X][LocalCurrent.Y] =9 ):  # Mark open space value as 0 
                    
                    set totalPath = array{LocalCurrent} + totalPath

               
        return totalPath

    FilterPath(path: []Point, StartRoomX: int, StartRoomY: int, StartRoomWidth: int, StartRoomHeight: int, EndRoomX: int, EndRoomY: int, EndRoomWidth: int, EndRoomHeight: int)<suspends>: []Point=
        var filteredPath: []Point = array{}
        var insideRoom: logic = false
        var entrancePointMarked: logic = false
        for(point : path):
                # If point is an entrance to a room, mark it as an entrance
                if(IsPointInRoom(point, StartRoomX, StartRoomY, StartRoomWidth, StartRoomHeight) = true or IsPointInRoom(point, EndRoomX, EndRoomY, EndRoomWidth, EndRoomHeight) = true):
                    Print("Entrance point found")
                    if( entrancePointMarked = false ):
                        MarkPointAsEntrance(point)
                        set entrancePointMarked = true
                    else:
                        set insideRoom = true

                # Mark corridor points
                if( insideRoom = false):
                    MarkPointAsCorridor(point)

                if(not point.X = StartRoomX and not point.X = EndRoomX and not point.Y = StartRoomY and not point.Y = EndRoomY):
                    set filteredPath += array{point}
                    
        return filteredPath

    IsPointInRoom(point: Point, RoomX: int, RoomY: int, RoomWidth: int, RoomHeight: int)<transacts>: logic=
        if(point.X >= RoomX and point.X < RoomX + RoomWidth+1 and point.Y >= RoomY and point.Y < RoomY + RoomHeight+1):
            Print("true")
            return true
        return false

    # Mark a point as part of the corridor in the occupancy grid
    MarkPointAsCorridor(point: Point): logic=
        if(point.X >= 0 and point.X < GridWidth and point.Y >= 0 and point.Y < GridHeight):
            if(OccupancyGrid[point.X][point.Y] = 0 or OccupancyGrid[point.X][point.Y] =9):  # Mark open space value as 0
                if(set OccupancyGrid[point.X][point.Y] = 2):  # Mark corridor value as 2
                    return true
        return false

    # Mark a point as an entrance in the occupancy grid
    MarkPointAsEntrance(point: Point): logic=
        if(point.X >= 0 and point.X < GridWidth and point.Y >= 0 and point.Y < GridHeight):
            if(set OccupancyGrid[point.X][point.Y] = 1):  # Mark entrance value as 1
                return true
        return false

    IsNonCornerTileInRoom(point: Point, RoomX: int, RoomY: int, RoomWidth: int, RoomHeight: int)<transacts>: logic =
        if (point.X > RoomX and point.X < RoomX + RoomWidth - 1 and point.Y > RoomY and point.Y < RoomY + RoomHeight - 1):
            Print("reached")
            return true
        return false