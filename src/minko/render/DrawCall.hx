package minko.render;
import Array;
import glm.Mat4;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.StringMap;
import minko.component.Renderer.EffectVariables;
import minko.data.Binding;
import minko.data.Provider;
import minko.data.ResolvedBinding;
import minko.data.Store;
import minko.render.Blending.Destination;
import minko.render.Blending.Source;
import minko.render.ProgramInputs.AttributeInput;
import minko.render.ProgramInputs.UniformInput;
import minko.signal.Signal3.SignalSlot3;
import minko.utils.MathUtil;
import minko.Uuid.Enable_uuid;
typedef ConstUniformInputRef = UniformInput ;
typedef ConstAttrInputRef = AttributeInput ;

class UniformValue<T> {
    public var location:Int;
    public var size:Int;
    public var count:Int;
    public var data:Any;//记录原值
    public var dataArray:Array<T>;

    public function new(location:Int, size:Int, count:Int, dataArray:Array<T>) {
        this.location = location;
        this.size = size;
        this.count = count;
        this.dataArray = dataArray ;
    }

    static public function vecInts1(dataValue:Int) {
        return [dataValue];
    }

    static public function vecInts2(dataValue:Vec2) {
        return  dataValue.toFloatArray().map(function(v) return Math.floor(v));
    }

    static public function vecInts3(dataValue:Vec3) {
        return  dataValue.toFloatArray().map(function(v) return Math.floor(v));
    }

    static public function vecInts4(dataValue:Vec4) {
        return dataValue.toFloatArray().map(function(v) return Math.floor(v));
    }

    static public function vecFloats1(dataValue:Float) {
        return [dataValue];
    }

    static public function vecFloats2(dataValue:Vec2) {
        return  dataValue.toFloatArray();
    }

    static public function vecFloats3(dataValue:Vec3) {
        return dataValue.toFloatArray();
    }

    static public function vecFloats4(dataValue:Vec4) {
        return dataValue.toFloatArray();
    }

    static public function matFloats(dataValue:Mat4) {
        return dataValue.toFloatArray();
    }


    static public function vecsInts1(dataValue:Array<Int>) {
        return dataValue;
    }

    static public function vecsInts2(dataValue:Array<Vec2>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecInts2(d));
        }
        return tmp;
    }

    static public function vecsInts3(dataValue:Array<Vec3>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecInts3(d));
        }
        return tmp;
    }

    static public function vecsInts4(dataValue:Array<Vec4>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecInts4(d));
        }
        return tmp;
    }

    static public function vecsFloats1(dataValue:Array<Float>) {
        return dataValue;
    }

    static public function vecsFloats2(dataValue:Array<Vec2>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecFloats2(d));
        }
        return tmp;
    }

    static public function vecsFloats3(dataValue:Array<Vec3>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecFloats3(d));
        }
        return tmp;
    }

    static public function vecsFloats4(dataValue:Array<Vec4>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecFloats4(d));
        }
        return tmp;
    }

    static public function matsFloats(dataValue:Array<Mat4>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(matFloats(d));
        }
        return tmp;
    }
}


class SamplerValue {
    public var position:Int;
    public var sampler:TextureSampler;
    public var location:Int;
    public var wrapMode:WrapMode;
    public var textureFilter:TextureFilter;
    public var mipFilter:MipFilter;

    public function new(position:Int, sampler:TextureSampler, location:Int) {
        this.position = position;
        this.location = location;
        this.sampler = sampler;
    }
    //TextureType* type;
}
//todo 这里要进行一下 data Void->T类型 到Array转换  //mat vec one

class AttributeValue {
    public var location:Int;
    public var resourceId:Int;
    public var size:Int;
    public var stride:Int;
    public var offset:Int;

    public function new(location, resourceId, size, vertexSize, offset) {
        this.location = location;
        this.resourceId = resourceId;
        this.size = size;
        this.stride = vertexSize;
        this.offset = offset;
    }
}
class DrawCall extends Enable_uuid {
    public static inline var MAX_NUM_TEXTURES = 8;
    public static inline var MAX_NUM_VERTEXBUFFERS = 8;

    private var _enabled:Bool;

    private var _batchIDs:Array<Int>;
    private var _pass:Pass;
    private var _rootData:Store;
    private var _rendererData:Store;
    private var _targetData:Store;
    private var _variables:EffectVariables;

    private var _program:Program;
    private var _indexBuffer:Int;
    private var _firstIndex:Int;
    private var _numIndices:Int;
    private var _uniformInt:Array<UniformValue<Int>> ;
    private var _uniformFloat:Array<UniformValue<Float>> ;
    private var _uniformBool:Array<UniformValue<Int>>;
    private var _samplers:Array<SamplerValue>;
    private var _attributes:Array<AttributeValue>;

    private var _priority:Float;
    private var _zSorted:Bool;
    private var _blendingSourceFactor:Source;
    private var _blendingDestinationFactor:Destination;
    private var _colorMask:Bool;
    private var _depthMask:Bool;
    private var _depthFunc:CompareMode;
    private var _triangleCulling:TriangleCulling;
    private var _stencilFunction:CompareMode;
    private var _stencilReference:Int;
    private var _stencilMask:Int;
    private var _stencilFailOp:StencilOperation;
    private var _stencilZFailOp:StencilOperation;
    private var _stencilZPassOp:StencilOperation;
    private var _scissorTest:Bool;
    private var _scissorBox:Vec4;
    private var _target:Texture ;

