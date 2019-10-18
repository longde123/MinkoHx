package minko.render;
import minko.render.DrawCall;
import String;
import Array;
import glm.Vec3;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import minko.component.Renderer.EffectVariables;
import minko.data.Binding;
import minko.data.BindingMap.BindingMapBase;
import minko.data.BindingMap.MacroBinding;
import minko.data.BindingMap.MacroBindingMap;
import minko.data.BindingMap.MacroType;
import minko.data.Provider;
import minko.data.ResolvedBinding;
import minko.data.Store;
import minko.render.DrawCallPool.DrawCallSlot;
import minko.render.ProgramInputs.InputType;
import minko.render.ProgramInputs.UniformInput;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal3;


typedef PropertyRebindFuncMap = ObjectMap<DrawCall, Array<Void -> Void>>;
typedef DrawCallList = Array<DrawCall> ;
typedef DrawCallList2U = Tuple<DrawCallList, DrawCallList>;
typedef DrawCallSlotBindings ={
    var uniformBinding: Array<DrawCallSlot>;
    var samplerStatesBinding: Array<DrawCallSlot>;
    var stateBinding:Array<DrawCallSlot>;
    var macroBinding:Array<DrawCallSlot>;
}
typedef DrawCallSlot =Tuple<String,SignalSlot3<Store, Provider, String>>;

//draw call 运行期 资源 去掉  增加 删除  只能 修改
@:expose("minko.render.DrawCallPool")
class DrawCallPool {
    //_drawCalls macroBindingKey  DrawCallList


    private var _batchId:Int;
    private var _drawCalls:StringMap<DrawCallList2U > ;
    private var _drawCallsKeys:Array<String> ;
    private var _invalidDrawCalls:ObjectMap< DrawCall, Tuple<Bool, EffectVariables>>;
    private var _drawCallsToBeSorted:Array<DrawCall>;
    private var _propChangedSlot:ObjectMap< DrawCall, DrawCallSlotBindings>;//drawCallKey
    private var _sortUsefulPropertyChangedSlot:ObjectMap< DrawCall, Array<DrawCallSlot>>;//drawCallKey
    private var _sortUsefulPropertyNames:Array<String>;
    private var _zSortUsefulPropertyChangedSlot:ObjectMap< DrawCall,Array<DrawCallSlot>>;//drawCallKey
    private var _zSortUsefulPropertyNames:Array<String>;
    private var _mustZSort:Bool;

    private var _drawCallToPropRebindFuncs:PropertyRebindFuncMap;

    public function new() {
        this._zSortUsefulPropertyNames = [];
        this._sortUsefulPropertyNames = [];
        _zSortUsefulPropertyNames = [
        "modelToWorldMatrix",
        "material[@{materialUuid}].priority",
        "material[@{materialUuid}].zSorted",
        "geometry[@{geometryUuid}].position"
        ];

        _sortUsefulPropertyNames = [
        "material[@{materialUuid}].priority",
        "material[@{materialUuid}].zSorted",
        "material[@{materialUuid}].target"
        ];
        this._batchId = 0;
        this._drawCalls = new StringMap<DrawCallList2U >();
        this._drawCallsKeys = [];

        this._invalidDrawCalls = new ObjectMap< DrawCall, Tuple<Bool, EffectVariables>>();
        this._drawCallToPropRebindFuncs = new PropertyRebindFuncMap();
        this._drawCallsToBeSorted = new Array<DrawCall>();
        this._propChangedSlot = new ObjectMap< DrawCall, DrawCallSlotBindings>();
        this._sortUsefulPropertyChangedSlot = new ObjectMap< DrawCall,Array<DrawCallSlot>>();
        this._zSortUsefulPropertyChangedSlot = new ObjectMap< DrawCall,Array<DrawCallSlot>>();
        this._mustZSort = false;
    }

    public function dispose() {
        //todo

        if (_propChangedSlot != null) {
            _propChangedSlot = null;
        }
        if (_drawCallToPropRebindFuncs != null) {
            _drawCallToPropRebindFuncs = null;
        }
    }
    public var drawCallsKeys(get, null):Array<String> ;

    function get_drawCallsKeys() {

        return _drawCallsKeys;
    }
    public var drawCalls(get, null):StringMap<DrawCallList2U > ;

    function get_drawCalls() {

        return _drawCalls;
    }

