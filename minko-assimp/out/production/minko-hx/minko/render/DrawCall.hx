package minko.render;
import minko.signal.Signal3;
import minko.data.UnsafePointer;
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
@:expose("minko.render.UniformValue")
class UniformValue<T> {
    public var location:Int;
    public var size:Int;
    public var count:Int;

    public var data:UnsafePointer<Dynamic>;//记录原值
    function get_dataArray(){
        return data.arrayBuffer();
    }
    public function new(location:Int, size:Int, count:Int ) {
        this.location = location;
        this.size = size;
        this.count = count;
    }

}

@:expose("minko.render.SamplerValue")
class SamplerValue {
    public var position:Int;
    public var sampler(get,null):TextureSampler;
    public var location:Int;
    public var texture:UnsafePointer<Texture>;
    public var wrapMode:UnsafePointer<WrapMode>;
    public var textureFilter:UnsafePointer<TextureFilter>;
    public var mipFilter:UnsafePointer<MipFilter>;
    function get_sampler(){
        return texture.value.sampler;
    }
    public function new(position:Int, texture:UnsafePointer<Texture>, location:Int) {
        this.position = position;
        this.location = location;
        this.texture = texture;
    }
    //TextureType* type;
}
//todo 这里要进行一下 data Void->T类型 到Array转换  //mat vec one
@:expose("minko.render.AttributeValue")
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
@:expose("minko.render.DrawCall")
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
    //geo indexBuffer
    private var _indexBuffer:UnsafePointer<Int>;
    private var _firstIndex:UnsafePointer<Int>;
    private var _numIndices:UnsafePointer<Int>;

    //uniform
    private var _uniformInt:Array<UniformValue<Int>>;
    private var _uniformFloat:Array<UniformValue<Float>> ;
    private var _uniformBool:Array<UniformValue<Int>>;
    //samplers
    private var _samplers:Array<SamplerValue>;
    //attributes geo vert Buffer
    private var _attributes:Array<AttributeValue>;

    //context state
    private var _priority:UnsafePointer<Float>;
    private var _zSorted:UnsafePointer<Bool>;
    private var _blendingSourceFactor:UnsafePointer<Source>;
    private var _blendingDestinationFactor:UnsafePointer<Destination>;
    private var _colorMask:UnsafePointer<Bool>;
    private var _depthMask:UnsafePointer<Bool>;
    private var _depthFunc:UnsafePointer<CompareMode>;
    private var _triangleCulling:UnsafePointer<TriangleCulling>;
    private var _stencilFunction:UnsafePointer<CompareMode>;
    private var _stencilReference:UnsafePointer<Int>;
    private var _stencilMask:UnsafePointer<Int>;
    private var _stencilFailOp:UnsafePointer<StencilOperation>;
    private var _stencilZFailOp:UnsafePointer<StencilOperation>;
    private var _stencilZPassOp:UnsafePointer<StencilOperation>;
    private var _scissorTest:UnsafePointer<Bool>;
    private var _scissorBox:UnsafePointer<Vec4>;
    private var _target:UnsafePointer<Texture> ;

    // Positional members
    private var _centerPosition:UnsafePointer<Vec3>;
    private var _modelToWorldMatrix:UnsafePointer<Mat4>;
    private var _worldToScreenMatrix:UnsafePointer<Mat4>;

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
        this._priority = new UnsafePointer(States.DEFAULT_PRIORITY);
        this._zSorted = new UnsafePointer(States.DEFAULT_ZSORTED);
        this._blendingSourceFactor =  new UnsafePointer(States.DEFAULT_BLENDING_SOURCE);
        this._blendingDestinationFactor =  new UnsafePointer(States.DEFAULT_BLENDING_DESTINATION);
        this._colorMask =  new UnsafePointer(States.DEFAULT_COLOR_MASK);
        this._depthMask =  new UnsafePointer(States.DEFAULT_DEPTH_MASK);
        this._depthFunc =  new UnsafePointer(States.DEFAULT_DEPTH_FUNCTION);
        this._triangleCulling =  new UnsafePointer(States.DEFAULT_TRIANGLE_CULLING);
        this._stencilFunction =  new UnsafePointer(States.DEFAULT_STENCIL_FUNCTION);
        this._stencilReference =  new UnsafePointer(States.DEFAULT_STENCIL_REFERENCE);
        this._stencilMask =  new UnsafePointer(States.DEFAULT_STENCIL_MASK);
        this._stencilFailOp =  new UnsafePointer(States.DEFAULT_STENCIL_FAIL_OPERATION);
        this._stencilZFailOp =  new UnsafePointer(States.DEFAULT_STENCIL_ZFAIL_OPERATION);
        this._stencilZPassOp =  new UnsafePointer(States.DEFAULT_STENCIL_ZPASS_OPERATION);
        this._scissorTest =  new UnsafePointer(States.DEFAULT_SCISSOR_TEST);
        this._scissorBox =  new UnsafePointer(States.DEFAULT_SCISSOR_BOX);
        this._target =  new UnsafePointer(States.DEFAULT_TARGET);
        this._centerPosition =  new UnsafePointer(new Vec3());
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
        return _priority.value;
    }

    public var zSorted(get, null):Bool;

    function get_zSorted() {
        if (_zSorted.value) {
            return _zSorted.value;
        }
        else {
            return false;
        }
    }
    public var blendingSource(get, null):Source;

    function get_blendingSource() {
        return _blendingSourceFactor.value;
    }

    public var blendingDestination(get, null):Destination;

    function get_blendingDestination() {
        return _blendingDestinationFactor.value;
    }

    public var colorMask(get, null):Bool;

    function get_colorMask() {
        return _colorMask.value;
    }

    public var depthMask(get, null):Bool;

    function get_depthMask() {
        return _depthMask.value;
    }

    public var depthFunction(get, null):CompareMode;

    function get_depthFunction() {
        return _depthFunc.value;
    }

    public var triangleCulling(get, null):TriangleCulling;

    function get_triangleCulling() {
        return _triangleCulling.value;
    }

    public var stencilFunction(get, null):CompareMode;

    function get_stencilFunction() {
        return _stencilFunction.value;
    }

    public var stencilReference(get, null):Int;

    function get_stencilReference() {
        return _stencilReference.value;
    }

    public var stencilMask(get, null):Int;

    function get_stencilMask() {
        return _stencilMask.value;
    }
    public var stencilFailOperation(get, null):StencilOperation;

    function get_stencilFailOperation() {
        return _stencilFailOp.value;
    }

    public var stencilZFailOperation(get, null):StencilOperation;

    function get_stencilZFailOperation() {
        return _stencilZFailOp.value;
    }

    public var stencilZPassOperation(get, null):StencilOperation;

    function get_stencilZPassOperation() {
        return _stencilZPassOp.value;
    }

    public var scissorTest(get, null):Bool;

    function get_scissorTest() {
        return _scissorTest.value;
    }

    public var scissorBox(get, null):Vec4;

    function get_scissorBox() {
        return _scissorBox.value;
    }
    public var target(get, null):Texture ;

    function get_target() {
        return _target.value;
    }
    public var numTriangles(get, null):Int;

    function get_numTriangles() {
        return _numIndices != null ? Math.floor(_numIndices.value / 3) : 0;
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

        var hasOwnTarget = _target != null &&_target.value!=null&& _target.value.id != 0;
        var renderTargetId = hasOwnTarget ? _target.value.id : (renderTarget != null ? renderTarget.id : 0);
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
                context.setUniformInt(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 2) {
                context.setUniformInt2(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 3) {
                context.setUniformInt3(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 4) {
                context.setUniformInt4(u.location, u.count, u.data.arrayBuffer());
            }
        }

        for (u in _uniformInt) {
            if (u.size == 1) {
                context.setUniformInt(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 2) {
                context.setUniformInt2(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 3) {
                context.setUniformInt3(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 4) {
                context.setUniformInt4(u.location, u.count, u.data.arrayBuffer());
            }
        }


        for (u in _uniformFloat) {
            if (u.size == 1) {
                context.setUniformFloat(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 2) {
                context.setUniformFloat2(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 3) {
                context.setUniformFloat3(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 4) {
                context.setUniformFloat4(u.location, u.count, u.data.arrayBuffer());
            }
            else if (u.size == 16) {
                context.setUniformMatrix4x4(u.location, u.count, u.data.arrayBuffer());
            }
        }

        for (s in _samplers) {
            context.setTextureAt(s.position, s.sampler.id, s.location);
            context.setSamplerStateAt(s.position, s.wrapMode.value, s.textureFilter.value, s.mipFilter.value);
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

        context.setColorMask(_colorMask.value);
        context.setBlendingModeSD(_blendingSourceFactor.value, _blendingDestinationFactor.value);
        context.setDepthTest(_depthMask.value, _depthFunc.value);
        context.setStencilTest(_stencilFunction.value, _stencilReference.value, _stencilMask.value, _stencilFailOp.value, _stencilZFailOp.value, _stencilZPassOp.value);
        context.setScissorTest(_scissorTest.value, _scissorBox.value);
        context.setTriangleCulling(_triangleCulling.value);

        if (!_pass.isForward) {
            context.drawTriangles(0, 2);
        }
        else {
            context.drawIndexBufferTriangles(_indexBuffer.value, _firstIndex.value, Math.floor(_numIndices.value / 3));
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
    function bindSamplerState(input:ConstUniformInputRef, uniformBindings:StringMap< Binding>, defaultValues:Store, samplerStateProperty:String) {
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
            _centerPosition = _targetData.getUnsafePointer("centerPosition");
        }

        if (_targetData.hasProperty("modelToWorldMatrix")) {
            _modelToWorldMatrix = _targetData.getUnsafePointer("modelToWorldMatrix");
        }
        else {
//            _modelToWorldMatrixPropertyAddedSlot = _targetData.getPropertyAdded("modelToWorldMatrix").connect(
//                function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                    _modelToWorldMatrix = _targetData.getUnsafePointer("modelToWorldMatrix");
//                });
        }

        if (_rendererData.hasProperty("worldToScreenMatrix")) {
            _worldToScreenMatrix = _rendererData.getUnsafePointer("worldToScreenMatrix");
        }
        else {
//            _worldToScreenMatrixPropertyAddedSlot = _rendererData.getPropertyAdded("worldToScreenMatrix").connect(
//                function(store, data, UnnamedParameter1) {
//                    _worldToScreenMatrix = _rendererData.getUnsafePointer("worldToScreenMatrix");
//                });
        }

        // Removed slot
//        _modelToWorldMatrixPropertyRemovedSlot = _targetData.getPropertyRemoved("modelToWorldMatrix").connect(
//            function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                _modelToWorldMatrix = null;
//            });
//
//        _worldToScreenMatrixPropertyRemovedSlot = _rendererData.getPropertyRemoved("worldToScreenMatrix").connect(
//            function(store, data, UnnamedParameter1) {
//                _worldToScreenMatrix = null;
//            });
    }

    public function bindIndexBuffer() {
        var indexBufferProperty = Store.getActualPropertyName(_variables, "geometry[@{geometryUuid}].indices");

        if (_targetData.hasProperty(indexBufferProperty)) {
            _indexBuffer = _targetData.getUnsafePointer(indexBufferProperty);
        }else{
            throw "no  _indexBuffer ";
        }

        var surfaceFirstIndexProperty = Store.getActualPropertyName(_variables, "surface[@{surfaceUuid}].firstIndex");

        if (!_targetData.hasProperty(surfaceFirstIndexProperty)) {
            var geometryFirstIndexProperty = Store.getActualPropertyName(_variables, "geometry[@{geometryUuid}].firstIndex");

            if (_targetData.hasProperty(geometryFirstIndexProperty)) {
                _firstIndex = _targetData.getUnsafePointer(geometryFirstIndexProperty);
            }
        }
        else {
            _firstIndex = _targetData.getUnsafePointer(surfaceFirstIndexProperty);
        }

        var surfaceNumIndicesProperty = Store.getActualPropertyName(_variables, "surface[@{surfaceUuid}].numIndices");

        if (!_targetData.hasProperty(surfaceNumIndicesProperty)) {
            var geometryNumIndicesProperty = Store.getActualPropertyName(_variables, "geometry[@{geometryUuid}].numIndices");

            if (_targetData.hasProperty(geometryNumIndicesProperty)) {
                _numIndices = _targetData.getUnsafePointer(geometryNumIndicesProperty);
            }
        }
        else {
            _numIndices = _targetData.getUnsafePointer(surfaceNumIndicesProperty);
        }
    }

    public function getEyeSpacePosition() {
        var modelView:Mat4 = Mat4.identity(new Mat4());

        if (_modelToWorldMatrix != null) {
            modelView = _modelToWorldMatrix.value;
        }
        //math
        if (_worldToScreenMatrix != null) {
            modelView = _worldToScreenMatrix.value * (modelView) ;
        }

        var tmp:Vec4 = modelView * (new Vec4(_centerPosition.value.x, _centerPosition.value.y, _centerPosition.value.z, 1));
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

    function getStore(source:minko.data.Binding.Source) {
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

    function resolveBinding(inputName:String, bindings:StringMap< Binding>):ResolvedBinding {
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


    function setUniformValueFromStore(input:UniformInput, propertyName:String, store:Store) {
        var isArray:Bool = input.name.charAt(input.name.length - 1) == ']';
        var data =   store.getUnsafePointer(propertyName) ; //todo
        if (isArray == false) {
            switch (input.type)
            {
                case ProgramInputs.InputType.bool1:
                    setUniformValue(_uniformBool, input.location, 1, input.size, UnsafePointerArrayBuffer.vecInts1, data);

                case ProgramInputs.InputType.bool2:
                    setUniformValue(_uniformBool, input.location, 2, input.size, UnsafePointerArrayBuffer.vecInts2, data);

                case ProgramInputs.InputType.bool3:
                    setUniformValue(_uniformBool, input.location, 3, input.size, UnsafePointerArrayBuffer.vecInts3, data);

                case ProgramInputs.InputType.bool4:
                    setUniformValue(_uniformBool, input.location, 4, input.size, UnsafePointerArrayBuffer.vecInts4, data);

                case ProgramInputs.InputType.int1:
                    setUniformValue(_uniformInt, input.location, 1, input.size, UnsafePointerArrayBuffer.vecInts1, data);

                case ProgramInputs.InputType.int2:
                    setUniformValue(_uniformInt, input.location, 2, input.size, UnsafePointerArrayBuffer.vecInts2, data);

                case ProgramInputs.InputType.int3:
                    setUniformValue(_uniformInt, input.location, 3, input.size, UnsafePointerArrayBuffer.vecInts3, data);

                case ProgramInputs.InputType.int4:
                    setUniformValue(_uniformInt, input.location, 4, input.size, UnsafePointerArrayBuffer.vecInts4, data);

                case ProgramInputs.InputType.float1:
                    setUniformValue(_uniformFloat, input.location, 1, input.size, UnsafePointerArrayBuffer.vecFloats1, data);

                case ProgramInputs.InputType.float2:
                    setUniformValue(_uniformFloat, input.location, 2, input.size, UnsafePointerArrayBuffer.vecFloats2, data);

                case ProgramInputs.InputType.float3:
                    setUniformValue(_uniformFloat, input.location, 3, input.size, UnsafePointerArrayBuffer.vecFloats3, data);

                case ProgramInputs.InputType.float4:
                    setUniformValue(_uniformFloat, input.location, 4, input.size, UnsafePointerArrayBuffer.vecFloats4, data);

                case ProgramInputs.InputType.float16:
                    setUniformValue(_uniformFloat, input.location, 16, input.size, UnsafePointerArrayBuffer.matFloats, data);

                case ProgramInputs.InputType.sampler2d | ProgramInputs.InputType.samplerCube:
                    var samplerIt:SamplerValue = Lambda.find(_samplers, function(samplerValue:SamplerValue) {
                        return samplerValue.location == input.location;
                    });
                    var texture:UnsafePointer<Texture> = cast store.getUnsafePointer(propertyName) ;
                    if (samplerIt == null) {
                        _samplers.push(
                            new SamplerValue((_program.setTextureNames.length + _samplers.length), texture, input.location)
                        );
                    }
                    else {
                        samplerIt.texture = texture;
                    }


                case ProgramInputs.InputType.float9 | ProgramInputs.InputType.unknown:
                    trace("unsupported program input type: " + ProgramInputs.typeToString(input.type));
                    throw ("unsupported program input type: " + ProgramInputs.typeToString(input.type));

            }
        } else {
            switch (input.type)
            {
                case ProgramInputs.InputType.bool1:
                    setUniformValue(_uniformBool, input.location, 1, input.size, UnsafePointerArrayBuffer.vecsInts1, data);

                case ProgramInputs.InputType.bool2:
                    setUniformValue(_uniformBool, input.location, 2, input.size, UnsafePointerArrayBuffer.vecsInts2, data);

                case ProgramInputs.InputType.bool3:
                    setUniformValue(_uniformBool, input.location, 3, input.size, UnsafePointerArrayBuffer.vecsInts3, data);

                case ProgramInputs.InputType.bool4:
                    setUniformValue(_uniformBool, input.location, 4, input.size, UnsafePointerArrayBuffer.vecsInts4, data);

                case ProgramInputs.InputType.int1:
                    setUniformValue(_uniformInt, input.location, 1, input.size, UnsafePointerArrayBuffer.vecsInts1, data);

                case ProgramInputs.InputType.int2:
                    setUniformValue(_uniformInt, input.location, 2, input.size, UnsafePointerArrayBuffer.vecsInts2, data);

                case ProgramInputs.InputType.int3:
                    setUniformValue(_uniformInt, input.location, 3, input.size, UnsafePointerArrayBuffer.vecsInts3, data);

                case ProgramInputs.InputType.int4:
                    setUniformValue(_uniformInt, input.location, 4, input.size, UnsafePointerArrayBuffer.vecsInts4, data);

                case ProgramInputs.InputType.float1:
                    setUniformValue(_uniformFloat, input.location, 1, input.size, UnsafePointerArrayBuffer.vecsFloats1, data);

                case ProgramInputs.InputType.float2:
                    setUniformValue(_uniformFloat, input.location, 2, input.size, UnsafePointerArrayBuffer.vecsFloats2, data);

                case ProgramInputs.InputType.float3:
                    setUniformValue(_uniformFloat, input.location, 3, input.size, UnsafePointerArrayBuffer.vecsFloats3, data);

                case ProgramInputs.InputType.float4:
                    setUniformValue(_uniformFloat, input.location, 4, input.size, UnsafePointerArrayBuffer.vecsFloats4, data);

                case ProgramInputs.InputType.float16:
                    setUniformValue(_uniformFloat, input.location, 16, input.size, UnsafePointerArrayBuffer.matsFloats, data);

                case ProgramInputs.InputType.sampler2d | ProgramInputs.InputType.samplerCube:

                    trace("unsupported program input type: " + ProgramInputs.typeToString(input.type));
                    throw ("unsupported program input type: " + ProgramInputs.typeToString(input.type));

                case ProgramInputs.InputType.float9 | ProgramInputs.InputType.unknown:
                    trace("unsupported program input type: " + ProgramInputs.typeToString(input.type));
                    throw ("unsupported program input type: " + ProgramInputs.typeToString(input.type));

            }
        }

    }

    function setSamplerStateValueFromStore(input:UniformInput, propertyName:String, store:Store, samplerStateProperty:String) {

        var it:SamplerValue = Lambda.find(_samplers, function(sampler:SamplerValue) {
            return sampler.location == input.location;
        });

        if (it != null) {
            var sampler = it;

            if (samplerStateProperty == SamplerStates.PROPERTY_WRAP_MODE) {
                if (store.hasProperty(propertyName)) {
                    sampler.wrapMode = store.getUnsafePointer(propertyName);
                }
                else {
                    sampler.wrapMode = new UnsafePointer(SamplerStates.DEFAULT_WRAP_MODE);
                }
            }
            else if (samplerStateProperty == SamplerStates.PROPERTY_TEXTURE_FILTER) {
                if (store.hasProperty(propertyName)) {
                    sampler.textureFilter = store.getUnsafePointer(propertyName);
                }
                else {
                    sampler.textureFilter = new UnsafePointer(SamplerStates.DEFAULT_TEXTURE_FILTER);
                }
            }
            else if (samplerStateProperty == SamplerStates.PROPERTY_MIP_FILTER) {
                if (store.hasProperty(propertyName)) {
                    sampler.mipFilter = store.getUnsafePointer(propertyName);
                }
                else {
                    sampler.mipFilter = new UnsafePointer(SamplerStates.DEFAULT_MIP_FILTER);
                }
            }
        }
    }

    function setStateValueFromStore(stateName:String, store:Store) {
        if (stateName == States.PROPERTY_PRIORITY) {
            if (store.hasProperty(stateName)) {
                _priority = store.getUnsafePointer(stateName);
            }
            else {
                _priority = new UnsafePointer(States.DEFAULT_PRIORITY);
            }
        }
        else if (stateName == States.PROPERTY_ZSORTED) {
            if (store.hasProperty(stateName)) {
                _zSorted = store.getUnsafePointer(stateName);
            }
            else {
                _zSorted = new UnsafePointer(States.DEFAULT_ZSORTED);
            }
        }
        else if (stateName == States.PROPERTY_BLENDING_SOURCE) {
            if (store.hasProperty(stateName)) {
                _blendingSourceFactor = store.getUnsafePointer(stateName);
            }
            else {
                _blendingSourceFactor = new UnsafePointer(States.DEFAULT_BLENDING_SOURCE);
            }
        }
        else if (stateName == States.PROPERTY_BLENDING_DESTINATION) {
            if (store.hasProperty(stateName)) {
                _blendingDestinationFactor = store.getUnsafePointer(stateName);
            }
            else {
                _blendingDestinationFactor = new UnsafePointer(States.DEFAULT_BLENDING_DESTINATION);
            }
        }
        else if (stateName == States.PROPERTY_COLOR_MASK) {
            if (store.hasProperty(stateName)) {
                _colorMask = store.getUnsafePointer(stateName);
            }
            else {
                _colorMask = new UnsafePointer(States.DEFAULT_COLOR_MASK);
            }
        }
        else if (stateName == States.PROPERTY_DEPTH_MASK) {
            if (store.hasProperty(stateName)) {
                _depthMask = store.getUnsafePointer(stateName);
            }
            else {
                _depthMask = new UnsafePointer(States.DEFAULT_DEPTH_MASK);
            }
        }
        else if (stateName == States.PROPERTY_DEPTH_FUNCTION) {
            if (store.hasProperty(stateName)) {
                _depthFunc = store.getUnsafePointer(stateName);
            }
            else {
                _depthFunc = new UnsafePointer(States.DEFAULT_DEPTH_FUNCTION);
            }
        }
        else if (stateName == States.PROPERTY_TRIANGLE_CULLING) {
            if (store.hasProperty(stateName)) {
                _triangleCulling = store.getUnsafePointer(stateName);
            }
            else {
                _triangleCulling = new UnsafePointer(States.DEFAULT_TRIANGLE_CULLING);
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_FUNCTION) {
            if (store.hasProperty(stateName)) {
                _stencilFunction = store.getUnsafePointer(stateName);
            }
            else {
                _stencilFunction = new UnsafePointer(States.DEFAULT_STENCIL_FUNCTION);
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_REFERENCE) {
            if (store.hasProperty(stateName)) {
                _stencilReference = store.getUnsafePointer(stateName);
            }
            else {
                _stencilReference = new UnsafePointer(States.DEFAULT_STENCIL_REFERENCE);
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_MASK) {
            if (store.hasProperty(stateName)) {
                _stencilMask = store.getUnsafePointer(stateName);
            }
            else {
                _stencilMask = new UnsafePointer(States.DEFAULT_STENCIL_MASK);
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_FAIL_OPERATION) {
            if (store.hasProperty(stateName)) {
                _stencilFailOp = store.getUnsafePointer(stateName);
            }
            else {
                _stencilFailOp = new UnsafePointer(States.DEFAULT_STENCIL_FAIL_OPERATION);
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_ZFAIL_OPERATION) {
            if (store.hasProperty(stateName)) {
                _stencilZFailOp = store.getUnsafePointer(stateName);
            }
            else {
                _stencilZFailOp = new UnsafePointer(States.DEFAULT_STENCIL_ZFAIL_OPERATION);
            }
        }
        else if (stateName == States.PROPERTY_STENCIL_ZPASS_OPERATION) {
            if (store.hasProperty(stateName)) {
                _stencilZPassOp = store.getUnsafePointer(stateName);
            }
            else {
                _stencilZPassOp = new UnsafePointer(States.DEFAULT_STENCIL_ZPASS_OPERATION);
            }
        }
        else if (stateName == States.PROPERTY_SCISSOR_TEST) {
            if (store.hasProperty(stateName)) {
                _scissorTest = store.getUnsafePointer(stateName);
            }
            else {
                _scissorTest = new UnsafePointer(States.DEFAULT_SCISSOR_TEST);
            }
        }
        else if (stateName == States.PROPERTY_SCISSOR_BOX) {
            if (store.hasProperty(stateName)) {
                _scissorBox = store.getUnsafePointer(stateName);
            }
            else {
                _scissorBox = new UnsafePointer(States.DEFAULT_SCISSOR_BOX);
            }
        }
        else if (stateName == States.PROPERTY_TARGET) {
            if (store.hasProperty(stateName)) {

                _target = store.getUnsafePointer(stateName) ;
            }
            else {
                _target = new UnsafePointer(States.DEFAULT_TARGET);
            }
        }
    }

    function setAttributeValueFromStore(input:AttributeInput, propertyName:String, store:Store) {
        var attr:VertexAttribute = store.get(propertyName);
        //need vertexSize bind
        _attributes.push(new AttributeValue(input.location, attr.resourceId, attr.size, attr.vertexSize, attr.offset));
    }


    static private function setUniformValue<T>(uniforms:Array<UniformValue<T>>, location, size, count, dataArray:Dynamic->Array<T>, data:Any) {
        var it:UniformValue<T> = Lambda.find(uniforms, function(u:UniformValue<T>) {
            return u.location == location;
        });
        if (it == null) {
            it = new UniformValue<T>(location, size, count);
            uniforms.push(it);
        }
        it.data = data;
        setUnsafePointerArrayBuffer(dataArray,data);
    }
    static private function setUnsafePointerArrayBuffer<T>(  dataArray:Dynamic->Array<T>, data:UnsafePointer<Dynamic>) {
        //it.applyFunc = dataArray;
        if(data.buffer==null){
            var buffer=new UnsafePointerArrayBuffer<T>();
            buffer.applyFunc=dataArray;
            buffer.applyDone(data.value);
            data.buffer=buffer;

        }
    }
}
