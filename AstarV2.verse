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

# Updated A* for grid-based pathfinding
AStarV2 := class:
    var OccupancyGrid: [][]int = array{}  # Assume 0 for open, 1 for corridor, 5 for room
    var GridWidth: int = 0
    var GridHeight: int = 0
    DebugCube: creative_prop_asset
    FinalCube: creative_prop_asset

    # Initialize the occupancy grid
    Init(_OccupancyGrid: [][]int): void=
        set OccupancyGrid = _OccupancyGrid
        set GridWidth = OccupancyGrid.Length
        if(set GridHeight = OccupancyGrid[0].Length){}

    # Heuristic function using Euclidean distance
    Heuristic(node1: Point, node2: Point)<transacts>: float=
        return Sqrt(Pow(node1.X * 1.0 - node2.X * 1.0, 2.0) + Pow(node1.Y * 1.0 - node2.Y * 1.0, 2.0))

    # Get neighbors considering open grid
    GetNeighbors(node: Point): []tuple(Point, float)=
        var neighbors: []tuple(Point, float) = array{}
        var directions: []tuple(int, int) = array{(0, 1), (0, -1), (1, 0), (-1, 0)}

        for(direction: directions):
            newX := node.X + direction(0)
            newY := node.Y + direction(1)
            if(newX >= 0 and newX < GridWidth and newY >= 0 and newY < GridHeight):
                if(Cost := OccupancyGrid[newX][newY]):
                    NewPoint := CreatePoint(newX, newY)
                    set neighbors += array{(NewPoint, Cost * 1.0)}
        return neighbors

    # The core A* search algorithm incorporating variable costs
    Search(start: Point, goal: Point, StartRoomX: int, StartRoomY: int, StartRoomWidth: int, StartRoomHeight: int, EndRoomX: int, EndRoomY: int, EndRoomWidth: int, EndRoomHeight: int)<suspends>: tuple([]Point, [string]Point)=
        var openSet: []Point = array{start}
        var closedSet: []Point = array{}
        var cameFrom: [string]Point = map{}
        var gScore: [string]float = map{start.UUID => 0.0}
        var fScore: [string]float = map{start.UUID => Heuristic(start, goal)}
        var SpawnedCubes: []creative_prop = array{}

        loop:
            Sleep(1.0 / 20.0)
            Print("Open set length: {openSet.Length}")

            if(openSet.Length = 0):
                break
            if(var current: Point = openSet[0]):
                for(node : openSet):
                    if(fScore[node.UUID] < fScore[current.UUID]):
                        set current = node

                # Check goal by comparing coordinates
                if(current.X = goal.X and current.Y = goal.Y):
                    Print("Path found to goal at {goal.X}, {goal.Y}")
                    for(cube: SpawnedCubes):
                        cube.Dispose()
                    return (FilterPath(ReconstructPath(cameFrom, current), StartRoomX, StartRoomY, StartRoomWidth, StartRoomHeight, EndRoomX, EndRoomY, EndRoomWidth, EndRoomHeight), cameFrom)

                set openSet = openSet.RemovePoint(current)
                set closedSet += array{current}

                var neighbors: []tuple(Point, float) = GetNeighbors(current)
                for(neighborTuple: neighbors):
                    neighbor := neighborTuple(0)
                    moveCost := neighborTuple(1)
                    if(not closedSet.Contains(neighbor) = true):
                        if(tentativeGScore := gScore[current.UUID] + moveCost):
                            if(tentativeGScore < gScore.Get(neighbor.UUID, 999999.0)):
                                if(
                                    set cameFrom[neighbor.UUID] = current
                                    set gScore[neighbor.UUID] = tentativeGScore
                                    set fScore[neighbor.UUID] = tentativeGScore + Heuristic(neighbor, goal)
                                ):
                                    if(not openSet.Contains(neighbor) = true):
                                        Print("Adding neighbor to open set at {neighbor.X} {neighbor.Y}, open set length: {openSet.Length}")
                                        SpawnLocation := vector3{X := neighbor.X * 100.0, Y := neighbor.Y * 100.0, Z := 75.0}
                                        set SpawnedCubes += array{SpawnTarget(SpawnLocation, DebugCube)}
                                        set openSet += array{neighbor}
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
            Sleep(1.0 / 29.0)
            Print("Reconstructing path")
            if(cameFrom.ContainsKey(LocalCurrent.UUID) = false):
                break
            if(set LocalCurrent = cameFrom[LocalCurrent.UUID]):
                set totalPath = array{LocalCurrent} + totalPath

        
        return totalPath

    FilterPath(path: []Point, StartRoomX: int, StartRoomY: int, StartRoomWidth: int, StartRoomHeight: int, EndRoomX: int, EndRoomY: int, EndRoomWidth: int, EndRoomHeight: int)<suspends>: []Point=
        var filteredPath: []Point = array{}
        for(point : path):
            if(
                (not IsPointInRoom(point, StartRoomX, StartRoomY, StartRoomWidth, StartRoomHeight) = true) and (not IsPointInRoom(point, EndRoomX, EndRoomY, EndRoomWidth, EndRoomHeight) = true)
            ):
                set filteredPath += array{point}
        return filteredPath

    IsPointInRoom(point: Point, RoomX: int, RoomY: int, RoomWidth: int, RoomHeight: int)<transacts>: logic=
        if(point.X >= RoomX and point.X < RoomX + RoomWidth and point.Y >= RoomY and point.Y < RoomY + RoomHeight):
            return true
        return false