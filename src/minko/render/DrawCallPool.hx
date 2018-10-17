package minko.render;
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
typedef DrawCallSlot = Tuple<DrawCall, SignalSlot3<Store, Provider, String>>;


class DrawCallPool {
    //_drawCalls macroBindingKey  DrawCallList
    public static function macroBindingKey(propertyName:String, m:MacroBinding, s:Store) {
        return propertyName + "+" + m.uuid + "_" + s.uuid;
    }

    public static function drawCallKey(m:Binding, s:DrawCall) {
        return m.uuid + "_" + s.uuid;
    }

    public static function sortPropertyTuple(m:Float, s:Int) {
        return m + "_" + s;
    }
    private var _batchId:Int;
    private var _drawCalls:StringMap<DrawCallList2U > ;
    private var _drawCallsKeys:Array<String> ;
    private var _macroToDrawCalls:StringMap<DrawCallList>;//macroBindingKey
    private var _invalidDrawCalls:ObjectMap< DrawCall, Tuple<Bool, EffectVariables>>;
    private var _drawCallsToBeSorted:Array<DrawCall>;
    private var _macroChangedSlot:StringMap<Tuple<SignalSlot3<Store, Provider, String>, Int>>;//macroBindingKey
    private var _propChangedSlot:StringMap<DrawCallSlot>;//drawCallKey
    private var _sortUsefulPropertyChangedSlot:StringMap<DrawCallSlot>;//drawCallKey
    private var _sortUsefulPropertyNames:Array<String>;
    private var _zSortUsefulPropertyChangedSlot:StringMap<DrawCallSlot>;//drawCallKey
    private var _zSortUsefulPropertyNames:Array<String>;
    private var _mustZSort:Bool;

    private var _drawCallToPropRebindFuncs:PropertyRebindFuncMap;

    public function new() {
        this._zSortUsefulPropertyNames = [];
        this._sortUsefulPropertyNames = [];
        this._batchId = 0;
        this._drawCalls = new StringMap<DrawCallList2U >();
        this._drawCallsKeys = [];
        this._macroToDrawCalls = new StringMap<DrawCallList>();
        this._invalidDrawCalls = new ObjectMap< DrawCall, Tuple<Bool, EffectVariables>>();
        this._macroChangedSlot = new StringMap<Tuple<SignalSlot3<Store, Provider, String>, Int>>();
        this._drawCallToPropRebindFuncs = new PropertyRebindFuncMap();
        this._drawCallsToBeSorted = new Array<DrawCall>();
        this._propChangedSlot = new StringMap<DrawCallSlot>();
        this._sortUsefulPropertyChangedSlot = new StringMap<DrawCallSlot>();
        this._zSortUsefulPropertyChangedSlot = new StringMap<DrawCallSlot>();
        this._mustZSort = false;
    }