    public function addDrawCalls(effect:Effect, techniqueName:String, variables:EffectVariables, rootData:Store, rendererData:Store, targetData:Store) {
        var technique:Array<Pass> = effect.technique(techniqueName);

        _batchId++;
        for (pass in technique) {
            var drawCall:DrawCall = new DrawCall(_batchId, pass, variables, rootData, rendererData, targetData);
            //todo 	var drawCall = [new minko_render_DrawCall(this._batchId,pass,variables,rootData,rendererData,targetData)];
            //drawCall[0]
            initializeDrawCall(drawCall);

            // if the draw call is meant only for post-processing, then it should only exist once
            if (!pass.isForward) {
                var seekedDrawCall = findDrawCall(function(d:DrawCall) {
                    return d.program == drawCall.program ;
                });

                // FIXME: cumbersome and wasteful to completely init. a DrawCall just to discard it
                if (seekedDrawCall != null) {
                    seekedDrawCall.batchIDs.push(_batchId);
                    drawCall = null;
                    continue;
                }
            }

            addDrawCallToSortedBucket(drawCall);
        }
        technique=null;

        return _batchId;
    }

    inline function _removeDrawCalls(drawCalls:Array<DrawCall>, batchId) {
        return drawCalls.filter(function(drawCall:DrawCall) {
            var batchIDs:Array<Int> = drawCall.batchIDs ;
            var it = Lambda.has(batchIDs, batchId);

            if (it != false) {
                batchIDs.remove(batchId);

                if (batchIDs.length != 0) {
                    return !false;
                }

                unwatchProgramSignature(drawCall, drawCall.pass.macroBindings, drawCall.rootData, drawCall.rendererData, drawCall.targetData);
                unbindDrawCall(drawCall);

                _invalidDrawCalls.remove(drawCall);
                _drawCallsToBeSorted.remove(drawCall);
                drawCall.dispose();
                drawCall = null;

//Debug.Assert(_drawCallToPropRebindFuncs.count(drawCall) == 0);
//for (var it = _propChangedSlot.GetEnumerator(); it != _propChangedSlot.end(); ++it)
//{
//Debug.Assert(it.first.second != drawCall);
//}

                return !true;
            }

            return !false;
        }) ;
    }

    public function removeDrawCalls(batchId) {
        for (priorityAndTargetIdToDrawCalls in _drawCalls) {

            priorityAndTargetIdToDrawCalls.first = _removeDrawCalls(priorityAndTargetIdToDrawCalls.first, batchId);
            priorityAndTargetIdToDrawCalls.second = _removeDrawCalls(priorityAndTargetIdToDrawCalls.second, batchId);

        }
    }

    public function invalidateDrawCalls(batchId:Int, variables:EffectVariables) {
        foreachDrawCall(function(drawCall:DrawCall) {
            var batchIDs = drawCall.batchIDs ;

            var it = Lambda.has(batchIDs, batchId);

            if (it != false) {
                _invalidDrawCalls.set(drawCall, new Tuple(true, variables));
            }
        });
    }

    public function update(forceSort = false, mustZSort = false) {
        for (invalidDrawCall in _invalidDrawCalls.keys()) {
            var drawCallPtr = invalidDrawCall;

            initializeDrawCall(drawCallPtr, true);
        }
        _invalidDrawCalls = new ObjectMap< DrawCall, Tuple<Bool, EffectVariables>>();

        for (drawCallPtrAndFuncList in _drawCallToPropRebindFuncs.iterator()) {
            for (func in drawCallPtrAndFuncList) {
                func();
            }
        }

        _drawCallToPropRebindFuncs = new PropertyRebindFuncMap();


        for (drawCall in _drawCallsToBeSorted) {
            removeDrawCallFromSortedBucket(drawCall);
            addDrawCallToSortedBucket(drawCall);
        }

        _drawCallsToBeSorted = new Array<DrawCall>();

        var finalMustZSort = forceSort || _mustZSort || mustZSort;

        if (finalMustZSort) {
            _mustZSort = false;

            zSortDrawCalls();
        }
    }