    // Positional members
    private var _centerPosition:Vec3;
    private var _modelToWorldMatrix:Mat4;
    private var _worldToScreenMatrix:Mat4;

    private var _modelToWorldMatrixPropertyAddedSlot:SignalSlot3<Store, Provider, String>;
    private var _worldToScreenMatrixPropertyAddedSlot:SignalSlot3<Store, Provider, String>;
    private var _modelToWorldMatrixPropertyRemovedSlot:SignalSlot3<Store, Provider, String>;
    private var _worldToScreenMatrixPropertyRemovedSlot:SignalSlot3<Store, Provider, String>;

    private var _vertexAttribArray:Int;


    public function new(batchId:Int, pass:Pass, variables:EffectVariables, rootData:Store, rendererData:Store, targetData:Store) {
        this._enabled = true;
        this._pass = pass;
        this._rootData = (rootData);
        this._rendererData = (rendererData);
        this._targetData = (targetData);
        this._variables = variables;
        this._indexBuffer = null;
        this._firstIndex = null;
        this._numIndices = null;
        this._priority = States.DEFAULT_PRIORITY;
        this._zSorted = States.DEFAULT_ZSORTED;
        this._blendingSourceFactor = States.DEFAULT_BLENDING_SOURCE;
        this._blendingDestinationFactor = States.DEFAULT_BLENDING_DESTINATION;
        this._colorMask = States.DEFAULT_COLOR_MASK;
        this._depthMask = States.DEFAULT_DEPTH_MASK;
        this._depthFunc = States.DEFAULT_DEPTH_FUNCTION;
        this._triangleCulling = States.DEFAULT_TRIANGLE_CULLING;
        this._stencilFunction = States.DEFAULT_STENCIL_FUNCTION;
        this._stencilReference = States.DEFAULT_STENCIL_REFERENCE;
        this._stencilMask = States.DEFAULT_STENCIL_MASK;
        this._stencilFailOp = States.DEFAULT_STENCIL_FAIL_OPERATION;
        this._stencilZFailOp = States.DEFAULT_STENCIL_ZFAIL_OPERATION;
        this._stencilZPassOp = States.DEFAULT_STENCIL_ZPASS_OPERATION;
        this._scissorTest = States.DEFAULT_SCISSOR_TEST;
        this._scissorBox = States.DEFAULT_SCISSOR_BOX;
        this._target = States.DEFAULT_TARGET;
        this._centerPosition = new Vec3();
        this._modelToWorldMatrix = null;
        this._worldToScreenMatrix = null;
        this._modelToWorldMatrixPropertyRemovedSlot = null;
        this._worldToScreenMatrixPropertyRemovedSlot = null;
        this._vertexAttribArray = 0;
        this._batchIDs = [batchId];
        this._uniformFloat = [];
        this._uniformInt = [];
        this._uniformBool = [];
        this._samplers = [];
        this._attributes = [];
        // For Z-sorting
        bindPositionalMembers();
        super();
        enable_uuid();
    }

    public function dispose() {
        this._pass = null;
        this._rootData = null;
        this._rendererData = null;
        this._targetData = null;
        this._variables = null;
        if (_modelToWorldMatrixPropertyAddedSlot != null) _modelToWorldMatrixPropertyAddedSlot.dispose();
        if (_worldToScreenMatrixPropertyAddedSlot != null) _worldToScreenMatrixPropertyAddedSlot.dispose();
        if (_modelToWorldMatrixPropertyRemovedSlot != null) _modelToWorldMatrixPropertyRemovedSlot.dispose();
        if (_worldToScreenMatrixPropertyRemovedSlot != null) _worldToScreenMatrixPropertyRemovedSlot.dispose();
        _modelToWorldMatrixPropertyAddedSlot=null;
        _worldToScreenMatrixPropertyAddedSlot=null;
        _modelToWorldMatrixPropertyRemovedSlot=null;
        _worldToScreenMatrixPropertyRemovedSlot=null;
    }
    public var enabled(get, set):Bool;

    function get_enabled() {
        return _enabled;
    }

    function set_enabled(value) {
        _enabled = value;
        return value;
    }
    public var batchIDs(get, null):Array<Int>;

    function get_batchIDs() {
        return _batchIDs;
    }
    public var pass(get, null):Pass;

    function get_pass() {
        return _pass;
    }

    public var program(get, null):Program;

    function get_program() {
        return _program;
    }
    public var variables(get, set):EffectVariables;

    function set_variables(v) {
        _variables = v;
        return v;
    }

    function get_variables() {
        return _variables;
    }
    public var rootData(get, null):Store;

    function get_rootData() {
        return _rootData;
    }
    public var rendererData(get, null):Store;

    function get_rendererData() {
        return _rendererData;
    }
    public var targetData(get, null):Store;

    function get_targetData() {
        return _targetData;
    }

    public var boundBoolUniforms(get, null):Array<UniformValue<Int>>;

    function get_boundBoolUniforms() {
        return _uniformBool;
    }

    public var boundIntUniforms(get, null):Array<UniformValue<Int>>;

    function get_boundIntUniforms() {
        return _uniformInt;
    }
    public var boundFloatUniforms(get, null):Array<UniformValue<Float>>;

    function get_boundFloatUniforms() {
        return _uniformFloat;
    }
    public var samplers(get, null):Array<SamplerValue>;

    function get_samplers() {
        return _samplers;
    }

    public var priority(get, null):Float;

