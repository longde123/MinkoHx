package minko.render;
import glm.Vec4;
import minko.data.Binding.Source;
import minko.data.Provider;

class States {

    public static inline var PROPERTY_PRIORITY = "priority";
    public static inline var PROPERTY_ZSORTED = "zSorted";
    public static inline var PROPERTY_BLENDING_SOURCE = "blendingSource";
    public static inline var PROPERTY_BLENDING_DESTINATION = "blendingDestination";
    public static inline var PROPERTY_COLOR_MASK = "colorMask";
    public static inline var PROPERTY_DEPTH_MASK = "depthMask";
    public static inline var PROPERTY_DEPTH_FUNCTION = "depthFunction";
    public static inline var PROPERTY_TRIANGLE_CULLING = "triangleCulling";
    public static inline var PROPERTY_STENCIL_FUNCTION = "stencilFunction";
    public static inline var PROPERTY_STENCIL_REFERENCE = "stencilReference";
    public static inline var PROPERTY_STENCIL_MASK = "stencilMask";
    public static inline var PROPERTY_STENCIL_FAIL_OPERATION = "stencilFailOperation";
    public static inline var PROPERTY_STENCIL_ZFAIL_OPERATION = "stencilZFailOperation";
    public static inline var PROPERTY_STENCIL_ZPASS_OPERATION = "stencilZPassOperation";
    public static inline var PROPERTY_SCISSOR_TEST = "scissorTest";
    public static inline var PROPERTY_SCISSOR_BOX = "scissorBox";
    public static inline var PROPERTY_TARGET = "target";
    public static var PROPERTY_NAMES:Array<String> = [
        PROPERTY_PRIORITY,
        PROPERTY_ZSORTED,
        PROPERTY_BLENDING_SOURCE,
        PROPERTY_BLENDING_DESTINATION,
        PROPERTY_COLOR_MASK,
        PROPERTY_DEPTH_MASK,
        PROPERTY_DEPTH_FUNCTION,
        PROPERTY_TRIANGLE_CULLING,
        PROPERTY_STENCIL_FUNCTION,
        PROPERTY_STENCIL_REFERENCE,
        PROPERTY_STENCIL_MASK,
        PROPERTY_STENCIL_FAIL_OPERATION,
        PROPERTY_STENCIL_ZFAIL_OPERATION,
        PROPERTY_STENCIL_ZPASS_OPERATION,
        PROPERTY_SCISSOR_TEST,
        PROPERTY_SCISSOR_BOX,
        PROPERTY_TARGET
    ];
    public static var DEFAULT_PRIORITY = Priority.OPAQUE;
    public static inline var DEFAULT_ZSORTED = false;
    public static inline var DEFAULT_BLENDING_SOURCE = Blending.Source.ONE;
    public static inline var DEFAULT_BLENDING_DESTINATION = Blending.Destination.ZERO;
    public static inline var DEFAULT_COLOR_MASK = true;
    public static inline var DEFAULT_DEPTH_MASK = true;
    public static inline var DEFAULT_DEPTH_FUNCTION = (CompareMode.LESS);
    public static inline var DEFAULT_TRIANGLE_CULLING = (TriangleCulling.BACK);
    public static inline var DEFAULT_STENCIL_FUNCTION = (CompareMode.ALWAYS);
    public static inline var DEFAULT_STENCIL_REFERENCE = 0;
    public static inline var DEFAULT_STENCIL_MASK = 1;
    public static inline var DEFAULT_STENCIL_FAIL_OPERATION = (StencilOperation.KEEP);
    public static inline var DEFAULT_STENCIL_ZFAIL_OPERATION = (StencilOperation.KEEP);
    public static inline var DEFAULT_STENCIL_ZPASS_OPERATION = (StencilOperation.KEEP);
    public static inline var DEFAULT_SCISSOR_TEST = false;
    public static var DEFAULT_SCISSOR_BOX = new Vec4();
    public static var DEFAULT_TARGET:Texture = null;

    public static var UNSET_PRIORITY_VALUE = Math.NEGATIVE_INFINITY;
    private var _data:Provider;

    static public function createbyProvider(a:Provider) {
        var s = new States();
        s.data = (a);
        return s;
    }