    public function clear() {
        this._drawCalls = new StringMap< DrawCallList2U >();
        this._drawCallsKeys = [];
        this._invalidDrawCalls = new ObjectMap< DrawCall, Tuple<Bool, EffectVariables>>();
        this._propChangedSlot = new ObjectMap< DrawCall,DrawCallSlotBindings>();
        this._drawCallToPropRebindFuncs = new PropertyRebindFuncMap();
        this._sortUsefulPropertyChangedSlot = new ObjectMap< DrawCall,Array<DrawCallSlot>>();
        this._zSortUsefulPropertyChangedSlot = new ObjectMap< DrawCall,Array<DrawCallSlot>>();
    }

    public var numDrawCalls(get, null):Int;

    function get_numDrawCalls() {
        var numDrawCalls = 0 ;

        for (drawCalls in _drawCalls) {
            numDrawCalls += drawCalls.first.length;
            numDrawCalls += drawCalls.second.length;
        }

        return numDrawCalls;
    }

    private function watchProgramSignature(drawCall:DrawCall, macroBindings:MacroBindingMap, rootData:Store, rendererData:Store, targetData:Store) {
//        for (macroNameAndBinding in macroBindings.bindings.keys()) {
//            var macroName = macroNameAndBinding;
//            var macroBinding:MacroBinding = macroBindings.bindings.get(macroNameAndBinding);
//            var store:Store = macroBinding.source == Source.ROOT ? rootData : (macroBinding.source == Source.RENDERER ? rendererData : targetData);
//            var propertyName:String = Store.getActualPropertyName(drawCall.variables, macroBinding.propertyName);
//
//
//
//            if (macroBindings.types.get(macroName) != MacroType.UNSET) {
//                addMacroCallback(drawCall,propertyName, store.getPropertyChanged(propertyName), function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                    macroPropertyChangedHandler(drawCall,macroBinding);
//                });
//            }
//            else {
//                var hasProperty = store.hasProperty(propertyName);
//                if (hasProperty) {
//                    addMacroCallback(drawCall,propertyName, store.getPropertyRemoved(propertyName) , function(s, UnnamedParameter1, p) {
//                        macroPropertyRemovedHandler(drawCall,macroBinding, propertyName, s);
//                    });
//                }
//                else {
//                    addMacroCallback(drawCall,propertyName, store.getPropertyAdded(propertyName), function(s, UnnamedParameter1, p) {
//                        macroPropertyAddedHandler(drawCall,macroBinding, propertyName, s);
//                    });
//                }
//            }
//        }
    }

    private function unwatchProgramSignature(drawCall:DrawCall, macroBindings:MacroBindingMap, rootData:Store, rendererData:Store, targetData:Store) {

        var drawCallPropChangedSlot=_propChangedSlot.get(drawCall);
        for (macroNameAndBinding in       drawCallPropChangedSlot.macroBinding) {
            removeMacroCallback(drawCall,macroNameAndBinding.first);
        }
        drawCallPropChangedSlot.macroBinding=[];
    }


    public function macroPropertyAddedHandler(drawCall:DrawCall,macroBinding:MacroBinding, propertyName:String, store:Store ) {

        removeMacroCallback(drawCall,propertyName);
        addMacroCallback(drawCall,propertyName, store.getPropertyRemoved(propertyName),
        function(s:Store, UnnamedParameter1:Provider, p:String) {
            macroPropertyRemovedHandler(drawCall,macroBinding, propertyName, s);
        });

        macroPropertyChangedHandler(drawCall,macroBinding);
    }

    public function macroPropertyRemovedHandler(drawCall:DrawCall,macroBinding:MacroBinding, propertyName:String, store:Store ) {
        // If the store still has the property, it means that it was not really removed
        // but that one of the copies of the properties was removed (ie same material added multiple
        // times to the same store). Thus the macro state should not be affected.
        if (store.hasProperty(propertyName)) {
            return;
        }


        removeMacroCallback(drawCall,propertyName);
        addMacroCallback(drawCall,propertyName, store.getPropertyAdded(propertyName),
        function(s:Store, UnnamedParameter1:Provider, p:String) {
            macroPropertyAddedHandler(drawCall,macroBinding, propertyName, s);
        });

        macroPropertyChangedHandler(drawCall,macroBinding);
    }

    public function macroPropertyChangedHandler(drawCall:DrawCall,macroBinding:MacroBinding) {

            _invalidDrawCalls.set(drawCall, new Tuple<Bool, EffectVariables>(false, new EffectVariables()));

    }

