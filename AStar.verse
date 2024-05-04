# using { /Verse.org/Simulation }

# (Points: []Point).Contains(point: Point)<transacts>: logic=
#     for(p: Points):
#         if(p.UUID = point.UUID):
#             return true
#     return false

# (Points: []Point).RemovPoint(P:Point): []Point=
#     var result: []Point = array{}
#     for(p: Points):
#         if(not p.UUID = P.UUID):
#             set result += array{p}
#     return result
# # Using A* for continuous space with MST edges
# AStarContinuous := class:
#     var Edges: []Edge = array{}

#     # Initialize with MST edges
#     Init(_Edges: []Edge): void=
#         set Edges = _Edges
#         Print("A* initialized with edges: {Edges.Length}")

#     # Heuristic function using Euclidean distance
#     Heuristic(node1: Point, node2: Point)<transacts>: float=
#         return Sqrt(Pow(node1.X - node2.X, 2.0) + Pow(node1.Y - node2.Y, 2.0))

#     # Get neighbors from MST edges
#     GetNeighbors(node: Point): []Point=
#         var neighbors: []Point = array{}
#         for(edge: Edges):
#             if(edge.Point1.UUID = node.UUID):
#                 set neighbors += array{edge.Point2}
#             else if(edge.Point2.UUID = node.UUID):
#                 set neighbors += array{edge.Point1}
#         return neighbors

#     # The core A* search algorithm
#     Search(start: Point, goal: Point): tuple([]Point,[string]Point )=
#         var openSet: []Point = array{start}
#         var cameFrom: [string]Point = map{}

#         var gScore: [string]float = map{}
#         var fScore: [string]float = map{}

#         if(set gScore[start.UUID] = 0.0):
#             if(set fScore[start.UUID] = Heuristic(start, goal)){}

#             loop:
#                 if(openSet.Length <= 0):
#                     Print("No path found")
#                     break
            
#                 # Find the node with the lowest fScore
#                 var current: Point = openSet.Get(0, CreatePoint(-1.0, -1.0))
#                 for(node : openSet):
#                     if(fScore[node.UUID] < fScore[current.UUID]):
#                         set current = node
            
#                 # Now remove the current node from the openSet
#                 set openSet = openSet.RemovPoint(current)
            
#                 if(current.UUID = goal.UUID):
#                     Print("Path found")
#                     return (ReconstructPath(cameFrom, current), cameFrom)
            
#                 # Explore neighbors
#                 var neighbors :[]Point= GetNeighbors(current)
#                 for(neighbor : neighbors):
#                     var tentativeGScore: float = gScore.Get(neighbor.UUID, 999999999.0) + Heuristic(current, neighbor)
#                     var currentGScore :float = gScore.Get(neighbor.UUID, 999999999.0)
                    
#                     if(tentativeGScore < currentGScore):
#                         # This path to neighbor is better than any previous one. Record it!
#                         if(set cameFrom[neighbor.UUID] = current){}
#                         if(set gScore[neighbor.UUID] = tentativeGScore){}
#                         if(set fScore[neighbor.UUID] = tentativeGScore + Heuristic(neighbor, goal)){}
            
#                         # Only add the neighbor to openSet if it isn't already there
#                         if(openSet.Contains(neighbor)= false):
#                             set openSet += array{neighbor}

#         Print("No path found")                                    
#         return (array{}, cameFrom)  # Return an empty path if no path is found

#     # Reconstruct the path from the cameFrom map
#     ReconstructPath(cameFrom: [string]Point, current: Point): []Point=
#         var totalPath :[]Point= array{current}
#         var LocalCurrent :Point= current
#         loop:
#             if(not cameFrom[current.UUID] ):
#                 break
#             if(set LocalCurrent = cameFrom[LocalCurrent.UUID],
#             set totalPath = array{LocalCurrent} + totalPath){}
#         return totalPath