    function get_priority() {
        return _priority;
    }

    public var zSorted(get, null):Bool;

    function get_zSorted() {
        if (_zSorted) {
            return _zSorted;
        }
        else {
            return false;
        }
    }
    public var blendingSource(get, null):Source;

    function get_blendingSource() {
        return _blendingSourceFactor;
    }

    public var blendingDestination(get, null):Destination;

    function get_blendingDestination() {
        return _blendingDestinationFactor;
    }

    public var colorMask(get, null):Bool;

    function get_colorMask() {
        return _colorMask;
    }

    public var depthMask(get, null):Bool;

    function get_depthMask() {
        return _depthMask;
    }

    public var depthFunction(get, null):CompareMode;

    function get_depthFunction() {
        return _depthFunc;
    }

    public var triangleCulling(get, null):TriangleCulling;

    function get_triangleCulling() {
        return _triangleCulling;
    }

    public var stencilFunction(get, null):CompareMode;

    function get_stencilFunction() {
        return _stencilFunction;
    }

    public var stencilReference(get, null):Int;

    function get_stencilReference() {
        return _stencilReference;
    }

    public var stencilMask(get, null):Int;

    function get_stencilMask() {
        return _stencilMask;
    }
    public var stencilFailOperation(get, null):StencilOperation;

    function get_stencilFailOperation() {
        return _stencilFailOp;
    }

    public var stencilZFailOperation(get, null):StencilOperation;

    function get_stencilZFailOperation() {
        return _stencilZFailOp;
    }

    public var stencilZPassOperation(get, null):StencilOperation;

    function get_stencilZPassOperation() {
        return _stencilZPassOp;
    }

    public var scissorTest(get, null):Bool;

    function get_scissorTest() {
        return _scissorTest;
    }

    public var scissorBox(get, null):Vec4;

    function get_scissorBox() {
        return _scissorBox;
    }
    public var target(get, null):Texture ;

    function get_target() {
        return _target;
    }
    public var numTriangles(get, null):Int;

    function get_numTriangles() {
        return _numIndices != null ? Math.floor(_numIndices / 3) : 0;
    }

    public function bind(program:Program) {
        reset();
        _program = program;

        // bindIndexBuffer();
        // bindStates();
        //bindUniforms();
        // bindAttributes();
    }

    public function render(context:AbstractContext, renderTarget:AbstractTexture, viewport:Vec4, clearColor:Int) {
        if (!this.enabled) {
            return;
        }

        context.setProgram(_program.id);

        var hasOwnTarget = _target != null && _target.id != 0;
        var renderTargetId = hasOwnTarget ? _target.id : (renderTarget != null ? renderTarget.id : 0);
        var targetChanged = false;

        if (renderTargetId != 0) {
            if (renderTargetId != context.renderTarget) {
                context.setRenderToTexture(renderTargetId, true);

                if (hasOwnTarget) {
                    context.clear(((clearColor >> 24) & 0xff) / 255.0, ((clearColor >> 16) & 0xff) / 255.0, ((clearColor >> 8) & 0xff) / 255.0, (clearColor & 0xff) / 255.0);
                }

                targetChanged = true;
            }
        }
        else {
            context.setRenderToBackBuffer();
        }

        if (targetChanged && !hasOwnTarget && viewport.z >= 0 && viewport.w >= 0) {
            context.configureViewport(Math.floor(viewport.x), Math.floor(viewport.y), Math.floor(viewport.z), Math.floor(viewport.w));
        }


        for (u in _uniformBool) {
            if (u.size == 1) {
                context.setUniformInt(u.location, u.count, u.dataArray);
            }
            else if (u.size == 2) {
                context.setUniformInt2(u.location, u.count, u.dataArray);
            }
            else if (u.size == 3) {
                context.setUniformInt3(u.location, u.count, u.dataArray);
            }
            else if (u.size == 4) {
                context.setUniformInt4(u.location, u.count, u.dataArray);
            }
        }

        for (u in _uniformInt) {
            if (u.size == 1) {
                context.setUniformInt(u.location, u.count, u.dataArray);
            }
            else if (u.size == 2) {
                context.setUniformInt2(u.location, u.count, u.dataArray);
            }
            else if (u.size == 3) {
                context.setUniformInt3(u.location, u.count, u.dataArray);
            }
            else if (u.size == 4) {
                context.setUniformInt4(u.location, u.count, u.dataArray);
            }
        }
        var mvMatrix = new Mat4() ;
        var pMatrix = new Mat4();

        for (u in _uniformFloat) {
            if (u.size == 1) {
                context.setUniformFloat(u.location, u.count, u.dataArray);
            }
            else if (u.size == 2) {
                context.setUniformFloat2(u.location, u.count, u.dataArray);
            }
            else if (u.size == 3) {
                context.setUniformFloat3(u.location, u.count, u.dataArray);
            }
            else if (u.size == 4) {
                context.setUniformFloat4(u.location, u.count, u.dataArray);
            }
            else if (u.size == 16) {
                context.setUniformMatrix4x4(u.location, u.count, u.dataArray);
            }
        }

        for (s in _samplers) {
            var ss = s.sampler;
            var sid = ss.id;
            context.setTextureAt(s.position, s.sampler.id, s.location);
            context.setSamplerStateAt(s.position, s.wrapMode, s.textureFilter, s.mipFilter);
        }
/*
        if (_vertexAttribArray == 0) {
            _vertexAttribArray = context.createVertexAttributeArray();

            if (_vertexAttribArray != -1) {
                context.setVertexAttributeArray(_vertexAttribArray);
                for (a in _attributes) {
                    context.setVertexBufferAt(a.location, a.resourceId, a.size, a.stride, a.offset);
                }
            }
        }
        if (_vertexAttribArray != -1) {
            context.setVertexAttributeArray(_vertexAttribArray);
        }
        else {
        */
        for (a in _attributes) {
            context.setVertexBufferAt(a.location, a.resourceId, a.size, a.stride, a.offset);
        }
        //    }

        context.setColorMask(_colorMask);
        context.setBlendingModeSD(_blendingSourceFactor, _blendingDestinationFactor);
        context.setDepthTest(_depthMask, _depthFunc);
        context.setStencilTest(_stencilFunction, _stencilReference, _stencilMask, _stencilFailOp, _stencilZFailOp, _stencilZPassOp);
        context.setScissorTest(_scissorTest, _scissorBox);
        context.setTriangleCulling(_triangleCulling);

        if (!_pass.isForward) {
            context.drawTriangles(0, 2);
        }
        else {
            context.drawIndexBufferTriangles(_indexBuffer, _firstIndex, Math.floor(_numIndices / 3));
        }
    }