    private function initializeDrawCall(drawCall:DrawCall, forceRebind = false) {
        var invalidDrawCallIt:Tuple<Bool, EffectVariables> = _invalidDrawCalls.get(drawCall);
        var variablesChanged = false;
        if (invalidDrawCallIt != null) {
            variablesChanged = invalidDrawCallIt.first;
        }

        var newVariables:EffectVariables = new EffectVariables();

        if (variablesChanged) {
            newVariables = invalidDrawCallIt.second;
        }

        var variables:EffectVariables = variablesChanged ? newVariables : drawCall.variables ;

        var pass:Pass = drawCall.pass ;

        var programAndSignature:Tuple<Program, ProgramSignature> = pass.selectProgram(variables, drawCall.targetData, drawCall.rendererData, drawCall.rootData);

        var program:Program = programAndSignature.first;
        if (variablesChanged) {
            drawCall.variables = variables ;
        }
        if (program == drawCall.program ) {

            return;
        }
        if(_propChangedSlot.exists(drawCall)){

            unwatchProgramSignature(drawCall, drawCall.pass.macroBindings, drawCall.rootData, drawCall.rendererData, drawCall.targetData);
            unbindDrawCall(drawCall);
        }
        if(!_propChangedSlot.exists(drawCall)){
            _propChangedSlot.set(drawCall,{
                uniformBinding:[],
                samplerStatesBinding: [],
                stateBinding:[],
                macroBinding:[]
            });
        }
        bindDrawCall(drawCall, pass, program, forceRebind);

        if (programAndSignature.second != null) {
            watchProgramSignature(drawCall, drawCall.pass.macroBindings, drawCall.rootData, drawCall.rendererData, drawCall.targetData);
        }
    }


    public function addMacroCallback(drawCall:DrawCall,propertyName:String, signal:Signal3<Store, Provider, String>, callback:Store -> Provider -> String -> Void) {
        if(!hasMacroCallback(drawCall,propertyName)){
            var drawCallPropChangedSlot=_propChangedSlot.get(drawCall);
            var changedSlot=signal.connect(callback);
            addPropChangedSlot(  drawCallPropChangedSlot.macroBinding, new DrawCallSlot(propertyName,changedSlot));
        }else{
            trace("addMacroCallback null");
        }


    }

    public function removeMacroCallback(drawCall:DrawCall,propertyName:String) {
        if(hasMacroCallback(drawCall,propertyName)){
            var drawCallPropChangedSlot=_propChangedSlot.get(drawCall);
            drawCallPropChangedSlot.macroBinding=removePropChangedSlot(  drawCallPropChangedSlot.macroBinding,propertyName);
        }else{
            trace("removeMacroCallback null");
        }

    }