    public function new(priority:Priority = null, zSorted = DEFAULT_ZSORTED, blendingSourceFactor = DEFAULT_BLENDING_SOURCE, blendingDestinationFactor = DEFAULT_BLENDING_DESTINATION, colorMask = DEFAULT_COLOR_MASK, depthMask = DEFAULT_DEPTH_MASK, depthFunction = DEFAULT_DEPTH_FUNCTION, triangleCulling = DEFAULT_TRIANGLE_CULLING, stencilFunction = DEFAULT_STENCIL_FUNCTION, stencilRef = DEFAULT_STENCIL_REFERENCE, stencilMask = DEFAULT_STENCIL_MASK, stencilFailOp = DEFAULT_STENCIL_FAIL_OPERATION, stencilZFailOp = DEFAULT_STENCIL_ZFAIL_OPERATION, stencilZPassOp = DEFAULT_STENCIL_ZPASS_OPERATION, scissorTest = DEFAULT_SCISSOR_TEST, ?scissorBox:Vec4 = null, ?target:Texture = null) {
        this._data = Provider.create() ;
        //resetDefaultValues();

        this.priority = (priority == null ? DEFAULT_PRIORITY : priority);
        this.zSorted = (zSorted);
        this.blendingSourceFactor = (blendingSourceFactor);
        this.blendingDestinationFactor = (blendingDestinationFactor);
        this.colorMask = (colorMask);
        this.depthMask = (depthMask);
        this.depthFunction = (depthFunction);
        this.triangleCulling = (triangleCulling);
        this.stencilFunction = (stencilFunction);
        this.stencilReference = (stencilRef);
        this.stencilMask = (stencilMask);
        this.stencilFailOperation = (stencilFailOp);
        this.stencilZFailOperation = stencilZFailOp;
        this.stencilZPassOperation = (stencilZPassOp);
        this.scissorTest = (scissorTest);
        this.scissorBox = (scissorBox == null ? DEFAULT_SCISSOR_BOX : scissorBox);
        this.target = (target == null ? DEFAULT_TARGET : target);
    }

    public function copyFrom(states:States) {
        this._data = Provider.createbyProvider(states._data) ;
        return this;
    }


    public function resetDefaultValues() {
        _data.set(PROPERTY_PRIORITY, DEFAULT_PRIORITY);
        _data.set(PROPERTY_ZSORTED, DEFAULT_ZSORTED);
        _data.set(PROPERTY_BLENDING_SOURCE, DEFAULT_BLENDING_SOURCE);
        _data.set(PROPERTY_BLENDING_DESTINATION, DEFAULT_BLENDING_DESTINATION);
        _data.set(PROPERTY_COLOR_MASK, DEFAULT_COLOR_MASK);
        _data.set(PROPERTY_DEPTH_MASK, DEFAULT_DEPTH_MASK);
        _data.set(PROPERTY_DEPTH_FUNCTION, DEFAULT_DEPTH_FUNCTION);
        _data.set(PROPERTY_TRIANGLE_CULLING, DEFAULT_TRIANGLE_CULLING);
        _data.set(PROPERTY_STENCIL_FUNCTION, DEFAULT_STENCIL_FUNCTION);
        _data.set(PROPERTY_STENCIL_REFERENCE, DEFAULT_STENCIL_REFERENCE);
        _data.set(PROPERTY_STENCIL_MASK, DEFAULT_STENCIL_MASK);
        _data.set(PROPERTY_STENCIL_FAIL_OPERATION, DEFAULT_STENCIL_FAIL_OPERATION);
        _data.set(PROPERTY_STENCIL_ZFAIL_OPERATION, DEFAULT_STENCIL_ZFAIL_OPERATION);
        _data.set(PROPERTY_STENCIL_ZPASS_OPERATION, DEFAULT_STENCIL_ZPASS_OPERATION);
        _data.set(PROPERTY_SCISSOR_TEST, DEFAULT_SCISSOR_TEST);
        _data.set(PROPERTY_SCISSOR_BOX, DEFAULT_SCISSOR_BOX);
        _data.set(PROPERTY_TARGET, DEFAULT_TARGET);
    }

    public var data(get, set):Provider;

    function get_data() {
        return _data;
    }

    function set_data(v) {
        _data = v;
        return v;
    }

    public var priority(get, set):Float;

    function get_priority() {
        return _data.get(PROPERTY_PRIORITY);
    }

    function set_priority(priority) {
        _data.set(PROPERTY_PRIORITY, priority);

        return priority;
    }

    public var zSorted(get, set):Bool;

    function get_zSorted() {
        return _data.get(PROPERTY_ZSORTED);
    }

