package minko.data;
import haxe.ds.StringMap;
class HalfEdgeCollection {


    private var _indices:Array<Int>;
    private var _subMeshesList:Array<Array<HalfEdge>>;
    private var _halfEdges:Array<HalfEdge>;

    public static function create(indices:Array<Int>) {
        return new HalfEdgeCollection(indices);
    }

    public var subMeshesList(get, null):Array<Array<HalfEdge>>;

    function get_subMeshesList() {
        return _subMeshesList;
    }

    public var halfEdges:Array<HalfEdge>;

    function get_halfEdges() {
        return _halfEdges;
    }

    public function new(indices:Array<Int>) {
        this._indices = indices;
        initialize();
    }

    inline function make_pair(t, t1) {
        return t * 10000 + "_" + t1;
    }

    public function initialize() {
        var id = 0;
        var data = _indices;

        var map:StringMap<HalfEdge> = new StringMap<HalfEdge>();

        var i = 0;
        while (i < data.length) {
            var t1 = data[i];
            var t2 = data[i + 1];
            var t3 = data[i + 2];

            var he1 = HalfEdge.create(t1, t2, id++);
            var he2 = HalfEdge.create(t2, t3, id++);
            var he3 = HalfEdge.create(t3, t1, id++);

            _halfEdges.push(he1);
            _halfEdges.push(he2);
            _halfEdges.push(he3);

            var halfEdges:Array<HalfEdge> = [he1, he2, he3];

            for (edgeId in 0... 3) {
                halfEdges[edgeId].setFace(he1, he2, he3);
                halfEdges[edgeId].next = (halfEdges[(edgeId + 1) % 3]);
                halfEdges[edgeId].prec = (halfEdges[(edgeId - 1) + 3 * (edgeId - 1 < 0 ? 1 : 0)]);
            }

            map.set(make_pair(t1, t2), he1);
            map.set(make_pair(t2, t3), he2);
            map.set(make_pair(t3, t1), he3);

            var adjacents = [
                map.get(make_pair(t2, t1)),
                map.get(make_pair(t3, t2)),
                map.get(make_pair(t1, t3))];

            for (edgeId in 0...3) {
                if (adjacents[edgeId] == null) {
                    continue;
                }

                halfEdges[edgeId].adjacent = (adjacents[edgeId]);
                adjacents[edgeId].adjacent = (halfEdges[edgeId]);
            }
            i += 3;
        }

        //HalfEdgeMap unmarked(map.begin(), map.end());
        //computeList(unmarked);
    }

    public function computeList(unmarked:StringMap<HalfEdge>) {
        var queue:Array<HalfEdge> = new Array<HalfEdge>();

        for (unmark in unmarked) {
            var currentList = new Array<HalfEdge>();
            _subMeshesList.push(currentList);
            queue.push(unmark);

            do {
                var he = queue.pop();
                currentList.push(he);
                he.marked = (true);
                //todo
                unmarked.remove(make_pair(he.startNodeId, he.endNodeId));
                if (he.adjacent != null && he.adjacent.marked == false) {
                    var adjIt = unmarked.get(make_pair(he.adjacent.startNodeId, he.adjacent.endNodeId));
                    unmarked.remove(make_pair(he.adjacent.startNodeId, he.adjacent.endNodeId));
                    queue.push(he.adjacent);
                }
                if (he.next != null && he.next.marked == false) {
                    var adjIt = unmarked.get(make_pair(he.next.startNodeId, he.next.endNodeId));
                    unmarked.remove(make_pair(he.next.startNodeId, he.next.endNodeId));
                    queue.push(he.next);
                }
                if (he.prec != null && he.prec.marked == false) {
                    var adjIt = unmarked.get(make_pair(he.prec.startNodeId, he.prec.endNodeId));
                    unmarked.remove(make_pair(he.prec.startNodeId, he.prec.endNodeId));
                    queue.push(he.prec);
                }
            } while (queue.length > 0);
        }

        // debug
        trace("Submeshes : ");
        trace(_subMeshesList.length);
        trace("\n");
    }

}