    public function hasMacroCallback(drawCall:DrawCall,propertyName:String) {

        var drawCallPropChangedSlot=_propChangedSlot.get(drawCall);
        if(!_propChangedSlot.exists(drawCall)){
            return false;
        }
        return Lambda.exists( drawCallPropChangedSlot.macroBinding ,function(m:DrawCallSlot) return m.first==propertyName);
    }
    function removePropChangedSlot(bindings: Array<DrawCallSlot>,propertyName:String){
        var dc:DrawCallSlot= Lambda.find(bindings,function(b:DrawCallSlot)return b.first==propertyName);
        dc.second.dispose();
        dc.second=null;
        var tmp= bindings.filter(function(b:DrawCallSlot)return b.first!=propertyName);
        return tmp;
    }
    function addPropChangedSlot(bindings: Array<DrawCallSlot>,dc:DrawCallSlot){
        bindings.push(dc);
    }
    private function uniformBindingPropertyAddedHandler(drawCall:DrawCall, input:UniformInput, uniformBindingMap:BindingMapBase<Binding>, forceRebind = false) {
        if (!forceRebind && _invalidDrawCalls.exists(drawCall)) {
            return;
        }

        var resolvedBinding:ResolvedBinding = drawCall.bindUniform(input, uniformBindingMap.bindings, uniformBindingMap.defaultValues);
//
//
//        if (resolvedBinding != null) {
//            var propertyName = resolvedBinding.propertyName;
//            var propertyExist = resolvedBinding.store.hasProperty(propertyName);
//            //var signal:Signal3<Store, Provider, String> = resolvedBinding.store.getPropertyChanged(propertyName);
//            var signal:Signal3<Store, Provider, String> = propertyExist ? resolvedBinding.store.getPropertyRemoved(propertyName) : resolvedBinding.store.getPropertyAdded(propertyName);
//            var drawCallPropChangedSlot=_propChangedSlot.get(drawCall);
//
//
//            var changedSlot = signal.connect(function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                drawCallPropChangedSlot.uniformBinding=removePropChangedSlot(drawCallPropChangedSlot.uniformBinding,   propertyName);
//                if (_drawCallToPropRebindFuncs.exists(drawCall) == false) {
//                    _drawCallToPropRebindFuncs.set(drawCall, []);
//                }
//                _drawCallToPropRebindFuncs.get(drawCall).push(function() {
//                    uniformBindingPropertyAddedHandler(drawCall, input, uniformBindingMap, forceRebind);
//                });
//            }, 0, true);
//            addPropChangedSlot(drawCallPropChangedSlot.uniformBinding,     new DrawCallSlot(propertyName,changedSlot) );
//
//
//            // If this draw call needs to be sorted
//            // => we listen to the useful properties
//            if (propertyExist && drawCall.zSorted) {
//
//                var propertyRelatedToZSortIt = Lambda.find(_zSortUsefulPropertyNames, function(zSortUsefulPropertyName) {
//                    return Store.getActualPropertyName(drawCall.variables, zSortUsefulPropertyName) == propertyName;
//                });
//
//                if (propertyRelatedToZSortIt != null) {
//                    var zSortUsefulPropertyChangedSlot=_zSortUsefulPropertyChangedSlot.get(drawCall);
//                    zSortUsefulPropertyChangedSlot.push( new DrawCallSlot(propertyName,
//                        resolvedBinding.store.getPropertyChanged(propertyName).connect(
//                        function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                            _mustZSort = true;
//                        })));
//                }
//            }
//        }
        resolvedBinding = null;
        if (input.type == InputType.sampler2d || input.type == InputType.samplerCube) {
            samplerStatesBindingPropertyAddedHandler(drawCall, input, uniformBindingMap);
        }
    }

    function samplerStatesBindingPropertyAddedHandler(drawCall:DrawCall, input:UniformInput, uniformBindingMap:BindingMapBase<Binding>) {
        var resolvedBindings:Array<ResolvedBinding> = drawCall.bindSamplerStates(input, uniformBindingMap.bindings, uniformBindingMap.defaultValues);
//
//        for (resolvedBinding in resolvedBindings) {
//            if (resolvedBinding != null) {
//                var propertyName = resolvedBinding.propertyName;
//                var propertyExist = resolvedBinding.store.hasProperty(propertyName);
//                //var signal:Signal3<Store, Provider, String> = resolvedBinding.store.getPropertyChanged(propertyName);
//                var signal:Signal3<Store, Provider, String> =propertyExist ? resolvedBinding.store.getPropertyRemoved(propertyName) : resolvedBinding.store.getPropertyAdded(propertyName);
//
//                var drawCallPropChangedSlot=_propChangedSlot.get(drawCall);
//                var changedSlot = signal.connect(
//                    function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                        drawCallPropChangedSlot.samplerStatesBinding=removePropChangedSlot(drawCallPropChangedSlot.samplerStatesBinding,propertyName);
//                        if (_drawCallToPropRebindFuncs.exists(drawCall) == false) {
//                            _drawCallToPropRebindFuncs.set(drawCall, []);
//                        }
//                        _drawCallToPropRebindFuncs.get(drawCall).push(function() {
//                            samplerStatesBindingPropertyAddedHandler(drawCall, input, uniformBindingMap);
//                        });
//                    }, 0, true);
//                addPropChangedSlot(drawCallPropChangedSlot.samplerStatesBinding, new DrawCallSlot(propertyName, changedSlot ));
//            }
//        }
        resolvedBindings=null;
    }

