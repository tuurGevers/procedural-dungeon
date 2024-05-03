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
        set Weight = Sqrt(Pow((Point1.X - Point2.X),2.0) + Pow((Point1.Y - Point2.Y),2.0))

    Print():void=
        Print("Edge: , {Point1.X}- {Point1.Y},  -> , {Point2.X}-{Point2.Y},  Weight: , {Weight}")


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
        set Parent = array{size}
        set Rank = array{size}
        for (i := 0.. size - 1):
            if(set Parent[i] = i ){} # Initially, each element is its own parent
            if(set Rank[i] = 0){}

    Find(x: int)<transacts>: int =
        if( not Parent[x] = x):
            if(Found:= Find(Parent[x]) , set Parent[x] =Found){}  # Path compression
        if(F:=Parent[x]):
            return F
        return -1

    Union(x: int, y: int): void =
        rootX := Find(x)
        rootY := Find(y)
        if(not rootX = rootY):
            if (Rank[rootX] > Rank[rootY]):
                if(set Parent[rootY] = rootX){}
            else if (Rank[rootX] < Rank[rootY]):
                if(set Parent[rootX] = rootY){}
            else:
                if(set Parent[rootY] = rootX){}
                if(set Rank[rootX] += 1){}


KruskalMST(Points:[]Point, Edges:[]tuple(Point,Point)):[]Edge=
    var edges :[]Edge= ConverPointsToEdges(Edges)
    set edges = edges.QuickSort(SortEdgeFunction)
    uf := UnionFind{}
    uf.Init(Points.Length)
    var UUIDPointIndex: [string]int = map{}
    for (I->point : Points):
        if(set UUIDPointIndex[point.UUID] = I){}

    var mst :[]Edge= array{}
    for (edge : edges):
        if(IndexPoint1:=UUIDPointIndex[edge.Point1.UUID], IndexPoint2:=UUIDPointIndex[edge.Point2.UUID]):
            if (not uf.Find(IndexPoint1) = uf.Find(IndexPoint2)):
                uf.Union(IndexPoint1, IndexPoint2)
                set mst += array{edge}
                edge.Print()  # Optionally print the edge being added to MST

    return mst