    function set_zSorted(zSorted) {
        _data.set(PROPERTY_ZSORTED, zSorted);

        return zSorted;
    }

    public var blendingSourceFactor(get, set):Blending.Source;

    function get_blendingSourceFactor() {
        return _data.get(PROPERTY_BLENDING_SOURCE);
    }


    function set_blendingSourceFactor(value) {
        _data.set(PROPERTY_BLENDING_SOURCE, value);

        return value;
    }
    public var blendingDestinationFactor(get, set):Blending.Destination;

    function get_blendingDestinationFactor() {
        return _data.get(PROPERTY_BLENDING_DESTINATION);
    }

    function set_blendingDestinationFactor(value) {
        _data.set(PROPERTY_BLENDING_DESTINATION, value);

        return value;
    }

    public var colorMask(get, set):Bool;

    function get_colorMask() {
        return _data.get(PROPERTY_COLOR_MASK);
    }

    function set_colorMask(value) {
        _data.set(PROPERTY_COLOR_MASK, value);

        return value;
    }
    public var depthMask(get, set):Bool;

    function get_depthMask() {
        return _data.get(PROPERTY_DEPTH_MASK);
    }

    function set_depthMask(value) {
        _data.set(PROPERTY_DEPTH_MASK, value);

        return value;
    }

    public var depthFunction(get, set):CompareMode;

    function get_depthFunction() {
        return _data.get(PROPERTY_DEPTH_FUNCTION);
    }

    function set_depthFunction(value) {
        _data.set(PROPERTY_DEPTH_FUNCTION, value);

        return value;
    }

    public var triangleCulling(get, set):TriangleCulling;

    function get_triangleCulling() {
        return _data.get(PROPERTY_TRIANGLE_CULLING);
    }

    function set_triangleCulling(value) {
        _data.set(PROPERTY_TRIANGLE_CULLING, value);

        return value;
    }
    public var stencilFunction(get, set):CompareMode;

    function get_stencilFunction() {
        return _data.get(PROPERTY_STENCIL_FUNCTION);
    }

    function set_stencilFunction(value) {
        _data.set(PROPERTY_STENCIL_FUNCTION, value);

        return value;
    }

    public var stencilReference(get, set):Int;

    function get_stencilReference() {
        return _data.get(PROPERTY_STENCIL_REFERENCE);
    }

    function set_stencilReference(value) {
        _data.set(PROPERTY_STENCIL_REFERENCE, value);

        return value;
    }

    public var stencilMask(get, set):Int;

    function get_stencilMask() {
        return _data.get(PROPERTY_STENCIL_MASK);
    }


    function set_stencilMask(value) {
        _data.set(PROPERTY_STENCIL_MASK, value);

        return value;
    }
    public var stencilFailOperation(get, set):StencilOperation;

    function get_stencilFailOperation() {
        return _data.get(PROPERTY_STENCIL_FAIL_OPERATION);
    }

    function set_stencilFailOperation(value) {
        _data.set(PROPERTY_STENCIL_FAIL_OPERATION, value);

        return value;
    }
    public var stencilZFailOperation(get, set):StencilOperation;

    function get_stencilZFailOperation() {
        return _data.get(PROPERTY_STENCIL_ZFAIL_OPERATION);
    }

    function set_stencilZFailOperation(value) {
        _data.set(PROPERTY_STENCIL_ZFAIL_OPERATION, value);

        return value;
    }
    public var stencilZPassOperation(get, set):StencilOperation;

    function get_stencilZPassOperation() {
        return _data.get(PROPERTY_STENCIL_ZPASS_OPERATION);
    }

    function set_stencilZPassOperation(value) {
        _data.set(PROPERTY_STENCIL_ZPASS_OPERATION, value);

        return value;
    }
    public var scissorTest(get, set):Bool;

    function get_scissorTest() {
        return _data.get(PROPERTY_SCISSOR_TEST);
    }

    function set_scissorTest(value) {
        _data.set(PROPERTY_SCISSOR_TEST, value);

        return value;
    }
    public var scissorBox(get, set):Vec4;

    function get_scissorBox() {
        return _data.get(PROPERTY_SCISSOR_BOX);
    }

    function set_scissorBox(value) {
        _data.set(PROPERTY_SCISSOR_BOX, value);

        return value;
    }
    public var target(get, set):AbstractTexture ;

    function get_target() {
        return _data.get(PROPERTY_TARGET);
    }

    function set_target(target) {
        _data.set(PROPERTY_TARGET, target);

        return target;
    }

}