    function stateBindingPropertyAddedHandler(stateName:String, drawCall:DrawCall, stateBindingMap:BindingMapBase<Binding>, forceRebind:Bool) {


        var resolvedBinding:ResolvedBinding = drawCall.bindState(stateName, stateBindingMap.bindings, stateBindingMap.defaultValues);
//
//        if (resolvedBinding != null) {
//            var bindingPtr = resolvedBinding.binding;
//            var propertyName = resolvedBinding.propertyName;
//            var propertyExist = resolvedBinding.store.hasProperty(propertyName);
//            //var signal:Signal3<Store, Provider, String> = resolvedBinding.store.getPropertyChanged(propertyName);
//            var signal:Signal3<Store, Provider, String> = propertyExist ? resolvedBinding.store.getPropertyRemoved(propertyName) : resolvedBinding.store.getPropertyAdded(propertyName);
//
//            var drawCallPropChangedSlot=_propChangedSlot.get(drawCall);
//            var changedSlot = signal.connect(
//                function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                    drawCallPropChangedSlot.stateBinding=removePropChangedSlot(drawCallPropChangedSlot.stateBinding,propertyName);
//                    if (_drawCallToPropRebindFuncs.exists(drawCall) == false) {
//                        _drawCallToPropRebindFuncs.set(drawCall, []);
//                    }
//                    _drawCallToPropRebindFuncs.get(drawCall).push(function() {
//                        stateBindingPropertyAddedHandler(stateName, drawCall, stateBindingMap, forceRebind);
//                    });
//                }, 0, true);
//            addPropChangedSlot(   drawCallPropChangedSlot.stateBinding, new DrawCallSlot(propertyName, changedSlot ));
//
//            var propertyRelatedToSortIt = Lambda.find(_sortUsefulPropertyNames, function(sortUsefulPropertyName) {
//                return Store.getActualPropertyName(drawCall.variables, sortUsefulPropertyName) == propertyName;
//            });
//
//            if (propertyRelatedToSortIt != null) {
//                if (_sortUsefulPropertyChangedSlot.exists(drawCall) == false) {
//                    _sortUsefulPropertyChangedSlot.set(drawCall, []);
//                }
//                var sortUsefulPropertyChangedSlot=_sortUsefulPropertyChangedSlot.get(drawCall);
//                sortUsefulPropertyChangedSlot.push( new DrawCallSlot(propertyName, resolvedBinding.store.getPropertyChanged(propertyName).connect(
//                    function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
//                        _drawCallsToBeSorted.push(drawCall);
//                    })));
//            }
//
//        }

        resolvedBinding = null;
    }

    private static function compareZSortedDrawCalls(a:DrawCall, b:DrawCall) {
        var aPosition:Vec3 = a.getEyeSpacePosition();
        var bPosition:Vec3 = b.getEyeSpacePosition();
        if (aPosition.z > bPosition.z) {
            return -1;
        }
        else if (aPosition.z < bPosition.z) {
            return 1;
        } else {
            return 0;
        }
    }

    private static function compareDrawCalls(a:String, b:String) {
        a = a.toUpperCase();
        b = b.toUpperCase();

        if (a > b) {
            return -1;
        }
        else if (a < b) {
            return 1;
        } else {
            return 0;
        }
    }
    inline public static function sortPropertyTuple(m:Float, s:Int) {
        return m + "_" + s;
    }
    private function addDrawCallToSortedBucket(drawCall:DrawCall) {
        var priority = drawCall.priority;
        var targetId = drawCall.target != null ? drawCall.target.id : 0;
        var zSortedIndex = drawCall.zSorted ? 1 : 0;
        var _sortPropertyTuple = sortPropertyTuple(priority, targetId);
        if (!_drawCalls.exists(_sortPropertyTuple)) {
            this._drawCallsKeys.push(_sortPropertyTuple);
            this._drawCallsKeys.sort(compareDrawCalls);
            _drawCalls.set(_sortPropertyTuple, new DrawCallList2U(new DrawCallList(), new DrawCallList() ));
        }
        var _drawCallList:DrawCallList2U = _drawCalls.get(_sortPropertyTuple);

        if (zSortedIndex == 1)
            _drawCallList.second.push(drawCall);
        else
            _drawCallList.first.push(drawCall);
    }

    private function removeDrawCallFromSortedBucket(drawCall:DrawCall) {
        for (sortPropertiesToDrawCalls in _drawCalls) {
            sortPropertiesToDrawCalls.first.remove(drawCall) ;
            sortPropertiesToDrawCalls.second.remove(drawCall) ;
        }
    }

