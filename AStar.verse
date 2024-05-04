using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }

(Points: []Point).Contains(point: Point)<transacts>: logic=
    for(p: Points):
        if(p.UUID = point.UUID):
            return true
    return false

(Points: []Point).RemovePoint(P:Point): []Point=
    var result: []Point = array{}
    for(p: Points):
        if(not p.UUID = P.UUID):
            set result += array{p}
    return result

# Updated A* for weighted pathfinding
AStarContinuous := class:
    var Edges: []Edge = array{}
    var OccupancyGrid: [][]int = array{}  # Assume 0 for open, 1 for corridor, 5 for room
    GridWidth: int 
    GridHeight: int 
    DebugCube: creative_prop_asset
    # Initialize with MST edges and the grid
    Init(_Edges: []Edge, _OccupancyGrid: [][]int): void=
        set Edges = _Edges
        set OccupancyGrid = _OccupancyGrid
        Print("A* initialized with edges: {Edges.Length}")

    # Heuristic function using Euclidean distance
    Heuristic(node1: Point, node2: Point)<transacts>: float=
        return Sqrt(Pow(node1.X*1.0 - node2.X*1.0, 2.0) + Pow(node1.Y*1.0 - node2.Y*1.0, 2.0))

    # Get neighbors considering MST and open grid
    GetNeighbors(node: Point): []tuple(Point, float)=
        var neighbors: []tuple(Point, float) = array{}
        for(edge: Edges):
            if(edge.Point1.UUID = node.UUID):
                set neighbors += array{(edge.Point2, 1.0)}  # Lower cost for MST edges
            else if(edge.Point2.UUID = node.UUID):
                set neighbors += array{(edge.Point1, 1.0)}  # Lower cost for MST edges
        # Add grid neighbors considering open spaces and room spaces
        var directions: []tuple(int, int) = array{(0,1), (0,-1), (1,0), (-1,0)}
        for(direction: directions):
            newX := node.X + direction(0)
            newY := node.Y + direction(1)
                if(newX >= 0 and newX < GridWidth and newY >= 0 and newY < GridHeight):
                    if(Cost := OccupancyGrid[newX][newY]):  # Cost based on the type of area
                        NewPoint:=CreatePoint(newX, newY)
                        set neighbors += array{(NewPoint, Cost*1.0)}
        return neighbors

    # The core A* search algorithm incorporating variable costs
    Search(start: Point, goal: Point)<suspends>: tuple([]Point,[string]Point )=
        var openSet: []Point = array{start}
        var cameFrom: [string]Point = map{}

        var gScore: [string]float = map{start.UUID=> 0.0}
        var fScore: [string]float = map{start.UUID=> Heuristic(start, goal)}
        var SpawnedCubes: []creative_prop = array{}
        loop:
            Sleep(1.0/20.0)
            Print("Open set length: {openSet.Length}")

            if(openSet.Length < 0):
                break
            if(var current: Point = openSet[0]):
                for(node : openSet):
                    if(fScore[node.UUID] < fScore[current.UUID]):
                        set current = node

                if(current.UUID = goal.UUID):
                    Print("Path found")
                    for(cube: SpawnedCubes):
                        cube.Dispose()
                    return (ReconstructPath(cameFrom, current), cameFrom)

                set openSet = openSet.RemovePoint(current)

                var neighbors :[]tuple(Point, float)= GetNeighbors(current)
                for(neighborTuple : neighbors):
                    neighbor := neighborTuple(0)
                    moveCost := neighborTuple(1)
                    if(tentativeGScore := gScore[current.UUID] + moveCost):
                        if(tentativeGScore < gScore.Get(neighbor.UUID, 999999.0)):
                            if(
                                set cameFrom[neighbor.UUID] = current
                                set gScore[neighbor.UUID] = tentativeGScore
                                set fScore[neighbor.UUID] = tentativeGScore + Heuristic(neighbor, goal)
                            ):
                                Print("Adding neighbor to open set with length {neighbor.X} {neighbor.Y} {openSet.Length}")
                                SpawnLocation := vector3{X:=neighbor.X * 100.0, Y:=neighbor.Y * 100.0, Z:=75.0}
                                set SpawnedCubes += array{SpawnTarget(SpawnLocation, DebugCube)}
                                if(not openSet.Contains(neighbor) = true):
                                    set openSet += array{neighbor}
            else:
                Print("No path found")
                break

        Print("No path found")
        return (array{}, cameFrom)  # Return an empty path if no path is found

    # Reconstruct the path from the cameFrom map
    ReconstructPath(cameFrom: [string]Point, current: Point)<suspends>: []Point=
        var totalPath :[]Point= array{current}
        var LocalCurrent: Point = current
        loop:
            Sleep(1.0/29.0)
            Print("Reconstructing path")
            if(cameFrom.ContainsKey(LocalCurrent.UUID)=false):
                break
            if(set LocalCurrent = cameFrom[LocalCurrent.UUID]):
                set totalPath = array{LocalCurrent} + totalPath
        return totalPath
