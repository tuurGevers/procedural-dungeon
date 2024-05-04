using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }


CreatePoint(X: int, Y: int)<transacts>: Point :=
    return Point{X:=X,Y:=Y, UUID:=GenerateUUID(), ID:=X+Y}

Point := class:
    UUID: string
    var X: int
    var Y: int
    ID: int 


CreateDelaunayTriangle(A: Point, B: Point, C: Point, LinePropAsset:creative_prop_asset): DelaunayTriangle :=
    Triangle := DelaunayTriangle{A:=A,B:=B,C:=C, UUID:=GenerateUUID(), LinePropAsset:=LinePropAsset}
    Triangle.Init()
    return Triangle
    
# Method to calculate the determinant of a 3x3 matrix
Determinant(Matrix: [][]int)<transacts>: int=
    if(Det:=
        Matrix[0][0] * (Matrix[1][1] * Matrix[2][2] - Matrix[1][2] * Matrix[2][1]) -
        Matrix[0][1] * (Matrix[1][0] * Matrix[2][2] - Matrix[1][2] * Matrix[2][0]) +
        Matrix[0][2] * (Matrix[1][0] * Matrix[2][1] - Matrix[1][1] * Matrix[2][0])
    ):
        return Det
    else:
        return 0

DelaunayTriangle := class:
    var A: Point
    var B: Point
    var C: Point

    var Edges: []tuple(Point, Point) = array{}
    UUID:string
    LinePropAsset : creative_prop_asset

    Init(): void=
        # Create edges from the vertices
        set Edges = array{(A, B), (B, C), (C, A)}

    Print():void=
        Print("Triangle with vertices {A.X}, {A.Y}, {B.X}, {B.Y}, {C.X}, {C.Y}")

    # Method to determine if point P is inside the circumcircle made by the triangle vertices A, B, C
    IsPointInside(P: Point)<transacts>: logic=
        # Compute the determinant of the matrix formed by the points
        Matrix := array{
            array{A.X - P.X, A.Y - P.Y, (A.X - P.X) * (A.X - P.X) + (A.Y - P.Y) * (A.Y - P.Y)},
            array{B.X - P.X, B.Y - P.Y, (B.X - P.X) * (B.X - P.X) + (B.Y - P.Y) * (B.Y - P.Y)},
            array{C.X - P.X, C.Y - P.Y, (C.X - P.X) * (C.X - P.X) + (C.Y - P.Y) * (C.Y - P.Y)}
        }
        Det := Determinant(Matrix)

        # If the determinant is greater than zero, P is inside the circumcircle (for CCW orientation)
        if(Det>0):
            return true
        else:
            return false

    
    ## Method to draw the triangle edges as lines in the game world
    # Draw(LineProp: creative_prop_asset)<suspends>: void=
    #     # Draw line from A to B
    #     DrawLine(A, B, LineProp)
    #     # Draw line from B to C
    #     DrawLine(B, C, LineProp)
    #     # Draw line from C to A
    #     DrawLine(C, A, LineProp)

   

(Edge1:tuple(Point,Point)).Equals(Edge2:tuple(Point,Point))<transacts><decides>: void=
    var IsEqual: logic = false
    if(Edge1(0).X = Edge2(0).X and Edge1(0).Y = Edge2(0).Y and Edge1(1).X = Edge2(1).X and Edge1(1).Y = Edge2(1).Y):
        set IsEqual = true
    IsEqual = true

(Triangle:DelaunayTriangle).contains_edge(edge: tuple(Point, Point))<transacts>: logic=
    # Check if this triangle has the given edge
    edges :[]tuple(Point, Point)= array{(Triangle.A, Triangle.B), (Triangle.B, Triangle.C), (Triangle.C, Triangle.A)}
    for(tri_edge :edges):
        if (edge.Equals[tri_edge]):
            return true
    return false

(Triangle:DelaunayTriangle).GetEdges(): []tuple(Point, Point)=
    return array{(Triangle.A, Triangle.B), (Triangle.B, Triangle.C), (Triangle.C, Triangle.A)}

CountClass:= class:
        var count:int = 0
        var Point1: Point
        var Point2: Point