    private function findDrawCall(predicate:DrawCall -> Bool):DrawCall {

        for (sortPropertiesToDrawCalls in _drawCalls) {
            var drawCalls = sortPropertiesToDrawCalls.first;

            for (drawCall in drawCalls) {
                if (predicate(drawCall)) {
                    return drawCall;
                }
            }
            drawCalls = sortPropertiesToDrawCalls.second;
            for (drawCall in drawCalls) {
                if (predicate(drawCall)) {
                    return drawCall;
                }
            }
        }

        return null;
    }

    inline function foreachDrawCall(func:DrawCall -> Void) {
        inline function _foreachDrawCall(drawCalls:Array<DrawCall>) {
            for (drawCall in drawCalls) {
                func(drawCall);
            }
        }
        for (sortPropertiesToDrawCalls in _drawCalls) {
            _foreachDrawCall(sortPropertiesToDrawCalls.first);
            _foreachDrawCall(sortPropertiesToDrawCalls.second);

        }
    }

    public function bindDrawCall(drawCall:DrawCall, pass:Pass, program:Program, forceRebind:Bool) {
        drawCall.bind(program);

        // bind attributes
        // FIXME: like for uniforms, watch and swap default values / binding value
        for (input in program.inputs.attributes) {
            drawCall.bindAttribute(input, pass.attributeBindings.bindings, pass.attributeBindings.defaultValues);
        }

        // bind states

        for (stateName in States.PROPERTY_NAMES) {
            stateBindingPropertyAddedHandler(stateName, drawCall, pass.stateBindings, forceRebind);
        }

        // bind uniforms
        for (input in program.inputs.uniforms) {
            uniformBindingPropertyAddedHandler(drawCall, input, pass.uniformBindings, forceRebind);
        }

        // bind index buffer
        if ( pass.isForward) {
            drawCall.bindIndexBuffer();
        }
    }

    private function unbindDrawCall(drawCall:DrawCall) {
        //todo remove


        if(_propChangedSlot.exists(drawCall)){
            var __propChangedSlot_keys:DrawCallSlotBindings=_propChangedSlot.get(drawCall);
            for (it in __propChangedSlot_keys.samplerStatesBinding) {
                removePropChangedSlot(__propChangedSlot_keys.samplerStatesBinding,it.first);
            }
            for (it in __propChangedSlot_keys.stateBinding) {
                removePropChangedSlot(__propChangedSlot_keys.stateBinding,it.first);
            }
            for (it in __propChangedSlot_keys.uniformBinding) {
                removePropChangedSlot(__propChangedSlot_keys.uniformBinding,it.first);
            }

            for (it in __propChangedSlot_keys.macroBinding) {
                removePropChangedSlot( __propChangedSlot_keys.macroBinding,it.first);
            }
            __propChangedSlot_keys.samplerStatesBinding=null;
            __propChangedSlot_keys.stateBinding=null;
            __propChangedSlot_keys.uniformBinding=null;
            __propChangedSlot_keys.macroBinding=null;
            __propChangedSlot_keys=null;
            _propChangedSlot.remove(drawCall);
            //_propChangedSlot->clear();
        }

        if(_sortUsefulPropertyChangedSlot.exists(drawCall)){
            var _sortUsefulPropertyChangedSlot_keys:Array<DrawCallSlot> = _sortUsefulPropertyChangedSlot.get(drawCall);
            for (it in _sortUsefulPropertyChangedSlot_keys) {
                 it.second.dispose();
                _sortUsefulPropertyChangedSlot_keys.remove(it);
            }

            _sortUsefulPropertyChangedSlot.remove(drawCall);
        }
        if(_zSortUsefulPropertyChangedSlot.exists(drawCall)){
            var _zSortUsefulPropertyChangedSlot_keys:Array<DrawCallSlot> = _zSortUsefulPropertyChangedSlot.get(drawCall);
            for (it in _zSortUsefulPropertyChangedSlot_keys) {
                it.second.dispose();
                _zSortUsefulPropertyChangedSlot_keys.remove(it);
            }
            _zSortUsefulPropertyChangedSlot.remove(drawCall);
        }

        _drawCallToPropRebindFuncs.remove(drawCall);
        //_drawCallToPropRebindFuncs->clear();
    }


    private function zSortDrawCalls() {
        for (sortPropertiesToDrawCalls in _drawCalls) {
            var drawCalls:Array<DrawCall> = sortPropertiesToDrawCalls.second ;
            drawCalls.sort(compareZSortedDrawCalls);
        }
    }
}
