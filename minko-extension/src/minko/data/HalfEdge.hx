package minko.data;
class HalfEdge {

    public static function create(startNodeId, endNodeId, edgeId) {
        var instance = new HalfEdge(startNodeId, endNodeId, edgeId);

        return instance;
    }

    private var _startNodeId:Int;
    private var _endNodeId:Int;
    private var _edgeId:Int;
    private var _next:HalfEdge;
    private var _prec:HalfEdge;
    private var _adjacent:HalfEdge;
    private var _face:Array<HalfEdge>;
    private var _firstReverseFace:Array<HalfEdge>;
    private var _secondReverseFace:Array<HalfEdge>;
    private var _marked:Bool;

    public function new(startNodeId=0, endNodeId=0, edgeId=0) {
        this._startNodeId = startNodeId;
        this._endNodeId = endNodeId;
        this._edgeId = edgeId;
        this._marked = false;
        this._adjacent = new HalfEdge();
        this._next = new HalfEdge();
        this._prec = new HalfEdge();
    }

    public function indiceInEdge(indice) {
        return indice == _startNodeId || indice == _endNodeId;
    }

    public function indiceInFace(indice) {
        return indice == _face[0].startNodeId || indice == _face[1].startNodeId || indice == _face[2].startNodeId;
    }

    public function getThirdVertex() {
        for (i in 0...3) {
            if (_face[i].startNodeId != _startNodeId && _face[i].startNodeId != _endNodeId) {
                return _face[i].startNodeId;
            }
        }

        return 0;
    }

    public function setFace(he1, he2, he3) {
        _face.push(he1);
        _face.push(he2);
        _face.push(he3);
    }
    public var marked(get, set):Bool;

    function get_marked() {
        return _marked;
    }

    public var startNodeId(get, null):Int;

    function get_startNodeId() {
        return _startNodeId;
    }

    function set_marked(value) {
        _marked = value;
        return value;
    }

    public var endNodeId(get, null):Int;

    function get_endNodeId() {
        return _endNodeId;
    }
    public var edgeId(get, null):Int;

    function get_edgeId() {
        return _edgeId;
    }

    public var next(get, set):HalfEdge;

    function get_next() {
        return _next;
    }

    function set_next(value) {
        _next = value;
        return value;
    }

    public var prec(get, set):HalfEdge;

    function get_prec() {
        return _prec;
    }

    function set_prec(value) {
        _prec = value;
        return value;
    }

    public var adjacent(get, set):HalfEdge;

    function get_adjacent() {
        return _adjacent;
    }

    function set_adjacent(value) {
        _adjacent = value;
        return value;
    }
    public var face(get, null):Array<HalfEdge>;

    function get_face() {
        return _face;
    }

    public var secondReverseFace(get, null):Array<HalfEdge>;


    function get_secondReverseFace() {
        if (_secondReverseFace.length == 0) {
            _secondReverseFace.push(_face[2]);
            _secondReverseFace.push(_face[0]);
            _secondReverseFace.push(_face[1]);
        }

        return _secondReverseFace;
    }
    public var firstReverseFace(get, null):Array<HalfEdge>;

    function get_firstReverseFace() {
        if (_firstReverseFace.length == 0) {
            _firstReverseFace.push(_face[1]);
            _firstReverseFace.push(_face[2]);
            _firstReverseFace.push(_face[0]);
        }

        return _firstReverseFace;
    }
}