DelaunayTriangulation := class:
    var Triangles: []DelaunayTriangle = array{}
    LinePropAsset : creative_prop_asset
    BossCube : creative_prop_asset

    # Initialize by creating a super triangle
    Initialize(points: []Point): []DelaunayTriangle=
        # Find bounds of all points (you might want to add some buffer or margin)
        Bounds:= CalculateBounds(points)
        MinX:= Bounds(0)
        MaxX:= Bounds(1)
        MinY := Bounds(2)
        MaxY  := Bounds(3)

        Print("Bounds: {MinX}, {MaxX}, {MinY}, {MaxY}")
        # SpawnTarget(vector3{X:=MinX, Y:=MinY, Z:=50.0}, BossCube, ?Scale:=vector3{X:=4.0, Y:=4.0, Z:=4.0})
        # SpawnTarget(vector3{X:=MaxX, Y:=MaxY, Z:=50.0}, BossCube, ?Scale:=vector3{X:=4.0, Y:=4.0, Z:=4.0})
        # Create a super triangle
       # Create two triangles from the bounding box
        Triangle1 := CreateDelaunayTriangle(
            CreatePoint(MinX, MinY),
            CreatePoint(MaxX, MinY),
            CreatePoint(MinX, MaxY),
            LinePropAsset
        )
        Triangle2 := CreateDelaunayTriangle(
            CreatePoint(MaxX, MinY),
            CreatePoint(MaxX, MaxY),
            CreatePoint(MinX, MaxY),
            LinePropAsset
        )

        # Add triangles to the triangulation list
        set Triangles = array{Triangle1, Triangle2}
        return Triangles

        

    # Main function to process all points
    Triangulate(points: []Point)<suspends>: []DelaunayTriangle=
        for(point :points):
            # Add each point to the triangulation
            AddPoint(point)

        # Print("Drawing Triangles")
        # for(I->triangle :Triangles):
        #     triangle.Draw(LinePropAsset)
        return Triangles
    

    # Add a point to the triangulation
    # Add a point to the triangulation
    AddPoint(point: Point): void=
        # Print("Processing new point: {point.X}, {point.Y}")
        var PointMap: [string]Point = map{}
        var BadTriangles :[]DelaunayTriangle= array{}
        # Find all triangles that are no longer valid
        for(triangle :Triangles):
            if(triangle.IsPointInside(point)= true):
                # Print("Point {point.X}, {point.Y} is inside triangle {triangle.UUID}")
                set BadTriangles += array{triangle}

        var edgeMap :[string]int = map{}  # Map to count edges

        # Collect edges from BadTriangles
        for(triangle :BadTriangles):
            for(edge : triangle.Edges):
                if(set PointMap[edge(0).UUID] = edge(0)){}
                if(set PointMap[edge(1).UUID] = edge(1)){}
                normalized_edge := normalize_edge(edge)
                edgeKey := "{normalized_edge(0).UUID}-{normalized_edge(1).UUID}"
                if (edgeMap[edgeKey]):
                    if(set edgeMap[edgeKey] += 1){}
                else:
                    if(set edgeMap[edgeKey] = 1){}
    
        # Identify boundary edges
        var boundary_edges :[]tuple(Point, Point) = array{}
        for(edgeKey-> count : edgeMap):
            if (count = 1):  # Boundary edges appear exactly once
                if(SPlitKeys:= edgeKey.Split("-"), Key1:=SPlitKeys[0], Key2:=SPlitKeys[1]):
                    if(Point1 := PointMap[Key1], Point2 := PointMap[Key2]):
                        edge := (Point1, Point2)
                        set boundary_edges += array{edge}
                        # Print("Boundary edge added: {edge(0).X}, {edge(0).Y} to {edge(1).X}, {edge(1).Y}")

        # Re-triangulate using boundary edges
        for(edge : boundary_edges):
            new_triangle := CreateDelaunayTriangle(edge(0), edge(1), point, LinePropAsset)
            # Print("New Triangle Created with vertices {edge(0).X}, {edge(0).Y}, {edge(1).X}, {edge(1).Y}, {point.X}, {point.Y}")
            set Triangles += array{new_triangle}
            # Consider edge flipping here or after all new triangles are added
            EdgeFlip(new_triangle)

    # Helper function to normalize an edge for consistent comparison
    normalize_edge(edge: tuple(Point, Point)): tuple(Point, Point)=
        if (edge(0).ID < edge(1).ID):
            return (edge(0), edge(1))
        else:
            return (edge(1), edge(0))

    # Function to flip an edge between two triangles
    flip_edge(edge: tuple(Point, Point), triangle1: DelaunayTriangle, triangle2: DelaunayTriangle): void=
        # Find the points opposite the shared edge in each triangle
        opposite1 := find_opposite_point(triangle1, edge)
        opposite2 := find_opposite_point(triangle2, edge)

        # Reconfigure the triangles to flip the edge
        # New edge will be between the opposite points
        # Update triangle1 to use new vertices
        set triangle1.A = opposite1
        set triangle1.B = opposite2
        set triangle1.C = edge(0)  # or edge(1), depending on your orientation choice

        # Update triangle2 to use new vertices
        set triangle2.A = opposite1
        set triangle2.B = opposite2
        set triangle2.C = edge(1)  # or edge(0)

    # Helper function to find the point opposite the shared edge in a triangle
    find_opposite_point(triangle: DelaunayTriangle, edge: tuple(Point, Point)): Point=
        if(not triangle.A.X = edge(0).X and not triangle.A.Y = edge(0).Y and not triangle.A.X = edge(1).X and not triangle.A.Y = edge(1).Y):
            return triangle.A
        else if  (not triangle.B.X = edge(0).X and not triangle.B.Y = edge(0).Y and not triangle.B.X = edge(1).X and not triangle.B.Y = edge(1).Y):
            return triangle.B
        else:
            return triangle.C
        # Edge flipping procedure
    EdgeFlip(new_triangle: DelaunayTriangle): void=
        for (edge : new_triangle.Edges):
            if(adjacent_triangle := find_adjacent_triangle(edge, new_triangle)?):
                Cond:=DelaunayCondition(new_triangle, adjacent_triangle)
                if (Cond=false ):
                    flip_edge(edge, new_triangle, adjacent_triangle)

    # Helper function to check the Delaunay condition between two triangles
    # Checks if the point P is inside the circumcircle of triangle ABC
    IsPointInsideCircumcircle(A: Point, B: Point, C: Point, P: Point)<transacts>: logic =
        Matrix := array{
            array{A.X - P.X, A.Y - P.Y, (A.X - P.X) * (A.X - P.X) + (A.Y - P.Y) * (A.Y - P.Y)},
            array{B.X - P.X, B.Y - P.Y, (B.X - P.X) * (B.X - P.X) + (B.Y - P.Y) * (B.Y - P.Y)},
            array{C.X - P.X, C.Y - P.Y, (C.X - P.X) * (C.X - P.X) + (C.Y - P.Y) * (C.Y - P.Y)}
        }
        Det := Determinant(Matrix)
        if(Det>0):
            return true
        else:
            return false

    # Delaunay condition between two triangles
    DelaunayCondition(triangle1: DelaunayTriangle, triangle2: DelaunayTriangle): logic =
        for ( point : array{triangle2.A, triangle2.B, triangle2.C}):
            if (IsPointInsideCircumcircle(triangle1.A, triangle1.B, triangle1.C, point)=true):
                return false
        return true


    # Helper function to find the adjacent triangle for a given edge
    find_adjacent_triangle(edge: tuple(Point, Point), calling_triangle: DelaunayTriangle)<transacts>: ?DelaunayTriangle=
        for(triangle :Triangles):
            if ((not triangle.UUID = calling_triangle.UUID) and triangle.contains_edge(edge)):
                return option{triangle}
        return false

    FindTriangle(needle: DelaunayTriangle, haystack: []DelaunayTriangle)<transacts>: int=
        for(i-> triangle :haystack):
            if(triangle.UUID = needle.UUID):
                return i
        return -1
    # Helper function to remove a triangle from the list
    Remove(triangleList: []DelaunayTriangle, triangle: DelaunayTriangle): logic=

        Index := FindTriangle(triangle, triangleList)
        if(not Index = -1):
            Delete(triangleList, Index)
            return true
        return false


    Delete(list: []DelaunayTriangle, index: int): logic=
        if(index < 0 or index >=list.Length):
            return false
        if(NewArr:= list.RemoveElement[index]):
            set Triangles = NewArr
        return true

    # Helper function to calculate the bounds of a set of points
    CalculateBounds(points: []Point): tuple(int, int, int, int)=
        if(points.Length = 0):
            return (0, 0, 0, 0)  # Return default bounds if no points are provided
    
        if(
            MinX:= points[0].X,
            MaxX:= points[0].X,
            MinY:= points[0].Y,
            MaxY:= points[0].Y
            ):
                #create variables to store the minimum and maximum bounds
                var TempMinX: int = MinX
                var TempMaxX: int = MaxX
                var TempMinY: int = MinY
                var TempMaxY: int = MaxY
    
                for(point :points):
                    if(point.X < TempMinX):
                        set TempMinX = point.X
                    if(point.X > TempMaxX):
                        set TempMaxX = point.X
                    if(point.Y < TempMinY):
                        set TempMinY = point.Y
                    if(point.Y > TempMaxY):
                        set TempMaxY = point.Y
            
                # Return an array containing the minimum and maximum bounds
                return (TempMinX, TempMaxX, TempMinY, TempMaxY)
        return (0, 0, 0, 0) 

        
        

   