    public function bindAttribute(input:ConstAttrInputRef, attributeBindings:StringMap< Binding>, defaultValues:Store) {
        var binding:ResolvedBinding = resolveBinding(input.name, attributeBindings);

        if (binding == null) {
            if (!defaultValues.hasProperty(input.name)) {

                var it = Lambda.has(_program.setAttributeNames, input.name);

                if (it == false) {
                    trace("Program \"" + _program.name + "\": the attribute \"" + input.name + "\" is not bound, has not been set and no default value was provided.");

                    throw ("Program \"" + _program.name + "\": the attribute \"" + input.name + "\" is not bound, has not been set and no default value was provided.");
                }

                setAttributeValueFromStore(input, input.name, defaultValues);
            }
        }
        else {
            #if DEBUG
			auto setAttributes = _program.setAttributeNames();

			if (std::find(setAttributes.begin(), setAttributes.end(), input.name) != setAttributes.end())
			{
				LOG_WARNING("Program \"" + _program.name() + "\", vertex attribute \"" + input.name + "\" set manually but overriden by a binding to the \"" + binding.propertyName + "\" property.");
			}
	#end

            if (!binding.store.hasProperty(binding.propertyName)) {
                if (!defaultValues.hasProperty(input.name)) {

                    trace("Program \"" + _program.name + "\": the attribute \"" + input.name + "\" is bound to the \"" + binding.propertyName + "\" property but it's not defined and no default value was provided.");

                    throw ("Program \"" + _program.name + "\": the attribute \"" + input.name + "\" is bound to the \"" + binding.propertyName + "\" property but it's not defined and no default value was provided.");
                }

                setAttributeValueFromStore(input, input.name, defaultValues);
            }
            else {
                setAttributeValueFromStore(input, binding.propertyName, binding.store);
            }

            binding = null;
        }
    }

    public function bindUniform(input:ConstUniformInputRef, uniformBindings:StringMap< Binding>, defaultValues:Store):ResolvedBinding {
        var binding:ResolvedBinding = resolveBinding(input.name, uniformBindings);

        if (binding == null) {
            if (!defaultValues.hasProperty(input.name)) {
                var it = Lambda.has(_program.setUniformNames, input.name);

                if (it == false) {
                    trace("Program \"" + _program.name + "\": the uniform \"" + input.name + "\" is not bound, has not been set and no default value was provided.");

                    throw ("Program \"" + _program.name + "\": the uniform \"" + input.name + "\" is not bound, has not been set and no default value was provided.");
                }
            }

            setUniformValueFromStore(input, input.name, defaultValues);
        }
        else {
            if (!binding.store.hasProperty(binding.propertyName)) {
                if (!defaultValues.hasProperty(input.name)) {

                    trace("Program \"" + _program.name + "\": the uniform \"" + input.name + "\" is bound to the \"" + binding.propertyName + "\" property but it's not defined and no default value was provided.");

                    throw ("Program \"" + _program.name + "\": the uniform \"" + input.name + "\" is bound to the \"" + binding.propertyName + "\" property but it's not defined and no default value was provided.");
                }
                else {
                    setUniformValueFromStore(input, input.name, defaultValues);
                }
            }
            else {
                setUniformValueFromStore(input, binding.propertyName, binding.store);
            }
        }

        return binding;
    }

    public function bindSamplerStates(input:ConstUniformInputRef, uniformBindings:StringMap< Binding>, defaultValues:Store):Array<ResolvedBinding> {
        var wrapModeBinding = bindSamplerState(input, uniformBindings, defaultValues, SamplerStates.PROPERTY_WRAP_MODE);
        var textureFilterBinding = bindSamplerState(input, uniformBindings, defaultValues, SamplerStates.PROPERTY_TEXTURE_FILTER);
        var mipFilterBinding = bindSamplerState(input, uniformBindings, defaultValues, SamplerStates.PROPERTY_MIP_FILTER);

        var samplerStatesResolveBindings:Array<ResolvedBinding> = [wrapModeBinding, textureFilterBinding, mipFilterBinding];

        return samplerStatesResolveBindings;
    }