    public function dispose() {
        if (_macroToDrawCalls != null) {
            _macroToDrawCalls = null;
        }
        if (_macroChangedSlot != null) {
            _macroChangedSlot = null;
        }
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
        this._macroToDrawCalls = new StringMap<DrawCallList>();
        this._invalidDrawCalls = new ObjectMap< DrawCall, Tuple<Bool, EffectVariables>>();
        this._macroChangedSlot = new StringMap<Tuple<SignalSlot3<Store, Provider, String>, Int>>();
        this._propChangedSlot = new StringMap<DrawCallSlot>();
        this._drawCallToPropRebindFuncs = new PropertyRebindFuncMap();
        this._sortUsefulPropertyChangedSlot = new StringMap<DrawCallSlot>();
        this._zSortUsefulPropertyChangedSlot = new StringMap<DrawCallSlot>();
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
        for (macroNameAndBinding in macroBindings.bindings.keys()) {
            var macroName = macroNameAndBinding;
            var macroBinding:MacroBinding = macroBindings.bindings.get(macroNameAndBinding);
            var store:Store = macroBinding.source == Source.ROOT ? rootData : (macroBinding.source == Source.RENDERER ? rendererData : targetData);
            var propertyName:String = Store.getActualPropertyName(drawCall.variables, macroBinding.propertyName);
            var _bindingKey = macroBindingKey(propertyName, macroBinding, store);

            if (!_macroToDrawCalls.exists(_bindingKey)) {
                _macroToDrawCalls.set(_bindingKey, new DrawCallList());
            }
            var drawCalls:DrawCallList = _macroToDrawCalls.get(_bindingKey);

//Debug.Assert(std::find(drawCalls.begin(), drawCalls.end(), drawCall) == drawCalls.end());

            drawCalls.push(drawCall);

            if (macroBindings.types.get(macroName) != MacroType.UNSET) {
                addMacroCallback(_bindingKey, store.getPropertyChanged(propertyName), function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                    macroPropertyChangedHandler(macroBinding, drawCalls);
                });
            }
            else {
                var hasProperty = store.hasProperty(propertyName);
                addMacroCallback(_bindingKey, hasProperty ? store.getPropertyRemoved(propertyName) : store.getPropertyAdded(propertyName), function(s, UnnamedParameter1, p) {
                    if (hasProperty) {
                        macroPropertyRemovedHandler(macroBinding, propertyName, s, drawCalls);
                    }
                    else {
                        macroPropertyAddedHandler(macroBinding, propertyName, s, drawCalls);
                    }
                });
            }
        }
    }

    private function unwatchProgramSignature(drawCall:DrawCall, macroBindings:MacroBindingMap, rootData:Store, rendererData:Store, targetData:Store) {
        for (macroNameAndBinding in macroBindings.bindings.keys()) {
            var macroBinding:MacroBinding = macroBindings.bindings.get(macroNameAndBinding);
            var store:Store = macroBinding.source == Source.ROOT ? rootData : ( macroBinding.source == Source.RENDERER ? rendererData : targetData);
            var propertyName = Store.getActualPropertyName(drawCall.variables, macroBinding.propertyName);
            var bindingKey = macroBindingKey(propertyName, macroBinding, store);
            if (_macroToDrawCalls.exists(bindingKey)) {
                var drawCalls = _macroToDrawCalls.get(bindingKey);

                drawCalls.remove(drawCall);

                if (drawCalls.length == 0) {
                    drawCalls = null;
                    _macroToDrawCalls.remove(bindingKey);
                }

            }

            removeMacroCallback(bindingKey);
        }
    }


    public function macroPropertyAddedHandler(macroBinding:MacroBinding, propertyName:String, store:Store, drawCalls:DrawCallList) {
        var key:String = macroBindingKey(propertyName, macroBinding, store);

        removeMacroCallback(key);
        addMacroCallback(key, store.getPropertyRemoved(propertyName),
        function(s:Store, UnnamedParameter1:Provider, p:String) {
            macroPropertyRemovedHandler(macroBinding, propertyName, s, drawCalls);
        });

        macroPropertyChangedHandler(macroBinding, drawCalls);
    }

    public function macroPropertyRemovedHandler(macroBinding:MacroBinding, propertyName:String, store:Store, drawCalls:DrawCallList) {
        // If the store still has the property, it means that it was not really removed
        // but that one of the copies of the properties was removed (ie same material added multiple
        // times to the same store). Thus the macro state should not be affected.
        if (store.hasProperty(propertyName)) {
            return;
        }

        var key:String = macroBindingKey(propertyName, macroBinding, store);

        removeMacroCallback(key);
        addMacroCallback(key, store.getPropertyAdded(propertyName),
        function(s:Store, UnnamedParameter1:Provider, p:String) {
            macroPropertyAddedHandler(macroBinding, propertyName, s, drawCalls);
        });

        macroPropertyChangedHandler(macroBinding, drawCalls);
    }

    public function macroPropertyChangedHandler(macroBinding:MacroBinding, drawCalls:DrawCallList) {

        for (drawCall in drawCalls) {
            _invalidDrawCalls.set(drawCall, new Tuple<Bool, EffectVariables>(false, new EffectVariables()));
        }
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

        if (program == drawCall.program ) {
            if (variablesChanged) {
                drawCall.variables = variables ;
            }

            return;
        }

        if (drawCall.program != null) {
            unwatchProgramSignature(drawCall, drawCall.pass.macroBindings, drawCall.rootData, drawCall.rendererData, drawCall.targetData);
            unbindDrawCall(drawCall);
        }

        if (variablesChanged) {
            drawCall.variables = variables ;
        }

        bindDrawCall(drawCall, pass, program, forceRebind);

        if (programAndSignature.second != null) {
            watchProgramSignature(drawCall, drawCall.pass.macroBindings, drawCall.rootData, drawCall.rendererData, drawCall.targetData);
        }
    }


    public function addMacroCallback(key:String, signal:Signal3<Store, Provider, String>, callback:Store -> Provider -> String -> Void) {
        _macroChangedSlot.set(key, new Tuple<SignalSlot3<Store, Provider, String>, Int>(signal.connect(callback), 1));

    }

    public function removeMacroCallback(key:String) {
        if (!_macroChangedSlot.exists(key)) {
            return;
        }

//Debug.Assert((*_macroChangedSlot)[key].second != 0);

        _macroChangedSlot.get(key).second--;
        if (_macroChangedSlot.get(key).second == 0) {
            var signalSlot3:SignalSlot3<Store, Provider, String> = _macroChangedSlot.get(key).first;
            signalSlot3.disconnect();
            _macroChangedSlot.remove(key);
        }
    }

    public function hasMacroCallback(key:String) {
        return _macroChangedSlot.exists(key) ;
    }

    private function uniformBindingPropertyAddedHandler(drawCall:DrawCall, input:UniformInput, uniformBindingMap:BindingMapBase<Binding>, forceRebind = false) {
        if (!forceRebind && _invalidDrawCalls.exists(drawCall)) {
            return;
        }

        var resolvedBinding:ResolvedBinding = drawCall.bindUniform(input, uniformBindingMap.bindings, uniformBindingMap.defaultValues);


        if (resolvedBinding != null) {
            var propertyName = resolvedBinding.propertyName;
            var bindingPtr = resolvedBinding.binding;
            var propertyExist = resolvedBinding.store.hasProperty(propertyName);
            var signal:Signal3<Store, Provider, String> = resolvedBinding.store.getPropertyChanged(propertyName);
            //propertyExist ? resolvedBinding.store.getPropertyRemoved(propertyName) : resolvedBinding.store.getPropertyAdded(propertyName);
            var _drawCallKey = drawCallKey(bindingPtr, drawCall);

            if (_propChangedSlot.exists(_drawCallKey)) {
                _propChangedSlot.get(_drawCallKey).second.disconnect();
            }

            var changedSlot = signal.connect(function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                _propChangedSlot.remove(_drawCallKey);
                if (_drawCallToPropRebindFuncs.exists(drawCall) == false) {
                    _drawCallToPropRebindFuncs.set(drawCall, []);
                }
                _drawCallToPropRebindFuncs.get(drawCall).push(function() {
                    uniformBindingPropertyAddedHandler(drawCall, input, uniformBindingMap, forceRebind);
                });
            }, 0, true);
            _propChangedSlot.set(_drawCallKey, new DrawCallSlot(drawCall, changedSlot));


            // If this draw call needs to be sorted
            // => we listen to the useful properties
            if (propertyExist && drawCall.zSorted) {

                var propertyRelatedToZSortIt = Lambda.find(_zSortUsefulPropertyNames, function(zSortUsefulPropertyName) {
                    return Store.getActualPropertyName(drawCall.variables, zSortUsefulPropertyName) == propertyName;
                });

                if (propertyRelatedToZSortIt != null) {

                    if (_zSortUsefulPropertyChangedSlot.exists(_drawCallKey)) {
                        _zSortUsefulPropertyChangedSlot.get(_drawCallKey).second.disconnect();
                    }
                    _zSortUsefulPropertyChangedSlot.set(_drawCallKey,
                    new DrawCallSlot(drawCall, resolvedBinding.store.getPropertyChanged(propertyName).connect(
                        function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                            _mustZSort = true;
                        })));
                }
            }

            resolvedBinding = null;
        }

        if (input.type == InputType.sampler2d || input.type == InputType.samplerCube) {
            samplerStatesBindingPropertyAddedHandler(drawCall, input, uniformBindingMap);
        }
    }

    private function stateBindingPropertyAddedHandler(stateName:String, drawCall:DrawCall, stateBindingMap:BindingMapBase<Binding>, forceRebind:Bool) {
        if (!forceRebind && _invalidDrawCalls.exists(drawCall)) {
            return;
        }

        var resolvedBinding:ResolvedBinding = drawCall.bindState(stateName, stateBindingMap.bindings, stateBindingMap.defaultValues);

        if (resolvedBinding != null) {
            var bindingPtr = resolvedBinding.binding;
            var propertyName = resolvedBinding.propertyName;
            var propertyExist = resolvedBinding.store.hasProperty(propertyName);
            var signal:Signal3<Store, Provider, String> = resolvedBinding.store.getPropertyChanged(propertyName);
            //  propertyExist ? resolvedBinding.store.getPropertyRemoved(propertyName) : resolvedBinding.store.getPropertyAdded(propertyName);
            var _drawCallKey = drawCallKey(resolvedBinding.binding, drawCall);
            if (_propChangedSlot.exists(_drawCallKey)) {
                _propChangedSlot.get(_drawCallKey).second.disconnect();
            }
            var changedSlot = signal.connect(
                function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                    _propChangedSlot.remove(_drawCallKey);
                    if (_drawCallToPropRebindFuncs.exists(drawCall) == false) {
                        _drawCallToPropRebindFuncs.set(drawCall, []);
                    }
                    _drawCallToPropRebindFuncs.get(drawCall).push(function() {
                        stateBindingPropertyAddedHandler(stateName, drawCall, stateBindingMap, forceRebind);
                    });
                }, 0, true);
            _propChangedSlot.set(_drawCallKey, new DrawCallSlot(drawCall, changedSlot ));
            var propertyRelatedToSortIt = Lambda.find(_sortUsefulPropertyNames, function(sortUsefulPropertyName) {
                return Store.getActualPropertyName(drawCall.variables, sortUsefulPropertyName) == propertyName;
            });

            if (propertyRelatedToSortIt != null) {
                if (_sortUsefulPropertyChangedSlot.exists(_drawCallKey)) {
                    _sortUsefulPropertyChangedSlot.get(_drawCallKey).second.disconnect();
                }
                _sortUsefulPropertyChangedSlot.set(_drawCallKey, new DrawCallSlot(drawCall, resolvedBinding.store.getPropertyChanged(propertyName).connect(
                    function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                        _drawCallsToBeSorted.push(drawCall);
                    })));
            }

            resolvedBinding = null;
        }
    }

    private function samplerStatesBindingPropertyAddedHandler(drawCall:DrawCall, input:UniformInput, uniformBindingMap:BindingMapBase<Binding>) {
        var resolvedBindings:Array<ResolvedBinding> = drawCall.bindSamplerStates(input, uniformBindingMap.bindings, uniformBindingMap.defaultValues);

        for (resolvedBinding in resolvedBindings) {
            if (resolvedBinding != null) {
                var propertyName = resolvedBinding.propertyName;
                var propertyExist = resolvedBinding.store.hasProperty(propertyName);
                var signal:Signal3<Store, Provider, String> = resolvedBinding.store.getPropertyChanged(propertyName);
                //propertyExist ? resolvedBinding.store.getPropertyRemoved(propertyName) : resolvedBinding.store.getPropertyAdded(propertyName);

                var _drawCallKey = drawCallKey(resolvedBinding.binding, drawCall);
                if (_propChangedSlot.exists(_drawCallKey)) {
                    _propChangedSlot.get(_drawCallKey).second.disconnect();
                }
                var changedSlot = signal.connect(
                    function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                        _propChangedSlot.remove(_drawCallKey);
                        if (_drawCallToPropRebindFuncs.exists(drawCall) == false) {
                            _drawCallToPropRebindFuncs.set(drawCall, []);
                        }
                        _drawCallToPropRebindFuncs.get(drawCall).push(function() {
                            samplerStatesBindingPropertyAddedHandler(drawCall, input, uniformBindingMap);
                        });
                    }, 0, true);
                _propChangedSlot.set(_drawCallKey, new DrawCallSlot(drawCall, changedSlot ));

                resolvedBinding = null;
            }
        }
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

    private function foreachDrawCall(func:DrawCall -> Void) {
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
        if (!!pass.isForward) {
            drawCall.bindIndexBuffer();
        }
    }

    private function unbindDrawCall(drawCall:DrawCall) {
        //todo remove

        inline function filter(keys:Iterator<String>, cond:String -> Bool) {
            var tmp:Array<String> = [];
            while (keys.hasNext()) {
                var value = keys.next();
                if (cond(value)) {
                    tmp.push(value);
                }
            }
            return tmp;
        }
        var __propChangedSlot_keys:Array<String> = filter(_propChangedSlot.keys(), function(k:String) {
            return _propChangedSlot.get(k).first == drawCall;
        });
        for (it in __propChangedSlot_keys) {
            _propChangedSlot.get(it).second.disconnect();
            _propChangedSlot.remove(it);
        }
        //_propChangedSlot->clear();


        var _sortUsefulPropertyChangedSlot_keys:Array<String> = filter(_sortUsefulPropertyChangedSlot.keys(), function(k:String) {
            return _sortUsefulPropertyChangedSlot.get(k).first == drawCall;
        });
        for (it in _sortUsefulPropertyChangedSlot_keys) {
            _sortUsefulPropertyChangedSlot.get(it).second.disconnect();
            _sortUsefulPropertyChangedSlot.remove(it);
        }
        var _zSortUsefulPropertyChangedSlot_keys:Array<String> = filter(_zSortUsefulPropertyChangedSlot.keys(), function(k:String) {
            return _zSortUsefulPropertyChangedSlot.get(k).first == drawCall;
        });
        for (it in _zSortUsefulPropertyChangedSlot_keys) {
            _zSortUsefulPropertyChangedSlot.get(it).second.disconnect();
            _zSortUsefulPropertyChangedSlot.remove(it);
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
