package minko.render;
import minko.signal.Signal;
class IndexBuffer extends AbstractResource {
    private var _data:Array<Int> ;
    private var _numIndices:Int;
    private var _changed:Signal<IndexBuffer>;

    public static function create(context:AbstractContext):IndexBuffer {
        return new IndexBuffer(context);
    }

    public static function createbyData(context, data):IndexBuffer {
        var ptr = new IndexBuffer(context);
        ptr.data = data;
        ptr.upload();

        return ptr;
    }
    public var data(get, set):Array<Int>;

    function get_data() {
        return _data;
    }

    function set_data(v) {
        _data = v;
        return _data;
    }

    public var dataPointer(get, null):Array<Int>;

    function get_dataPointer() {
        return _data;
    }
    public var numIndices(get, null):Int;

    function get_numIndices() {
        return _numIndices;
    }

    override public function upload() {
        uploadOffset();
    }


    public function uploadOffset(offset = 0, count = -1) {
        if (data.length == 0) {
            return;
        }

//Debug.Assert(count <= (int)data().Count);

        if (_id == -1) {
            _id = _context.createIndexBuffer(data.length);
        }

        var oldNumIndices = _numIndices;
        _numIndices = count > 0 ? count : data.length;

        _context.uploaderIndexBufferData(_id, offset, _numIndices, data);//[offset]);

        if (_numIndices != oldNumIndices) {
            _changed.execute(this);
        }
    }

    public function uploadOffsetData(offset, count, data:Array<Int>) {
        if (data.length == 0) {
            return;
        }

//Debug.Assert(count <= (int)data.Count);

        if (_id == -1) {
            _id = _context.createIndexBuffer(data.length);
        }

        var numIndices = count > 0 ? count : data.length;
        _numIndices = numIndices;

        _context.uploaderIndexBufferData(_id, offset, numIndices, data);

        _changed.execute(this);
    }

    override public function dispose() {

        if (_id != -1) {
            _context.deleteIndexBuffer(_id);
        }

        _id = -1;
        _numIndices = 0;

        disposeData();

        _changed.execute(null);
    }

    public function disposeData() {

        if (_data != null) {
            _data = null;
        }

    }

    public function equals(indexBuffer:IndexBuffer) {
        return dataPointer == indexBuffer.dataPointer;
    }

    public var changed(get, null):Signal<IndexBuffer>;

    function get_changed() {
        return _changed;
    }

    public function new(context:AbstractContext) {
        super(context);
        this._data = [];
        this._numIndices = 0;
        this._changed = new Signal<IndexBuffer>();
    }


}