    public function bindSamplerState(input:ConstUniformInputRef, uniformBindings:StringMap< Binding>, defaultValues:Store, samplerStateProperty:String) {
        if (samplerStateProperty == SamplerStates.PROPERTY_WRAP_MODE || samplerStateProperty == SamplerStates.PROPERTY_TEXTURE_FILTER || samplerStateProperty == SamplerStates.PROPERTY_MIP_FILTER) {
            var samplerStateUniformName = SamplerStates.uniformNameToSamplerStateName(input.name, samplerStateProperty);

            var binding:ResolvedBinding = resolveBinding(samplerStateUniformName, uniformBindings);

            if (binding == null) {
                setSamplerStateValueFromStore(input, samplerStateUniformName, defaultValues, samplerStateProperty);
            }
            else {
                if (!binding.store.hasProperty(binding.propertyName)) {
                    setSamplerStateValueFromStore(input, samplerStateUniformName, defaultValues, samplerStateProperty);
                }
                else {
                    setSamplerStateValueFromStore(input, binding.propertyName, binding.store, samplerStateProperty);
                }
            }

            return binding;
        }

        return null;
    }

    public function bindStates(stateBindings:StringMap<Binding>, defaultValues:Store) {
        var statesResolveBindings:Array<ResolvedBinding> =
        [bindState(States.PROPERTY_PRIORITY, stateBindings, defaultValues),
        bindState(States.PROPERTY_ZSORTED, stateBindings, defaultValues),
        bindState(States.PROPERTY_BLENDING_SOURCE, stateBindings, defaultValues),
        bindState(States.PROPERTY_BLENDING_DESTINATION, stateBindings, defaultValues),
        bindState(States.PROPERTY_COLOR_MASK, stateBindings, defaultValues),
        bindState(States.PROPERTY_DEPTH_MASK, stateBindings, defaultValues),
        bindState(States.PROPERTY_DEPTH_FUNCTION, stateBindings, defaultValues),
        bindState(States.PROPERTY_TRIANGLE_CULLING, stateBindings, defaultValues),
        bindState(States.PROPERTY_STENCIL_FUNCTION, stateBindings, defaultValues),
        bindState(States.PROPERTY_STENCIL_REFERENCE, stateBindings, defaultValues),
        bindState(States.PROPERTY_STENCIL_MASK, stateBindings, defaultValues),
        bindState(States.PROPERTY_STENCIL_FAIL_OPERATION, stateBindings, defaultValues),
        bindState(States.PROPERTY_STENCIL_ZFAIL_OPERATION, stateBindings, defaultValues),
        bindState(States.PROPERTY_STENCIL_ZPASS_OPERATION, stateBindings, defaultValues),
        bindState(States.PROPERTY_SCISSOR_TEST, stateBindings, defaultValues),
        bindState(States.PROPERTY_SCISSOR_BOX, stateBindings, defaultValues),
        bindState(States.PROPERTY_TARGET, stateBindings, defaultValues)];

        return statesResolveBindings;
    }

    public function bindState(stateName:String, bindings:StringMap<Binding>, defaultValues:Store) {
        var binding:ResolvedBinding = resolveBinding(stateName, bindings);

        if (binding == null) {
            setStateValueFromStore(stateName, defaultValues);
        }
        else {
            if (!binding.store.hasProperty(binding.propertyName)) {
                setStateValueFromStore(stateName, defaultValues);
            }
            else {
                setStateValueFromStore(stateName, binding.store);
            }
        }

        return binding;
    }

    public function bindPositionalMembers() {
        if (_targetData.hasProperty("centerPosition")) {
            _centerPosition = _targetData.get("centerPosition");
        }

        if (_targetData.hasProperty("modelToWorldMatrix")) {
            _modelToWorldMatrix = _targetData.get("modelToWorldMatrix");
        }
        else {
            _modelToWorldMatrixPropertyAddedSlot = _targetData.getPropertyAdded("modelToWorldMatrix").connect(
                function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                    _modelToWorldMatrix = _targetData.get("modelToWorldMatrix");
                });
        }

        if (_rendererData.hasProperty("worldToScreenMatrix")) {
            _worldToScreenMatrix = _rendererData.get("worldToScreenMatrix");
        }
        else {
            _worldToScreenMatrixPropertyAddedSlot = _rendererData.getPropertyAdded("worldToScreenMatrix").connect(
                function(store, data, UnnamedParameter1) {
                    _worldToScreenMatrix = _rendererData.get("worldToScreenMatrix");
                });
        }

