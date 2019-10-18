package minko.component;
import glm.Vec3;
import glm.Mat4;
import glm.Vec4;
import minko.data.Provider;
import minko.data.Store;
import minko.math.Box;
import minko.scene.Node;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
import minko.utils.MathUtil;
@:expose("minko.component.BoundingBox")
class BoundingBox extends AbstractComponent {
    private var _fixed:Bool;

    private var _box:Box;
    private var _worldSpaceBox:Box;

    private var _invalidBox:Bool;
    private var _invalidWorldSpaceBox:Bool;

    private var _targetAddedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _targetRemovedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _componentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _componentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _modelToWorldChangedSlot:SignalSlot3<Store, Provider, String>;

    public static function create() {
        var bb = new BoundingBox();

        return bb;
    }

    public static function createbySize(size, center:Vec3) {
        return createbyWHDC(size, size, size, center);
    }

    public static function createbyWHDC(width, height, depth, center:Vec3) {
        return createbyVector3(new Vec3(center.x - width * .5, center.y - height * .5, center.z - depth * .5), new Vec3(center.x + width * .5, center.y + height * .5, center.z + depth * .5));
    }

    public static function createbyVector3(topRight, bottomLeft) {
        var bb = new BoundingBox().setVector3(topRight, bottomLeft);

        return bb;
    }

    override public function clone(option) {
        var bbox = new BoundingBox();
        bbox.copyFrom(this);
        return bbox;
    }
    public var shape(get, null):Box;

    function get_shape() {
        return box;
    }

    public var box(get, null):Box;

    function get_box() {
        if (_invalidWorldSpaceBox) {
            updateWorldSpaceBox();
        }

        return _worldSpaceBox;
    }
    public var modelSpaceBox(get, null):Box;

    function get_modelSpaceBox() {
        if (_invalidBox) {
            update();
        }

        return _box;
    }

    public function update() {
        _invalidBox = false;

        var target = this.target ;

        if (!_fixed) {
            var surfaces:Array<Surface> = cast target.getComponents(Surface);

            var min = new Vec3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
            var max = new Vec3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

            if (surfaces.length > 0) {
                computeBox(surfaces, min, max);

                _box.bottomLeft = (min);
                _box.topRight = (max);
            }
            else {
                _box.bottomLeft = (new Vec3());
                _box.topRight = (new Vec3());
            }
        }

        _invalidWorldSpaceBox = true;
    }


    public function setVector3(topRight, bottomLeft) {
        this._fixed = true;
        this._box = Box.createbyVector3(topRight, bottomLeft);
        this._worldSpaceBox = Box.createbyVector3(topRight, bottomLeft);
        this._invalidBox = true;
        this._invalidWorldSpaceBox = true;
        return this;

    }

    public function new() {
        super();
        this._fixed = false;
        this._box = Box.create();
        this._worldSpaceBox = Box.create();
        this._invalidBox = true;
        this._invalidWorldSpaceBox = true;

    }

    public function copyFrom(bbox:BoundingBox, option:CloneOption = CloneOption.DEEP) {
        this._fixed = bbox._fixed;
        this._box = option == CloneOption.SHALLOW != null ? bbox._box : Box.createbyVector3(bbox._box.topRight, bbox._box.bottomLeft);
        this._worldSpaceBox = option == CloneOption.SHALLOW != null ? bbox._worldSpaceBox : Box.createbyVector3(bbox._worldSpaceBox.topRight, bbox._worldSpaceBox.bottomLeft);
        this._invalidBox = bbox._invalidBox;
        this._invalidWorldSpaceBox = bbox._invalidWorldSpaceBox;

    }

    private function updateWorldSpaceBox() {
        if (_invalidBox) {
            update();
        }

        _invalidWorldSpaceBox = false;

        if (!target.data.hasProperty("modelToWorldMatrix")) {
            _worldSpaceBox.topRight = (_box.topRight);
            _worldSpaceBox.bottomLeft = (_box.bottomLeft);
        }
        else {
            var t:Mat4 = target.data.get("modelToWorldMatrix");
            var vertices:Array<Vec3> = _box.getVertices();
            var numVertices = vertices.length;

            for (i in 0...numVertices) {
                var tmp:Vec4 =  t*(MathUtil.vec3_vec4(vertices[i], 1.0));
                vertices[i] = MathUtil.vec4_vec3(tmp);
            }

            var max = new Vec3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
            var min = new Vec3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);

            for (vertex in vertices) {
                if (vertex.x > max.x) {
                    max.x = vertex.x;
                }
                if (vertex.x < min.x) {
                    min.x = vertex.x;
                }

                if (vertex.y > max.y) {
                    max.y = vertex.y;
                }
                if (vertex.y < min.y) {
                    min.y = vertex.y;
                }

                if (vertex.z > max.z) {
                    max.z = vertex.z;
                }
                if (vertex.z < min.z) {
                    min.z = vertex.z;
                }
            }

            _worldSpaceBox.topRight = (max);
            _worldSpaceBox.bottomLeft = (min);
        }
    }

    private function computeBox(surfaces:Array<Surface >, min:Vec3, max:Vec3) {
        for (surface in surfaces) {
            var geom = surface.geometry;
            if (geom.hasVertexAttribute("position")) {
                var xyzBuffer = geom.vertexBuffer("position");
                var offset = xyzBuffer.attribute("position").offset;

                for (i in 0...xyzBuffer.numVertices) {
                    var x = xyzBuffer.data[i * xyzBuffer.vertexSize + offset];
                    var y = xyzBuffer.data[i * xyzBuffer.vertexSize + offset + 1];
                    var z = xyzBuffer.data[i * xyzBuffer.vertexSize + offset + 2];

                    if (x < min.x) {
                        min.x = x;
                    }
                    if (x > max.x) {
                        max.x = x;
                    }

                    if (y < min.y) {
                        min.y = y;
                    }
                    if (y > max.y) {
                        max.y = y;
                    }

                    if (z < min.z) {
                        min.z = z;
                    }
                    if (z > max.z) {
                        max.z = z;
                    }
                }
            }
            else {
                min = new Vec3(0.0, 0.0, 0.0);
                max = new Vec3(0.0, 0.0, 0.0);
            }
        }

    }
}
