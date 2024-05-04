using { /Verse.org/Simulation }

CreateEdge(Point1:Point, Point2:Point):Edge=
    edge := Edge{
        Point1 := Point1,
        Point2 := Point2
    }
   
    edge.Init()
    return edge

ConverPointsToEdges(Points:[]tuple(Point,Point)):[]Edge=
    var edges :[]Edge= array{}
    for (point : Points):
        edge := CreateEdge(point(0), point(1))
        set edges += array{edge}
    return edges

Edge := class:
    Point1: Point;
    Point2: Point;
    var Weight: float = 0.0

    Init():void=
        set Weight = Sqrt(Pow((Point1.X*1.0 - Point2.X*1.0),2.0) + Pow((Point1.Y*1.0 - Point2.Y*1.0),2.0))

    #Print():void=
        #Print("Edge: , {Point1.X}- {Point1.Y},  -> , {Point2.X}-{Point2.Y},  Weight: , {Weight}")


SortEdgeFunction(Edge1: Edge, Edge2: Edge)<transacts>: int =
    if (Edge1.Weight < Edge2.Weight):
        1
    else if (Edge1.Weight  > Edge2.Weight):
        -1
    else:
        0

UnionFind := class:
    var Parent: []int = array{}
    var Rank: []int = array{}

    Init(size: int): void =
        set Parent = array{}
        set Rank = array{}
        for (i := 0.. size *2):
            set Parent += array{i}  # Initially, each element is its own parent
            set Rank += array{0}  # Initially, each element has a rank of 0

        Print("UnionFind Initialized with size: {size} parent: {Parent.Length}, Rank: {Rank.Length}")
    Find(x: int, ?Depth: int = 0)<transacts>: ?int =
        #Print("Finding root for: {x}, Depth: {Depth}")
        if (Parent[x] ):  # Ensure x is a valid index
            if (not Parent[x] = x):  # x is not the root
                # Find the root of the current component
                if(XParent:=Parent[x]):
                    Root := Find(XParent, ?Depth:= Depth + 1)
                    if (RootFound := Root?):  # Successfully found the root
                        # Path compression: set the parent of x directly to the root
                        if(set Parent[x] = RootFound){}
                        #Print("Path compression: Set parent of {x} to {RootFound}")
                        return option{RootFound}
                    return Root  # Pass the failure or false upward if root not found
            return option{Parent[x]}  # x is the root
        else:
            Print("Error: Index {x} not found in Parent array")                
        return false
    
    Union(x: int, y: int): void =
        RootX := Find(x)
        RootY := Find(y)
        if (rootXFound := RootX?, rootYFound := RootY?):  # Both roots must be found
            if (not rootXFound = rootYFound):  # Ensure different components
                # Union by rank
                if (Rank[rootXFound] > Rank[rootYFound]):
                    if(set Parent[rootYFound] = rootXFound):
                        Print("Union done between {x} and {y}, New Roots: {rootXFound}, {rootYFound}")
                else if (Rank[rootXFound] < Rank[rootYFound]):
                    if(set Parent[rootXFound] = rootYFound):
                        Print("Union done between {x} and {y}, New Roots: {rootXFound}, {rootYFound}")
                else:
                    if(set Parent[rootYFound] = rootXFound):
                        if(set Rank[rootXFound] += 1):
                            Print("Union done between {x} and {y}, New Roots: {rootXFound}, {rootYFound}")
                #Print("Union done between {x} and {y}, New Roots: {rootXFound}, {rootYFound}")
            else:
                Print("No union needed: {x} and {y} are already in the same component")
        else:
            Print("Error: in union: Could not find roots for {x} and/or {y}")
            


KruskalMST(Points:[]Point, Edges:[]tuple(Point,Point))<suspends>:[]Edge=
    var edges :[]Edge= ConverPointsToEdges(Edges)
    set edges = edges.QuickSort(SortEdgeFunction)
    uf := UnionFind{}
    uf.Init(Points.Length)
    var UUIDPointIndex: [string]int = map{}
    for (I->point : Points):
        if(set UUIDPointIndex[point.UUID] = I){}

    var mst :[]Edge= array{}
    TotalStartingEdges := edges.Length
    var IDFound:int = 0
    var SeperatePoints:int = 0

    for (edge : edges):
        if(IndexPoint1:=UUIDPointIndex[edge.Point1.UUID], IndexPoint2:=UUIDPointIndex[edge.Point2.UUID]):
            set IDFound += 1
            Found1 := uf.Find(IndexPoint1)
            Found2 := uf.Find(IndexPoint2)
            if (not  Found1= Found2):
                set SeperatePoints +=1
                uf.Union(IndexPoint1, IndexPoint2)
                set mst += array{edge}

    Print("Total Points: {Points.Length}, Total MST Edges: , {mst.Length} complexity = V- {Points.Length-mst.Length}")
    return mst