        // Removed slot
        _modelToWorldMatrixPropertyRemovedSlot = _targetData.getPropertyRemoved("modelToWorldMatrix").connect(
            function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                _modelToWorldMatrix = null;
            });

        _worldToScreenMatrixPropertyRemovedSlot = _rendererData.getPropertyRemoved("worldToScreenMatrix").connect(
            function(store, data, UnnamedParameter1) {
                _worldToScreenMatrix = null;
            });
    }

    public function bindIndexBuffer() {
        var indexBufferProperty = Store.getActualPropertyName(_variables, "geometry[@{geometryUuid}].indices");

        if (_targetData.hasProperty(indexBufferProperty)) {
            _indexBuffer = _targetData.get(indexBufferProperty);
        }

        var surfaceFirstIndexProperty = Store.getActualPropertyName(_variables, "surface[@{surfaceUuid}].firstIndex");

        if (!_targetData.hasProperty(surfaceFirstIndexProperty)) {
            var geometryFirstIndexProperty = Store.getActualPropertyName(_variables, "geometry[@{geometryUuid}].firstIndex");

            if (_targetData.hasProperty(geometryFirstIndexProperty)) {
                _firstIndex = _targetData.get(geometryFirstIndexProperty);
            }
        }
        else {
            _firstIndex = _targetData.get(surfaceFirstIndexProperty);
        }

        var surfaceNumIndicesProperty = Store.getActualPropertyName(_variables, "surface[@{surfaceUuid}].numIndices");

        if (!_targetData.hasProperty(surfaceNumIndicesProperty)) {
            var geometryNumIndicesProperty = Store.getActualPropertyName(_variables, "geometry[@{geometryUuid}].numIndices");

            if (_targetData.hasProperty(geometryNumIndicesProperty)) {
                _numIndices = _targetData.get(geometryNumIndicesProperty);
            }
        }
        else {
            _numIndices = _targetData.get(surfaceNumIndicesProperty);
        }
    }

    public function getEyeSpacePosition() {
        var modelView:Mat4 = new Mat4();

        if (_modelToWorldMatrix != null) {
            modelView = _modelToWorldMatrix;
        }
        //math
        if (_worldToScreenMatrix != null) {
            modelView = _worldToScreenMatrix * (modelView) ;
        }

        var tmp:Vec4 = modelView * (new Vec4(_centerPosition.x, _centerPosition.y, _centerPosition.z, 1));
        return MathUtil.vec4_vec3(tmp);
    }

    public function initializeOnContext(context:AbstractContext) {

    }

    private function reset() {
        _program = null;
        _indexBuffer = null;
        _firstIndex = null;
        _numIndices = null;
        _uniformFloat = [];
        _uniformInt = [];
        _uniformBool = [];
        _samplers = [];
        _attributes = [];
        _vertexAttribArray = 0;
    }

    private function getStore(source:minko.data.Binding.Source) {
        switch (source)
        {
            case minko.data.Binding.Source.ROOT:
                return _rootData;
            case minko.data.Binding.Source.RENDERER:
                return _rendererData;
            case minko.data.Binding.Source.TARGET:
                return _targetData;
        }

        throw "";
    }

    private function resolveBinding(inputName:String, bindings:StringMap< Binding>):ResolvedBinding {
        var isCollection = false;
        var bindingName = inputName;
        var isArray = inputName.charAt(inputName.length - 1) == ']';
        var pos = bindingName.indexOf('[');

        if (!isArray && pos != -1) {
            bindingName = bindingName.substr(0, pos);
            isCollection = true;
        }

        var binding:Binding = null;
        var bindingPropertyName:String = "";

        // Some OpenGL drivers will provide uniform array names without the "[0]" suffix. In order to properly match uniform array
        // bindings, we will check for bindings with 1) the original name first but also 2) the named with the "[0]" suffix appened.
        if (bindings.exists(bindingName) || (!isArray && bindings.exists(bindingName + "[0]") )) {
            binding = bindings.get(bindingName);
            bindingPropertyName = binding.propertyName;
            // isCollection = isCollection && bindingPropertyName.find_first_of('[') == std::string::npos;
        }
        // else
        // {
        //     for (const auto& inputNameAndBinding : bindings)
        //     {
        //         std::regex r(inputNameAndBinding.first);
        //
        //         if (std::regex_match(inputName, r))
        //         {
        //             bindingPropertyName = std::regex_replace(inputName, r, inputNameAndBinding.second.propertyName);
        //             binding = &inputNameAndBinding.second;
        //             isCollection = false;
        //             break;
        //         }
        //     }

        if (binding == null) {
            return null;
        }
        // }

        var store:Store = getStore(binding.source);
        var propertyName = Store.getActualPropertyName(_variables, bindingPropertyName);

        // FIXME: handle uniforms with struct types

        // FIXME: we assume the uniform is an array of struct or the code to be irrelevantly slow here
        // uniform arrays of non-struct types should be detected and handled as such using a single call
        // to the context providing the direct pointer to the contiguous stored data

        // FIXME: handle per-fields bindings instead of using the raw uniform suffix
        if (isCollection && !isArray) {
            propertyName += inputName.substr(pos);
        }

        return new ResolvedBinding(binding, propertyName, store);
    }


    private function setUniformValueFromStore(input:UniformInput, propertyName:String, store:Store) {
        var isArray:Bool = input.name.charAt(input.name.length - 1) == ']';
        var data = store.get(propertyName) ;
        if (isArray == false) {
            switch (input.type)
            {
                case ProgramInputs.InputType.bool1:
                    setUniformValue(_uniformBool, input.location, 1, input.size, UniformValue.vecInts1(data), data);

                case ProgramInputs.InputType.bool2:
                    setUniformValue(_uniformBool, input.location, 2, input.size, UniformValue.vecInts2(data), data);

                case ProgramInputs.InputType.bool3:
                    setUniformValue(_uniformBool, input.location, 3, input.size, UniformValue.vecInts3(data), data);

                case ProgramInputs.InputType.bool4:
                    setUniformValue(_uniformBool, input.location, 4, input.size, UniformValue.vecInts4(data), data);

                case ProgramInputs.InputType.int1:
                    setUniformValue(_uniformInt, input.location, 1, input.size, UniformValue.vecInts1(data), data);

                case ProgramInputs.InputType.int2:
                    setUniformValue(_uniformInt, input.location, 2, input.size, UniformValue.vecInts2(data), data);

                case ProgramInputs.InputType.int3:
                    setUniformValue(_uniformInt, input.location, 3, input.size, UniformValue.vecInts3(data), data);

                case ProgramInputs.InputType.int4:
                    setUniformValue(_uniformInt, input.location, 4, input.size, UniformValue.vecInts4(data), data);

                case ProgramInputs.InputType.float1:
                    setUniformValue(_uniformFloat, input.location, 1, input.size, UniformValue.vecFloats1(data), data);

                case ProgramInputs.InputType.float2:
                    setUniformValue(_uniformFloat, input.location, 2, input.size, UniformValue.vecFloats2(data), data);

                case ProgramInputs.InputType.float3:
                    setUniformValue(_uniformFloat, input.location, 3, input.size, UniformValue.vecFloats3(data), data);

                case ProgramInputs.InputType.float4:
                    setUniformValue(_uniformFloat, input.location, 4, input.size, UniformValue.vecFloats4(data), data);

                case ProgramInputs.InputType.float16:
                    setUniformValue(_uniformFloat, input.location, 16, input.size, UniformValue.matFloats(data), data);

                case ProgramInputs.InputType.sampler2d | ProgramInputs.InputType.samplerCube:
                    var samplerIt:SamplerValue = Lambda.find(_samplers, function(samplerValue:SamplerValue) {
                        return samplerValue.location == input.location;
                    });
                    var texture:AbstractTexture = cast store.get(propertyName) ;
                    if (samplerIt == null) {
                        _samplers.push(
                            new SamplerValue((_program.setTextureNames.length + _samplers.length), texture.sampler, input.location)
                        );
                    }
                    else {
                        samplerIt.sampler = texture.sampler;
                    }


                case ProgramInputs.InputType.float9 | ProgramInputs.InputType.unknown:
                    trace("unsupported program input type: " + ProgramInputs.typeToString(input.type));
                    throw ("unsupported program input type: " + ProgramInputs.typeToString(input.type));

            }
        } else {
            switch (input.type)
            {
                case ProgramInputs.InputType.bool1:
                    setUniformValue(_uniformBool, input.location, 1, input.size, UniformValue.vecsInts1(data), data);

                case ProgramInputs.InputType.bool2:
                    setUniformValue(_uniformBool, input.location, 2, input.size, UniformValue.vecsInts2(data), data);

                case ProgramInputs.InputType.bool3:
                    setUniformValue(_uniformBool, input.location, 3, input.size, UniformValue.vecsInts3(data), data);

                case ProgramInputs.InputType.bool4:
                    setUniformValue(_uniformBool, input.location, 4, input.size, UniformValue.vecsInts4(data), data);

                case ProgramInputs.InputType.int1:
                    setUniformValue(_uniformInt, input.location, 1, input.size, UniformValue.vecsInts1(data), data);

                case ProgramInputs.InputType.int2:
                    setUniformValue(_uniformInt, input.location, 2, input.size, UniformValue.vecsInts2(data), data);

                case ProgramInputs.InputType.int3:
                    setUniformValue(_uniformInt, input.location, 3, input.size, UniformValue.vecsInts3(data), data);

                case ProgramInputs.InputType.int4:
                    setUniformValue(_uniformInt, input.location, 4, input.size, UniformValue.vecsInts4(data), data);

                case ProgramInputs.InputType.float1:
                    setUniformValue(_uniformFloat, input.location, 1, input.size, UniformValue.vecsFloats1(data), data);

                case ProgramInputs.InputType.float2:
                    setUniformValue(_uniformFloat, input.location, 2, input.size, UniformValue.vecsFloats2(data), data);

                case ProgramInputs.InputType.float3:
                    setUniformValue(_uniformFloat, input.location, 3, input.size, UniformValue.vecsFloats3(data), data);

                case ProgramInputs.InputType.float4:
                    setUniformValue(_uniformFloat, input.location, 4, input.size, UniformValue.vecsFloats4(data), data);

                case ProgramInputs.InputType.float16:
                    setUniformValue(_uniformFloat, input.location, 16, input.size, UniformValue.matsFloats(data), data);

                case ProgramInputs.InputType.sampler2d | ProgramInputs.InputType.samplerCube:

                    trace("unsupported program input type: " + ProgramInputs.typeToString(input.type));
                    throw ("unsupported program input type: " + ProgramInputs.typeToString(input.type));

                case ProgramInputs.InputType.float9 | ProgramInputs.InputType.unknown:
                    trace("unsupported program input type: " + ProgramInputs.typeToString(input.type));
                    throw ("unsupported program input type: " + ProgramInputs.typeToString(input.type));

            }
        }

    }

    private function setSamplerStateValueFromStore(input:UniformInput, propertyName:String, store:Store, samplerStateProperty:String) {

        var it:SamplerValue = Lambda.find(_samplers, function(sampler:SamplerValue) {
            return sampler.location == input.location;
        });

        if (it != null) {
            var sampler = it;

            if (samplerStateProperty == SamplerStates.PROPERTY_WRAP_MODE) {
                if (store.hasProperty(propertyName)) {
                    sampler.wrapMode = store.get(propertyName);
                }
                else {
                    sampler.wrapMode = SamplerStates.DEFAULT_WRAP_MODE;
                }
            }
            else if (samplerStateProperty == SamplerStates.PROPERTY_TEXTURE_FILTER) {
                if (store.hasProperty(propertyName)) {
                    sampler.textureFilter = store.get(propertyName);
                }
                else {
                    sampler.textureFilter = SamplerStates.DEFAULT_TEXTURE_FILTER;
                }
            }
            else if (samplerStateProperty == SamplerStates.PROPERTY_MIP_FILTER) {
                if (store.hasProperty(propertyName)) {
                    sampler.mipFilter = store.get(propertyName);
                }
                else {
                    sampler.mipFilter = SamplerStates.DEFAULT_MIP_FILTER;
                }
            }
        }
    }

    private function setStateValueFromStore(stateName:String, store:Store) {
        if (stateName == States.PROPERTY_PRIORITY) {
            if (store.hasProperty(stateName)) {
                _priority = store.get(stateName);
            }
            else {
                _priority = States.DEFAULT_PRIORITY;
            }
        }
        else if (stateName == States.PROPERTY_ZSORTED) {
            if (store.hasProperty(stateName)) {
                _zSorted = store.get(stateName);
            }
            else {
                _zSorted = States.DEFAULT_ZSORTED;
            }
        }
        else if (stateName == States.PROPERTY_BLENDING_SOURCE) {
            if (store.hasProperty(stateName)) {
                _blendingSourceFactor = store.get(stateName);
            }
            else {
                _blendingSourceFactor = States.DEFAULT_BLENDING_SOURCE;
            }
        }
        else if (stateName == States.PROPERTY_BLENDING_DESTINATION) {
            if (store.hasProperty(stateName)) {
                _blendingDestinationFactor = store.get(stateName);
            }
            else {
                _blendingDestinationFactor = States.DEFAULT_BLENDING_DESTINATION;
            }
        }
        else if (stateName == States.PROPERTY_COLOR_MASK) {
            if (store.hasProperty(stateName)) {
                _colorMask = store.get(stateName);
            }
            else {
                _colorMask = States.DEFAULT_COLOR_MASK;
            }
        }
        else if (stateName == States.PROPERTY_DEPTH_MASK) {
            if (store.hasProperty(stateName)) {
                _depthMask = store.get(stateName);
            }
            else {
                _depthMask = States.DEFAULT_DEPTH_MASK;
            }
        }
        else if (stateName == States.PROPERTY_DEPTH_FUNCTION) {
            if (store.hasProperty(stateName)) {
                _depthFunc = store.get(stateName);
            }
            else {
                _depthFunc = States.DEFAULT_DEPTH_FUNCTION;
            }
        }
        else if (stateName == States.PROPERTY_TRIANGLE_CULLING) {
            if (store.hasProperty(stateName)) {
                _triangleCulling = store.get(stateName);
            }
            else {
                _triangleCulling = States.DEFAULT_TRIANGLE_CULLING;
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_FUNCTION) {
            if (store.hasProperty(stateName)) {
                _stencilFunction = store.get(stateName);
            }
            else {
                _stencilFunction = States.DEFAULT_STENCIL_FUNCTION;
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_REFERENCE) {
            if (store.hasProperty(stateName)) {
                _stencilReference = store.get(stateName);
            }
            else {
                _stencilReference = States.DEFAULT_STENCIL_REFERENCE;
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_MASK) {
            if (store.hasProperty(stateName)) {
                _stencilMask = store.get(stateName);
            }
            else {
                _stencilMask = States.DEFAULT_STENCIL_MASK;
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_FAIL_OPERATION) {
            if (store.hasProperty(stateName)) {
                _stencilFailOp = store.get(stateName);
            }
            else {
                _stencilFailOp = States.DEFAULT_STENCIL_FAIL_OPERATION;
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_ZFAIL_OPERATION) {
            if (store.hasProperty(stateName)) {
                _stencilZFailOp = store.get(stateName);
            }
            else {
                _stencilZFailOp = States.DEFAULT_STENCIL_ZFAIL_OPERATION;
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_ZPASS_OPERATION) {
            if (store.hasProperty(stateName)) {
                _stencilZPassOp = store.get(stateName);
            }
            else {
                _stencilZPassOp = States.DEFAULT_STENCIL_ZPASS_OPERATION;
            }
        }
        else if (stateName == States.PROPERTY_SCISSOR_TEST) {
            if (store.hasProperty(stateName)) {
                _scissorTest = store.get(stateName);
            }
            else {
                _scissorTest = States.DEFAULT_SCISSOR_TEST;
            }
        }
        else if (stateName == States.PROPERTY_SCISSOR_BOX) {
            if (store.hasProperty(stateName)) {
                _scissorBox = store.get(stateName);
            }
            else {
                _scissorBox = States.DEFAULT_SCISSOR_BOX;
            }
        }
        else if (stateName == States.PROPERTY_TARGET) {
            if (store.hasProperty(stateName)) {

                _target = store.get(stateName) ;
            }
            else {
                _target = States.DEFAULT_TARGET;
            }
        }
    }

    private function setAttributeValueFromStore(input:AttributeInput, propertyName:String, store:Store) {
        var attr:VertexAttribute = store.get(propertyName);
        //need vertexSize bind
        _attributes.push(new AttributeValue(input.location, attr.resourceId, attr.size, attr.vertexSize, attr.offset));
    }


    static private function setUniformValue<T>(uniforms:Array<UniformValue<T>>, location, size, count, dataArray:Array<T>, data:Any) {

        var it:UniformValue<T> = Lambda.find(uniforms, function(u:UniformValue<T>) {
            return u.location == location;
        });


        if (it == null) {
            it = new UniformValue<T>(location, size, count, dataArray);
            uniforms.push(it);
        }
        else {
            it.dataArray = dataArray;
        }
        it.data = data;
    }
}
