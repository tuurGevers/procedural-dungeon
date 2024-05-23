using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Updated A* for grid-based pathfinding
AStarV3 := class:
    var OccupancyGrid: [][]int = array{}  # Assume 0 for open, 1 for corridor, 5 for room
    var GridWidth: int = 0
    var GridHeight: int = 0
    DebugCube: creative_prop_asset
    FinalCube: creative_prop_asset
    HeuristicWeight: float = 800.0
    TurnPenalty: float = 20.0

    # Initialize the occupancy grid
    Init(_OccupancyGrid: [][]int): void=
        set OccupancyGrid = _OccupancyGrid
        set GridWidth = OccupancyGrid.Length
        if(set GridHeight = OccupancyGrid[0].Length){}

    # Heuristic function using Euclidean distance
    Heuristic(node1: Point, node2: Point)<transacts>: float=
        return Sqrt(Pow(node1.X * 1.0 - node2.X * 1.0, 2.0) + Pow(node1.Y * 1.0 - node2.Y * 1.0, 2.0))


    # Get neighbors considering open grid
    GetNeighbors(node: Point, prevDirection: tuple(int, int)): []tuple(Point, float, tuple(int, int))=
        var neighbors: []tuple(Point, float, tuple(int, int)) = array{}
        var directions: []tuple(int, int) = array{(0, 1), (0, -1), (1, 0), (-1, 0)}

        for(direction: directions):
            newX := node.X + direction(0)
            newY := node.Y + direction(1)
            if(newX >= 0 and newX < GridWidth and newY >= 0 and newY < GridHeight):
                if(var Cost: float = OccupancyGrid[newX][newY] * 1.0, FlooredCost:= Floor[Cost]):
                    if(not FlooredCost=1):
                        # Apply the turn penalty if changing direction
                        if(not direction(0) = prevDirection(0) or not direction(1) = prevDirection(1)):
                            set Cost += TurnPenalty

                        case (FlooredCost):
                            1 => set Cost += 1500000.0  # Room goal point
                            2 => set Cost += 0.0  # Corridor
                            0 => set Cost += 1.0  # Open space
                            _   => 

                        

                        NewPoint := CreatePoint(newX, newY)
                        set neighbors += array{(NewPoint, Cost, direction)}
        return neighbors

    

    # The core A* search algorithm incorporating variable costs
    Search(start: Point, goal: Point)<suspends>: []Point=
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
                if((current.X = goal.X and current.Y = goal.Y)):
                    for(cube: SpawnedCubes):
                        cube.Dispose()
                    return ReconstructPath(cameFrom, current)

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
                Print("No path found here")
                break

        Print("No path found")
        return array{}  # Return an empty path if no path is found


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
                    if(set OccupancyGrid[LocalCurrent.X][LocalCurrent.Y] = 2){}
                        

               
        return totalPath


   



    