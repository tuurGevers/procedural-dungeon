using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }


CreatePoint(X: float, Y: float): Point :=
    return Point{X:=X,Y:=Y, UUID:=GenerateUUID(), ID:=X+Y}

Point := class:
    UUID: string
    var X: float
    var Y: float
    ID: float 


CreateDelaunayTriangle(A: Point, B: Point, C: Point, LinePropAsset:creative_prop_asset): DelaunayTriangle :=
    Triangle := DelaunayTriangle{A:=A,B:=B,C:=C, UUID:=GenerateUUID(), LinePropAsset:=LinePropAsset}
    Triangle.Init()
    return Triangle
    
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
    IsPointInside(P: Point)<transacts><decides>: void=
        # Compute the determinant of the matrix formed by the points
        Matrix := array{
            array{A.X - P.X, A.Y - P.Y, (Pow(A.X,2.0) - Pow(P.X,2.0)) + (Pow(A.Y,2.0) - Pow(P.Y,2.0))},
            array{B.X - P.X, B.Y - P.Y, (Pow(B.X,2.0) - Pow(P.X,2.0)) + (Pow(B.Y,2.0) - Pow(P.Y,2.0))},
            array{C.X - P.X, C.Y - P.Y, (Pow(C.X,2.0) - Pow(P.X,2.0)) + (Pow(C.Y,2.0) - Pow(P.Y,2.0))}
        }
        # Calculate the determinant
        Det := Determinant(Matrix)
        Print("Determinant for Point {P.X}, {P.Y} with Triangle {A.X}, {A.Y}, {B.X}, {B.Y}, {C.X}, {C.Y} is {Det}")

        # If the determinant is greater than zero, P is inside the circumcircle (for CCW orientation)
        Det > 0.0

    # Method to calculate the determinant of a 3x3 matrix
    Determinant(Matrix: [][]float)<transacts>: float=
        if(Det:=
            Matrix[0][0] * (Matrix[1][1] * Matrix[2][2] - Matrix[1][2] * Matrix[2][1]) -
            Matrix[0][1] * (Matrix[1][0] * Matrix[2][2] - Matrix[1][2] * Matrix[2][0]) +
            Matrix[0][2] * (Matrix[1][0] * Matrix[2][1] - Matrix[1][1] * Matrix[2][0])
        ):
            return Det
        else:
            return 0.0
    ## Method to draw the triangle edges as lines in the game world
    Draw(LineProp: creative_prop_asset): void=
        # Draw line from A to B
        DrawLine(A, B, LineProp)
        # Draw line from B to C
        DrawLine(B, C, LineProp)
        # Draw line from C to A
        DrawLine(C, A, LineProp)

    # Helper function to draw a line between two points using a specified prop asset
    DrawLine(Start: Point, End: Point, LineProp: creative_prop_asset): void=
        # Calculate midpoint for the line prop
        MidPointX := (Start.X + End.X) / 2.0
        MidPointY := (Start.Y + End.Y) / 2.0
        MidPointZ := 50.0  # Assuming a fixed height above ground
        SpawnLocation := vector3{X:=MidPointX, Y:=MidPointY, Z:=MidPointZ}

        # Calculate the distance between the points to set the scale of the line prop
        LineLength := Sqrt(Pow(End.X - Start.X, 2.0) + Pow(End.Y - Start.Y, 2.0))
        Scale := vector3{X:=LineLength / 100.0, Y:=0.1, Z:=0.1}  # Adjust Y and Z for thickness

        # Calculate the angle to rotate the line prop
        Angle := ArcTan(End.Y - Start.Y, End.X - Start.X)
        Rotation := MakeRotationFromYawPitchRollDegrees(0.0, 0.0, RadiansToDegrees(Angle))

        # Spawn the line prop at the calculated location with the appropriate rotation and scale
        Prop := SpawnTarget(SpawnLocation, LineProp, ?Scale := Scale)
        if(Prop.TeleportTo[SpawnLocation, Rotation]){}

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
    # Initialize by creating a super triangle
    Initialize(points: []Point): void=
        # Find bounds of all points (you might want to add some buffer or margin)
        Bounds:= CalculateBounds(points)
        MinX:= Bounds(0)
        MaxX:= Bounds(1)
        MinY := Bounds(2)
        MaxY  := Bounds(3)
        MidX := (MinX + MaxX) / 2.0  # Calculate the midpoint along X

        # Create a super triangle
        SuperTriangle := CreateDelaunayTriangle(
            CreatePoint((MinX - 10*1.0), (MinY - 10*1.0)),
            CreatePoint((MaxX + 10*1.0), (MinY - 10*1.0)),
            CreatePoint(MidX, MaxY + 10.0),
            LinePropAsset
        )
        SuperTriangle.Print()
        set Triangles = array{SuperTriangle}

    # Main function to process all points
    Triangulate(points: []Point): void=
        for(point :points):
            # Add each point to the triangulation
            AddPoint(point)

    

    # Add a point to the triangulation
    AddPoint(point: Point): void=
        var BadTriangles :[]DelaunayTriangle= array{}
        # Find all triangles that are no longer valid
        for(triangle :Triangles):
            if(triangle.IsPointInside[point]):
                set BadTriangles += array{triangle}

        
       # Assuming we are inside the AddPoint method after identifying BadTriangles
        var all_edges_count :[string]CountClass = map{}  # Dictionary to count edge appearances

        # Collect edges from BadTriangles and count each occurrence
        for(triangle :BadTriangles):
            edges := triangle.GetEdges()  # Ensure this method returns all edges of the triangle
            for(edge :edges):
                normalized_edge := normalize_edge(edge)
                Key:= "{normalized_edge(0).UUID}{normalized_edge(1).UUID}"
                if (all_edges_count[Key]):
                    if(set all_edges_count[Key].count += 1){}
                else:
                    if(set all_edges_count[Key] = CountClass{Point1:=normalized_edge(0), Point2:=normalized_edge(1)}){}

        # Identify boundary edges (edges appearing exactly once)
        var boundary_edges :[]tuple(Point, Point) = array{}
        for(edge->CClass :all_edges_count):
            if (CClass.count = 1):
                set boundary_edges += array{(CClass.Point1, CClass.Point2)}

        # Continue to re-triangulate using boundary_edges
        for(edge :boundary_edges):
            new_triangle := CreateDelaunayTriangle(edge(0), edge(1), point, LinePropAsset)
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
    DelaunayCondition(triangle1: DelaunayTriangle, triangle2: DelaunayTriangle): logic=
        # Implementation depends on checking circumcircles, omitted for brevity
        return false

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
    CalculateBounds(points: []Point): tuple(float, float, float, float)=
        if(points.Length = 0):
            return (0.0, 0.0, 0.0, 0.0)  # Return default bounds if no points are provided
    
        if(
            MinX: float = points[0].X,
            MaxX: float = points[0].X,
            MinY: float = points[0].Y,
            MaxY: float = points[0].Y
            ):
                #create variables to store the minimum and maximum bounds
                var TempMinX: float = MinX
                var TempMaxX: float = MaxX
                var TempMinY: float = MinY
                var TempMaxY: float = MaxY
    
                for(point :points):
                    if(point.X < MinX):
                        set TempMinX = point.X
                    if(point.X > MaxX):
                        set TempMaxX = point.X
                    if(point.Y < MinY):
                        set TempMinY = point.Y
                    if(point.Y > MaxY):
                        set TempMaxY = point.Y
            
                # Return an array containing the minimum and maximum bounds
                return (TempMinX, TempMaxX, TempMinY, TempMaxY)
        return (0.0, 0.0, 0.0, 0.0) 

        
    DrawTriangles(): void=
        Print("Drawing Triangles")
        for(I->triangle :Triangles):
            Print("Drawing Triangle {I}")
            triangle.Draw(LinePropAsset)

   