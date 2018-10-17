package minko.render;
import glm.Vec3;
import minko.signal.Signal2;

class VertexBuffer extends AbstractResource {
    private var _data:Array<Float>;
    private var _attributes:Array<VertexAttribute>;
    private var _vertexSize:Int;
    private var _vertexSizeChanged:Signal2<VertexBuffer, Int> ;

    public static function create(context:AbstractContext):VertexBuffer {
        return new VertexBuffer(context);
    }

    public static function createbyVec3Data(context:AbstractContext, data:Array<Vec3>, len:Int):VertexBuffer {
        var ptr = new VertexBuffer(context);
        ptr.data = [];
        for (d in data) {
            ptr.data.push(d.x);
            ptr.data.push(d.y);
            ptr.data.push(d.z);
        }
        ptr.upload();
        return ptr;
    }

    public static function createbyData(context:AbstractContext, data:Array<Float>):VertexBuffer {
        var ptr = new VertexBuffer(context);
        ptr.data = data;
        ptr.upload();
        return ptr;
    }
    public var data(get, set):Array<Float>;

    function set_data(v) {
        _data = v;
        return v;
    }

    function get_data() {
        return _data;
    }
    public var attributes(get, null):Array<VertexAttribute>;

    function get_attributes() {
        return _attributes;
    }
    public var vertexSize(get, set):Int;

    function get_vertexSize() {
        return _vertexSize;
    }

    function set_vertexSize(value) {
        var offset = value - _vertexSize;
        _vertexSize = value;
        _vertexSizeChanged.execute(this, offset);
        return value;
    }
    public var vertexSizeChanged(get, null):Signal2<VertexBuffer, Int>;

    function get_vertexSizeChanged() {
        return _vertexSizeChanged;
    }

    public var numVertices(get, null):Int;

    function get_numVertices() {
        return _vertexSize > 0 ? Math.floor(_data.length / _vertexSize) : 0;
    }

    override public function upload() {
        uploadOffset(0, 0);
    }

    public function uploadOffset(offset, numVertices = 0) {
        if (_data.length == 0) {
            return;
        }

        if (_id == -1) {
            _id = _context.createVertexBuffer(_data.length);
        }

        _context.uploadVertexBufferData(_id, offset * _vertexSize, numVertices == 0 ? _data.length : numVertices * _vertexSize, _data);

        //updatePositionBounds();
    }

    public function uploadData(offset, numVertices, data:Array<Float>) {
        if (data.length == 0) {
            return;
        }

        if (_id == -1) {
            _id = _context.createVertexBuffer(data.length);
        }

        _context.uploadVertexBufferData(_id, offset * _vertexSize, numVertices == 0 ? data.length : numVertices * _vertexSize, data);
    }

    override public function dispose() {
        if (_id != -1) {
            _context.deleteVertexBuffer(_id);
            _id = -1;
        }

        disposeData();
    }

    public function disposeData() {
        _data = null;
    }

    public function addAttribute(name, size, offset = 0) {
        if (hasAttribute(name)) {
            throw ("name");
        }

        var actualOffset = offset;
        if (actualOffset == 0) {
            actualOffset = _vertexSize;
        }

        _attributes.push(new VertexAttribute(_id, _vertexSize, name, size, actualOffset));
        vertexSize = (_vertexSize + size);
        _attributes = _attributes.map(function(a:VertexAttribute) {
            a.vertexSize = vertexSize;
            return a;
        });

    }

    public function removeAttribute(attributeName) {

        var it:VertexAttribute = Lambda.find(_attributes, function(attr:VertexAttribute) {
            return attr.name == attributeName;
        });

        if (it == null) {
            throw ("attributeName = " + attributeName);
        }

        vertexSize = (_vertexSize - it.size);
        _attributes.remove(it);
        _attributes = _attributes.map(function(a:VertexAttribute) {
            a.vertexSize = vertexSize;
            return a;
        });
    }


    public function hasAttribute(attributeName) {
        var it = Lambda.exists(_attributes, function(attr:VertexAttribute) {
            return attr.name == attributeName;
        });

        return it ;
    }

    public function attribute(attributeName):VertexAttribute  {
        var it:VertexAttribute = Lambda.find(_attributes, function(attr:VertexAttribute) {
            return attr.name == attributeName;
        });

        if (it == null) {
            throw ("attributeName = " + attributeName);
        }

        return it;
    }

    public function equals(vertexBuffer:VertexBuffer) {
        return _data == vertexBuffer._data;
    }

    public function new(context:AbstractContext) {
        super(context);
        this._data = [];
        this._attributes = [];
        this._vertexSize = 0;
        this._vertexSizeChanged = new Signal2<VertexBuffer, Int>();

    }

}
