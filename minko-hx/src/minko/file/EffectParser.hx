package minko.file;
import minko.data.BindingMap;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import minko.data.Binding;
import minko.data.BindingMap.BindingMapBase;
import minko.data.BindingMap.MacroBinding;
import minko.data.BindingMap.MacroBindingMap;
import minko.data.BindingMap.MacroType;
import minko.data.Provider;
import minko.data.Store;
import minko.render.AbstractTexture;
import minko.render.Blending.Destination;
import minko.render.Blending.Mode;
import minko.render.CompareMode;
import minko.render.CubeTexture;
import minko.render.Effect;
import minko.render.Pass;
import minko.render.Priority;
import minko.render.Program;
import minko.render.SamplerStates;
import minko.render.Shader;
import minko.render.States;
import minko.render.StencilOperation;
import minko.render.Texture;
import minko.render.TriangleCulling;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;

import minko.render.Blending.Source as BlendingSource;
//todo Std and cast


class GLSLBlock {
    public var type:GLSLBlockType;
    public var value:String;
    public function new (t ,v ):Void {
        type=t;
        value=v;
    }
}

typedef ShaderToGLSLBlocks = ObjectMap<Shader, GLSLBlockTree>;
typedef Technique = Array<Pass> ;
typedef Techniques = StringMap<Technique>;
typedef Passes = Array<Pass> ;

@:expose("minko.file.GLSLBlockType")
@:enum abstract GLSLBlockType(Int) from Int to Int{
    var TEXT = 0;
    var FILE = 1;
}
@:expose("minko.file.GLSLBlockTree")
class GLSLBlockTree {
    public var node:GLSLBlock;
    public var leaf:Array<GLSLBlockTree>;

    public function new(n) {
        leaf = [];
        node = n;
    }
}
@:expose("minko.file.Block")
class Block <T> {
    public var bindingMap:T;

    public function new() {

    }

    public function dispose() {
    }
}
@:expose("minko.file.AttributeBlock")
class AttributeBlock extends Block< BindingMap> {
    public function new() {
        super();
        bindingMap = new BindingMap();
    }

    public function copyFrom(s:AttributeBlock) {
        BindingMapBase.copyFrom(bindingMap, s.bindingMap);
        return this;
    }
}
@:expose("minko.file.MacroBlock")
class MacroBlock extends Block< MacroBindingMap> {
    public function new() {
        super();
        bindingMap = new MacroBindingMap();
    }

    public function copyFrom(s:MacroBlock) {
        MacroBindingMap.copyFrom2(bindingMap, s.bindingMap);
        return this;
    }
}
@:expose("minko.file.UniformBlock")
class UniformBlock extends Block< BindingMap> {
    public function new() {
        super();
        bindingMap = new BindingMap();
    }

    public function copyFrom(s:UniformBlock) {
        BindingMapBase.copyFrom(bindingMap, s.bindingMap);
        return this;
    }
}
@:expose("minko.file.StateBlock")
class StateBlock extends Block< BindingMap> {
    public var states:States;

    public function new() {
        super();
        bindingMap = new BindingMap();
        states = new States();
        // we set the priority to a special value in order to know
        // wether it was actually read from the file or not
        states.priority = (States.UNSET_PRIORITY_VALUE);
        bindingMap.defaultValues.addProvider(states.data);
    }

    public function copyFrom(s:StateBlock) {
        BindingMapBase.copyFrom(bindingMap, s.bindingMap);
        this.states = new States().copyFrom(s.states);
        //trace("this.states = new States().copyFrom(s.states);");
        //trace(this.states);
        // data::Store copy constructor makes a shallow copy, to avoid ending up with
        // data::Provider shared by multiple blocks/scopes, we have to simulate a deep copy
        // by emptying the data::Store and then add the actual data::Provider of the new
        // render::States object

        bindingMap.defaultValues.removeProvider(bindingMap.defaultValues.providers[0]);
        bindingMap.defaultValues.addProvider(states.data);
        return this;
    }
}

@:expose("minko.file.Scope")
class Scope {
    public var parent:Scope;
    public var children:Array<Scope>;
    public var attributeBlock:AttributeBlock;
    public var uniformBlock:UniformBlock;
    public var stateBlock:StateBlock;
    public var macroBlock:MacroBlock;
    public var defaultTechnique:String;
    public var passes:Passes;
    public var techniques:Techniques;

    public function new() {
        this.parent = null;
        this.children = new Array<Scope>();
        this.attributeBlock = new AttributeBlock();
        this.uniformBlock = new UniformBlock();
        this.stateBlock = new StateBlock();
        this.macroBlock = new MacroBlock();
        this.defaultTechnique = "";
        this.passes = new Passes();
        this.techniques = new Techniques();
    }

    public function copyFrom(scope:Scope) {
        this.parent = scope.parent;
        this.children = [];
        this.attributeBlock.copyFrom(scope.attributeBlock);

        this.uniformBlock.copyFrom(scope.uniformBlock);
        this.stateBlock = new StateBlock().copyFrom(scope.stateBlock);
        this.macroBlock.copyFrom(scope.macroBlock);
        this.defaultTechnique = scope.defaultTechnique;
        this.passes = scope.passes.concat([]);
        this.techniques = scope.techniques;
        return this;
    }

    public function copyFromParent(scope:Scope, parent:Scope) :Scope{
        copyFrom(scope);
        this.parent = parent;
        parent.children.push(this);
        return this;
    }
}
@:expose("minko.file.EffectParser")
class EffectParser extends AbstractParser {

    public static inline var EXTRA_PROPERTY_BLENDING_MODE = "blendingMode";
    public static inline var EXTRA_PROPERTY_STENCIL_TEST = "stencilTest";
    public static inline var EXTRA_PROPERTY_STENCIL_OPS = "stencilOps";
    public static inline var EXTRA_PROPERTY_STENCIL_FAIL_OP = "fail";
    public static inline var EXTRA_PROPERTY_STENCIL_Z_FAIL_OP = "zfail";
    public static inline var EXTRA_PROPERTY_STENCIL_Z_PASS_OP = "zpass";

    private static var _blendingSourceMap:StringMap<Int> = initialize_blendingSourceMap();
    private static var _blendingDestinationMap:StringMap<Int> = initialize_blendingDestinationMap();
    private static var _blendingModeMap:StringMap<Int> = initialize_blendingModeMap();
    private static var _compareFuncMap:StringMap<CompareMode> = initialize_compareFuncMap();
    private static var _triangleCullingMap:StringMap<TriangleCulling> = initialize_triangleCullingMap();
    private static var _stencilOpMap:StringMap<StencilOperation> = initialize_stencilOpMap();
    private static var _priorityMap:StringMap<Float> = initialize_priorityMap();

    static function initialize_blendingSourceMap() {
        var tmp = new StringMap<Int>();
        tmp.set("zero", BlendingSource.ZERO);
        tmp.set("one", BlendingSource.ONE);
        tmp.set("color", BlendingSource.SRC_COLOR);
        tmp.set("one_minus_src_color", BlendingSource.ONE_MINUS_SRC_COLOR);
        tmp.set("src_alpha", BlendingSource.SRC_ALPHA);
        tmp.set("one_minus_src_alpha", BlendingSource.ONE_MINUS_SRC_ALPHA);
        tmp.set("dst_alpha", BlendingSource.DST_ALPHA);
        tmp.set("one_minus_dst_alpha", BlendingSource.ONE_MINUS_DST_ALPHA);
        return tmp;
    }

    static function initialize_blendingDestinationMap() {
        var tmp = new StringMap<Int>();
        tmp.set("zero", Destination.ZERO) ;
        tmp.set("one", Destination.ONE) ;
        tmp.set("dst_color", Destination.DST_COLOR) ;
        tmp.set("one_minus_dst_color", Destination.ONE_MINUS_DST_COLOR) ;
        tmp.set("src_alpha_saturate", Destination.SRC_ALPHA_SATURATE) ;
        tmp.set("one_minus_src_alpha", Destination.ONE_MINUS_SRC_ALPHA) ;
        tmp.set("dst_alpha", Destination.DST_ALPHA) ;
        tmp.set("one_minus_dst_alpha", Destination.ONE_MINUS_DST_ALPHA) ;
        return tmp;
    }

    static function initialize_blendingModeMap() {
        var tmp = new StringMap<Int>();
        tmp.set("default", Mode.DEFAULT) ;
        tmp.set("alpha", Mode.ALPHA) ;
        tmp.set("additive", Mode.ADDITIVE) ;
        return tmp;
    }

    static function initialize_compareFuncMap() {
        var tmp = new StringMap<CompareMode>();
        tmp.set("always", CompareMode.ALWAYS);
        tmp.set("equal", CompareMode.EQUAL);
        tmp.set("greater", CompareMode.GREATER);
        tmp.set("greater_equal", CompareMode.GREATER_EQUAL) ;
        tmp.set("less", CompareMode.LESS) ;
        tmp.set("less_equal", CompareMode.LESS_EQUAL);
        tmp.set("never", CompareMode.NEVER);
        tmp.set("not_equal", CompareMode.NOT_EQUAL);
        return tmp;
    }

    static function initialize_triangleCullingMap() {
        var tmp = new StringMap<TriangleCulling>();
        tmp.set("none", TriangleCulling.NONE);
        tmp.set("front", TriangleCulling.FRONT);
        tmp.set("back", TriangleCulling.BACK);
        tmp.set("both", TriangleCulling.BOTH);
        return tmp;
    }

    static function initialize_stencilOpMap() {
        var tmp = new StringMap<StencilOperation>();
        tmp.set("keep", StencilOperation.KEEP);
        tmp.set("zero", StencilOperation.ZERO);
        tmp.set("replace", StencilOperation.REPLACE);
        tmp.set("incr", StencilOperation.INCR);
        tmp.set("incr_wrap", StencilOperation.INCR_WRAP);
        tmp.set("decr", StencilOperation.DECR);
        tmp.set("decr_wrap", StencilOperation.DECR_WRAP);
        tmp.set("invert", StencilOperation.INVERT);
        return tmp;
    }

    static function initialize_priorityMap() {
        var tmp = new StringMap<Float>();
        tmp.set("first", Priority.FIRST);
        tmp.set("background", Priority.BACKGROUND);
        tmp.set("opaque", Priority.OPAQUE);
        tmp.set("transparent", Priority.TRANSPARENT);
        tmp.set("last", Priority.LAST);
        return tmp;
    }


    static private var _extraStateNames:Array<String> = [
        EffectParser.EXTRA_PROPERTY_BLENDING_MODE,
        EffectParser.EXTRA_PROPERTY_STENCIL_TEST
    ];

    private var _filename:String;
    private var _resolvedFilename:String;
    private var _options:Options;
    private var _effect:Effect;
    private var _effectName:String;
    private var _assetLibrary:AssetLibrary;

    private var _globalScope:Scope;
    private var _shaderToGLSL:ObjectMap<Shader, GLSLBlockTree>;
    private var _numDependencies:Int;
    private var _numLoadedDependencies:Int;
    private var _effectData:Provider;

    private var _loaderCompleteSlots:ObjectMap<Loader, SignalSlot<Loader>>;
    private var _loaderErrorSlots:ObjectMap<Loader, SignalSlot2<Loader, String>>;

    public function new() {
        super();
        this._effect = null;
        this._numDependencies = 0;
        this._numLoadedDependencies = 0;
        this._effectData = Provider.create();


        _filename = "";
        _resolvedFilename = "";
        _options = null;
        _effectName = "";
        _assetLibrary = null;

        _globalScope = new Scope();
        _shaderToGLSL = new ObjectMap<Shader, GLSLBlockTree>();

        _loaderCompleteSlots = new ObjectMap<Loader, SignalSlot<Loader>>();
        _loaderErrorSlots = new ObjectMap<Loader, SignalSlot2<Loader, String>>();
    }

    public static function create() {
        return new EffectParser();
    }
    public var effect(get, null):Effect;

    function get_effect() {
        return _effect;
    }

    public var effectName(get, null):String;

    function get_effectName() {
        return _effectName;
    }

    function isDynamic(o) {
        return !Std.is(o, Array)
        && !Std.is(o, Int)
        && !Std.is(o, Float)
        && !Std.is(o, String)
        && !Std.is(o, Bool)
        && o != null;
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        var root = {};

        // Add a line ending to avoid JSON parsing error
        var tempData = data.getString(0, data.length);
        try {

            root = haxe.format.JsonParser.parse(tempData);
        } catch (e:String) {
            _error.execute(this, (resolvedFilename + ": " + e));
        }

        _options = options.clone();
        //_options.loadAsynchronously = (false);

        var pos = resolvedFilename.lastIndexOf("/");
        if (pos == -1) {
            pos = resolvedFilename.lastIndexOf("\\");
        }
        if (pos != -1) {
            _options = _options.clone();
            _options.includePaths = [];
            _options.includePaths.push(resolvedFilename.substr(0, pos));
        }

        _filename = filename;
        _resolvedFilename = resolvedFilename;
        _assetLibrary = assetLibrary;
        if (Reflect.hasField(root, "name")) {
            _effectName = Reflect.field(root, "name") ;
        }
        else {
            _effectName = filename;
        }

        parseGlobalScope(root, _globalScope);

        _effect = Effect.create(_effectName);
        checkLoadedAndfinalize();
    }


    private function getPriorityValue(name) {
        var foundPriorityIt = _priorityMap.exists(name);
        return foundPriorityIt ? _priorityMap.get(name) : _priorityMap.get("opaque");
    }

    private function parseGlobalScope(node:Dynamic, scope:Scope) {
        parseAttributes(node, scope, scope.attributeBlock);
        parseUniforms(node, scope, scope.uniformBlock);
        parseMacros(node, scope, scope.macroBlock);
        parseStates(node, scope, scope.stateBlock);
        parsePasses(node, scope, scope.passes);
        parseTechniques(node, scope, scope.techniques);
    }

    private function parseConfiguration(node:Dynamic) {
        var confValue = Reflect.field(node, "configuration");
        var platforms = _options.platforms;
        var userFlags = _options.userFlags;
        var r = false;

        if (Std.is(confValue, Array)) {
            var tmps:Array<Dynamic> = cast confValue;
            for (value in tmps) {

                // if the config. token is a string and we can find it in the list of platforms,
                // then the configuration is ok and we return true
                if (Std.is(value, String) && Lambda.has(platforms, value) || Lambda.has(userFlags, value)) {
                    return true;
                }
                else if (Std.is(value, Array)) {
                    // if the config. token is an array, we check that *all* the string tokens are in
                    // the platforms list; if a single of them is not there then the config. token
                    // is considered to be false
                    var tmp:Array<Dynamic> = cast value;
                    for (str in tmp) {
                        if (Std.is(str, String) && Lambda.has(platforms, str) || Lambda.has(userFlags, str)) {
                            r = r || false;
                            break;
                        }
                    }
                }
            }
        }
        else {
            return true;
        }

        return r;
    }

    private function fixMissingPassPriorities(passes:Array<Pass>) {
        //todo ?
        var numPasses = passes.length;
        var passOne = passes[0];
        if (numPasses == 1) {

            //todo
            // passOne.states.data=Provider.createbyProvider(passOne.stateBindings.defaultValues.providers[0]);
            if (passOne.states.priority == States.UNSET_PRIORITY_VALUE) {
                passOne.states.priority = (States.DEFAULT_PRIORITY);
            }
        }
        else {
            for (i in 0... numPasses) {
                var pass = passes[i];

                if (pass.states.priority == States.UNSET_PRIORITY_VALUE) {
                    var nextPassWithPriority = i + 1;
                    while (nextPassWithPriority < numPasses && passes[nextPassWithPriority].states.priority == States.UNSET_PRIORITY_VALUE) {
                        ++nextPassWithPriority;
                    }
                    //todo
                    // pass.states.data=Provider.createbyProvider(pass.stateBindings.defaultValues.providers[0]);
                    if (nextPassWithPriority >= numPasses) {
                        pass.states.priority = (States.DEFAULT_PRIORITY + (numPasses - i - 1));
                    }
                    else {
                        pass.states.priority = ((nextPassWithPriority - i) + passes[nextPassWithPriority].states.priority);
                    }
                }
            }
        }
    }

    public function parseTechniques(node:Any, scope:Scope, techniques:Techniques) {
        var techniquesNode = Reflect.field(node, "techniques");

        if (Std.is(techniquesNode, Array)) {
            var tmp:Array<Dynamic> = cast techniquesNode;
            for (techniqueNode in tmp) {
                // FIXME: switch to fallback instead of ignoring
                if (!parseConfiguration(techniqueNode)) {
                    continue;
                }


                var techniqueName:String = "";
                if(Reflect.hasField(techniqueNode, "name")){
                    var techniqueNameNode =Reflect.field(techniqueNode, "name");
                    if (Std.is(techniqueNameNode, String)) {
                        techniqueName = cast(techniqueNameNode, String);
                    } else if (Std.is(techniqueNameNode, Array)) {
                        var tmp:Array<Any> = cast techniqueNameNode;
                        if (tmp.length == 1) {
                            techniqueName = "default";
                        } else {
                            techniqueName = _effectName + "-technique-" + Lambda.count(techniques);
                        }
                    }
                }
                else {
                    techniqueName = "default";
                }


                var techniqueScope:Scope = new Scope().copyFromParent(scope, scope);

                if (!techniques.exists(techniqueName)) {
                    techniques.set(techniqueName, []);
                }
                var passes=techniques.get(techniqueName);
                parseAttributes(techniqueNode, techniqueScope, techniqueScope.attributeBlock);
                parseUniforms(techniqueNode, techniqueScope, techniqueScope.uniformBlock);
                parseMacros(techniqueNode, techniqueScope, techniqueScope.macroBlock);
                parseStates(techniqueNode, techniqueScope, techniqueScope.stateBlock);
                parsePasses(techniqueNode, techniqueScope, passes);

                fixMissingPassPriorities(techniques.get(techniqueName));
            }
        }
        // FIXME: throw otherwise
    }

    private function getPassToExtend(extendNode:Dynamic, callBack:Pass -> Void) {
        var pass:Pass = null;
        var passName:String;

        if (Std.is(extendNode, String)) {
            passName = extendNode ;

            var passIt = Lambda.find(_globalScope.passes, function(p:Pass) {
                return p.name == passName;
            });

            if (passIt != null) {
                pass = passIt;
            }
        }
        else if (isDynamic(extendNode)) {
            passName = Reflect.field(extendNode, "pass");

            var techniqueName = Reflect.field(extendNode, "technique");
            var effectFilename = Reflect.field(extendNode, "effect");

            if (techniqueName == "") {
                techniqueName = "default";
            }

            if (_assetLibrary.effect(effectFilename) == null) {
                var options:Options = _options.clone();
                var loader:Loader = Loader.createbyLoader(_assetLibrary.loader);

               // options.loadAsynchronously = (false);
                loader.setQueue(effectFilename, options);
                _numDependencies++;
                var effectComplete = loader.complete.connect(function(l:Loader) {
                    pass = findPassFromEffectFilename(effectFilename, techniqueName, passName);
                    callBack(pass);
                    _numLoadedDependencies++;
                    checkLoadedAndfinalize();
                });
                loader.load();
                trace("effectFilename",effectFilename);
                return;
            }
            else {
                pass = findPassFromEffectFilename(effectFilename, techniqueName, passName);
            }
        }
        else {
            throw "";
        }

        if (pass == null) {
            throw ("Undefined base pass with name '" + passName + "'.");
        }

        callBack(pass);
    }

    private function findPassFromEffectFilename(effectFilename, techniqueName, passName) {
        var effect:Effect = _assetLibrary.effect(effectFilename);

        if (effect == null) {
            return null;
        }

        for (techniqueNameAndPasses in effect.techniques.keys()) {
            if (techniqueNameAndPasses == techniqueName) {
                for (p in effect.techniques.get(techniqueNameAndPasses)) {
                    if (p.name == passName) {
                        return p;
                    }
                }
            }
        }

        return null;
    }

    private function parsePassDynamic(node:Dynamic, scope:Scope, passes:Array<Pass>, ?pass:Pass = null) {
        // If the pass is an actual pass object, we parse all its data, create the corresponding
        // Pass object and add it to the vector.

        var passScope:Scope = new Scope().copyFromParent(scope, scope);

        var vertexShader:Shader = null;
        var fragmentShader:Shader = null;
        var passName = _effectName + "-pass" + scope.passes.length;
        var nameNode = Reflect.field(node, "name");
        var isForward = true;

        if (Reflect.hasField(node, "extends") && pass != null) {
            var extendNode = Reflect.field(node, "extends");

            inline function merge(a:StringMap<Dynamic>, b:StringMap<Dynamic>) {
                for (k in b.keys()) {
                    if (!a.exists(k))
                        a.set(k, b.get(k));
                }
            };
            // If a pass "extends" another pass, then we have to merge its properties with the already existing ones
            merge(passScope.attributeBlock.bindingMap.bindings, pass.attributeBindings.bindings);
            merge(passScope.uniformBlock.bindingMap.bindings, pass.uniformBindings.bindings);
            merge(passScope.macroBlock.bindingMap.bindings, pass.macroBindings.bindings);
            merge(passScope.macroBlock.bindingMap.types, pass.macroBindings.types);
            merge(passScope.stateBlock.bindingMap.bindings, pass.stateBindings.bindings);


            if (pass.attributeBindings.defaultValues.providers.length > 0) {
                if (passScope.attributeBlock.bindingMap.defaultValues.providers.length == 0) {
                    passScope.attributeBlock.bindingMap.defaultValues = new Store().copyFrom(pass.attributeBindings.defaultValues, true);
                } else {
                    var tmp = [for (provider in pass.attributeBindings.defaultValues.providers) new Provider().copyFrom(provider)];
                    passScope.attributeBlock.bindingMap.defaultValues.providers = (tmp);
                }

            }

            if (pass.uniformBindings.defaultValues.providers.length > 0) {
                if (passScope.uniformBlock.bindingMap.defaultValues.providers.length == 0) {
                    passScope.uniformBlock.bindingMap.defaultValues = new Store().copyFrom(pass.uniformBindings.defaultValues, true);
                } else {
                    var tmp = [for (provider in pass.uniformBindings.defaultValues.providers) new Provider().copyFrom(provider)];
                    passScope.uniformBlock.bindingMap.defaultValues.providers = (tmp);
                }
            }

            if (pass.macroBindings.defaultValues.providers.length > 0) {
                if (passScope.macroBlock.bindingMap.defaultValues.providers.length == 0) {
                    passScope.macroBlock.bindingMap.defaultValues = new Store().copyFrom(pass.macroBindings.defaultValues, true);
                } else {
                    var tmp = [ for (provider in pass.macroBindings.defaultValues.providers) new Provider().copyFrom(provider)];
                    passScope.macroBlock.bindingMap.defaultValues.providers = (tmp);
                }
            }
            passScope.stateBlock.states.data = Provider.createbyProvider(pass.stateBindings.defaultValues.providers[0]);
            passScope.stateBlock.bindingMap.defaultValues.removeProvider(passScope.stateBlock.bindingMap.defaultValues.providers[0]);
            passScope.stateBlock.bindingMap.defaultValues.addProvider(passScope.stateBlock.states.data);

            vertexShader = pass.program.vertexShader;
            fragmentShader = pass.program.fragmentShader;
            isForward = pass.isForward;
            passName = pass.name;
        }

        if (Std.is(nameNode, String)) {
            passName = nameNode;
        }
        // FIXME: throw otherwise

        parseAttributes(node, passScope, passScope.attributeBlock);
        parseUniforms(node, passScope, passScope.uniformBlock);
        parseMacros(node, passScope, passScope.macroBlock);
        parseStates(node, passScope, passScope.stateBlock);

        if (Reflect.hasField(node, "vertexShader")) {
            vertexShader = parseShader(Reflect.field(node, "vertexShader"), passScope, ShaderType.VERTEX_SHADER);
        }
        else if (vertexShader == null) {
            throw ("Missing vertex shader for pass \"" + passName + "\"");
        }

        if (Reflect.hasField(node, "fragmentShader")) {
            fragmentShader = parseShader(Reflect.field(node, "fragmentShader"), passScope, ShaderType.FRAGMENT_SHADER);
        }
        else if (fragmentShader == null) {
            throw ("Missing fragment shader for pass \"" + passName + "\"");
        }

        if (Reflect.hasField(node, "forward")) {
            isForward = Reflect.field(node, "forward");
        }

        if (!isForward) {
            checkDeferredPassBindings(passScope);
        }

        //todo;

        passes.push(Pass.create(passName, isForward, Program.createbyShader(passName, _options.context, vertexShader, fragmentShader), passScope.attributeBlock.bindingMap, passScope.uniformBlock.bindingMap, passScope.stateBlock.bindingMap, passScope.macroBlock.bindingMap));

    }

    private function parsePassString(node:Dynamic, scope:Scope, passes:Array<Pass>, pass:Pass) {
        passes.push(Pass.createbyPass(pass, true));
    }

    private function parsePass(node:Dynamic, scope:Scope, passes:Array<Pass>) {
        if (Std.is(node, String)) {
            getPassToExtend(node, function(pass:Pass) {
                parsePassString(node, scope, passes, pass);
            });
        }
        else if (isDynamic(node)) {
            if (Reflect.hasField(node, "extends")) {
                var extendNode = Reflect.field(node, "extends");
                getPassToExtend(extendNode, function(pass:Pass) {
                    parsePassDynamic(node, scope, passes, pass);
                });
            } else {
                parsePassDynamic(node, scope, passes, null);
            }
        }
    }

    private function checkDeferredPassBindings(passScope:Scope) {
        for (bindingNameAndValue in passScope.attributeBlock.bindingMap.bindings) {
            if (bindingNameAndValue.source == Source.TARGET) {
                throw "";
            }
        }

        for (bindingNameAndValue in passScope.uniformBlock.bindingMap.bindings) {
            if (bindingNameAndValue.source == Source.TARGET) {
                throw "";
            }
        }

        for (bindingNameAndValue in passScope.stateBlock.bindingMap.bindings) {
            if (bindingNameAndValue.source == Source.TARGET) {
                throw "";
            }
        }

        for (bindingNameAndValue in passScope.macroBlock.bindingMap.bindings) {
            if (bindingNameAndValue.source == Source.TARGET) {
                throw "";
            }
        }
    }

    private function parsePasses(node:Dynamic, scope:Scope, passes:Array<Pass>) {
        var passesNode = Reflect.field(node, "passes");

        if (Std.is(passesNode, Array)) {
            var tmp:Array<Dynamic> = cast passesNode;
            for (passNode in tmp) {
                // FIXME: switch to fallback instead of ignoring
                if (isDynamic(passNode) && !parseConfiguration(passNode)) {
                    continue;
                }

                parsePass(passNode, scope, passes);
            }
        }
        // FIXME: throw otherwise
    }

    private function parseDefaultValue(node:Dynamic, scope:Scope, valueName:String, defaultValues:Provider) {
        if (!isDynamic(node)) {
            return;
        }
        var memberNames = Reflect.fields(node) ;
        if (Lambda.has(memberNames, "default") == false) {
            return;
        }

        var defaultValueNode = Reflect.field(node, "default");
        if (isDynamic(defaultValueNode)) {
            parseDefaultValueVectorObject(defaultValueNode, scope, valueName, defaultValues);
        }
        else if (Std.is(defaultValueNode, Array)) {
            var tmps:Array<Array<Any>> = cast defaultValueNode ;
            if (tmps.length == 1 && Std.is(tmps[0], Array)) {
                parseDefaultValueVectorArray(tmps[0], scope, valueName, defaultValues);
            }
            else {
                throw ""; // FIXME: support array default values
            }
        }
        else if (Std.is(defaultValueNode, Bool)) {
            defaultValues.set(valueName, cast(defaultValueNode, Bool) ? 1 : 0);
        }
        else if (Std.is(defaultValueNode, Int)) {
            defaultValues.set(valueName, defaultValueNode);
        }
        else if (Std.is(defaultValueNode, Float)) {
            defaultValues.set(valueName, defaultValueNode);
        }
        else if (Std.is(defaultValueNode, String)) {
            loadTexture(cast(defaultValueNode, String), valueName, defaultValues);
        }
    }


    private function parseDefaultValueSamplerStates(cls:String, node:Dynamic, scope:Scope, valueName:String, defaultValues:Provider) {
        if (!isDynamic(node)) {
            return;
        }
        var memberNames = Reflect.fields(node);
        if (Lambda.has(memberNames, "default") == false) {
            return;
        }
        var defaultValueNode = Reflect.field(node, "default");
        if (Std.is(defaultValueNode, String)) {
            if (cls == "WrapMode") {
                defaultValues.set(valueName, SamplerStates.stringToWrapMode(defaultValueNode));
            }
            else if (cls == "TextureFilter") {
                defaultValues.set(valueName, SamplerStates.stringToTextureFilter(defaultValueNode));
            }
            else if (cls == "MipFilter") {
                defaultValues.set(valueName, SamplerStates.stringToMipFilter(defaultValueNode));
            }
        }
    }

    private function parseDefaultValueStates(node:Dynamic, scope:Scope, stateName:String, defaultValues:Provider) {
        if (!isDynamic(node)) {
            return;
        }

        var memberNames = Reflect.fields(node);

        if (Lambda.has(memberNames, "default") == false) {
            return;
        }

        var defaultValueNode = Reflect.field(node, "default");

        if (Std.is(defaultValueNode, Bool)) {
            defaultValues.set(stateName, defaultValueNode ? 1 : 0);
        }
        else if (Std.is(defaultValueNode, Int)) {
            defaultValues.set(stateName, defaultValueNode);
        }
        else if (Std.is(defaultValueNode, Float)) {
            defaultValues.set(stateName, defaultValueNode);
        }
        else if (Std.is(defaultValueNode, String)) {
            defaultValues.set(stateName, defaultValueNode);
        }
        else if (Std.is(defaultValueNode, Array)) {
            if (stateName == States.PROPERTY_PRIORITY && Std.is(node[0], String) && Std.is(node[1], Float)) {
                defaultValues.set(stateName, getPriorityValue(node[0]) + node[1]);
            }
            else {
                throw ""; // FIXME: support array default values
            }
        }

    }

    private function parseDefaultValueVectorArray(defaultValueNode:Array<Dynamic>, scope:Scope, valueName:String, defaultValues:Provider) {
        var size = defaultValueNode.length;
        var type = defaultValueNode[0] ;

        if (Std.is(type, Int) || Std.is(type, Float)) {
            var value = [];
            for (i in 0... size) {
                value[i] = defaultValueNode[i] ;
            }
            if (size == 2) {
                defaultValues.set(valueName, new Vec2(value[0], value[1]));
            }
            else if (size == 3) {
                defaultValues.set(valueName, new Vec3(value[0], value[1], value[2]));
            }
            else if (size == 4) {
                defaultValues.set(valueName, new Vec4(value[0], value[1], value[2], value[3]));
            }
        }
        else if (Std.is(type, Bool)) {
            // GLSL bool uniforms are set using integers, thus even if the default value is written
            // using boolean values, we store it as integers
            // https://www.opengl.org/sdk/docs/man/html/glUniform.xhtml
            var value = [];//(size);
            for (i in 0...size) {
                value[i] = defaultValueNode[i] ? 1 : 0;
            }
            if (size == 2) {
                defaultValues.set(valueName, new Vec2(value[0], value[1]));
            }
            else if (size == 3) {
                defaultValues.set(valueName, new Vec3(value[0], value[1], value[2]));
            }
            else if (size == 4) {
                defaultValues.set(valueName, new Vec4(value[0], value[1], value[2], value[3]));
            }
        }
    }

    private function parseDefaultValueVectorObject(defaultValueNode:Dynamic, scope:Scope, valueName:String, defaultValues:Provider) {
        var memberNames = Reflect.fields(defaultValueNode);
        var size = memberNames.length;
        var type = Reflect.field(defaultValueNode, memberNames[0]);
        var offsets:Array<String> = ["x", "y", "z", "w"];

        if (Std.is(type, Int) || Std.is(type, Float)) {
            var value = [];//(size);
            for (i in 0... size) {
                value[i] = Reflect.field(defaultValueNode, offsets[i]);
            }
            if (size == 2) {
                defaultValues.set(valueName, new Vec2(value[0], value[1]));
            }
            else if (size == 3) {
                defaultValues.set(valueName, new Vec3(value[0], value[1], value[2]));
            }
            else if (size == 4) {
                defaultValues.set(valueName, new Vec4(value[0], value[1], value[2], value[3]));
            }
        }
        else if (Std.is(type, Bool)) {
            // GLSL bool uniforms are set using integers, thus even if the default value is written
            // using boolean values, we store it as integers
            // https://www.opengl.org/sdk/docs/man/html/glUniform.xhtml
            var value = [];//(size);
            for (i in 0... size) {
                value[i] = Reflect.field(defaultValueNode, offsets[i]) ? 1 : 0;
            }
            if (size == 2) {
                defaultValues.set(valueName, new Vec2(value[0], value[1]));
            }
            else if (size == 3) {
                defaultValues.set(valueName, new Vec3(value[0], value[1], value[2]));
            }
            else if (size == 4) {
                defaultValues.set(valueName, new Vec4(value[0], value[1], value[2], value[3]));
            }
        }
    }

    private function parseBinding(node:Dynamic, scope:Scope, binding:Binding) {
        binding.source = Source.TARGET;

        if (Std.is(node, String)) {
            binding.propertyName = node ;

            return true;
        }
        else {
            var bindingNode = Reflect.field(node, "binding");

            if (Std.is(bindingNode, String)) {
                binding.propertyName = bindingNode;

                return true;
            }
            else if (isDynamic(bindingNode)) {
                var propertyNode = Reflect.field(bindingNode, "property");
                var sourceNode = Reflect.field(bindingNode, "source");

                if (Std.is(propertyNode, String)) {
                    binding.propertyName = propertyNode;
                }
                // FIXME: throw otherwise

                if (Std.is(sourceNode, String)) {
                    var sourceStr = sourceNode;

                    if (sourceStr == "target") {
                        binding.source = Source.TARGET;
                    }
                    else if (sourceStr == "renderer") {
                        binding.source = Source.RENDERER;
                    }
                    else if (sourceStr == "root") {
                        binding.source = Source.ROOT;
                    }
                }
                // FIXME: throw otherwise

                return true;
            }
        }

        return false;
    }

    private function parseMacroBinding(node:Dynamic, scope:Scope, binding:MacroBinding) {
        if (!isDynamic(node)) {
            return;
        }

        var bindingNode = Reflect.field(node, "binding");

        if (!isDynamic(bindingNode)) {
            return;
        }

        var minNode = Reflect.field(bindingNode, "min");
        if (Std.is(minNode, Int)) {
            binding.minValue = minNode;
        }
        // FIXME: throw otherwise

        var maxNode = Reflect.field(bindingNode, "max");
        if (Std.is(maxNode, Int)) {
            binding.maxValue = maxNode;
        }
        // FIXME: throw otherwise
    }


    public function parseMacroBindings(node:Any, scope:Scope, bindings:MacroBindingMap) {

    }

    public function parseAttributes(node:Any, scope:Scope, attributes:AttributeBlock) {
        var attributesNode = Reflect.field(node, "attributes");

        if (isDynamic(attributesNode)) {
            var defaultValuesProvider:Provider = null;
            if (attributes.bindingMap.defaultValues.providers.length > 0) {
                defaultValuesProvider = attributes.bindingMap.defaultValues.providers[0];
            }
            else {
                defaultValuesProvider = Provider.create();
                attributes.bindingMap.defaultValues.addProvider(defaultValuesProvider);
            }

            // var defaultValuesProvider:Provider = Provider.create();
            // attributes.bindingMap.defaultValues.addProvider(defaultValuesProvider);
            var memberNames = Reflect.fields(attributesNode);
            for (attributeName in memberNames) {
                var attributeNode = Reflect.field(attributesNode, attributeName);

                var binding:Binding = new Binding();
                if (parseBinding(attributeNode, scope, binding)) {
                    attributes.bindingMap.bindings.set(attributeName, binding);
                }

                //if (!attributeNode.get("default", 0).empty())
                //    throw ParserError("Default values are not yet supported for attributes.");

                // FIXME: support default values for vertex attributes

                //parseDefaultValue(
                //    attributeNode,
                //    scope,
                //   attributeName,
                //Json::ValueType::realValue,
                //    defaultValuesProvider
                //);
            }
        }
        // FIXME: throw otherwise
    }

    public function parseUniforms(node:Any, scope:Scope, uniforms:UniformBlock) {
        var uniformsNode = Reflect.field(node, "uniforms");

        if (isDynamic(uniformsNode)) {
            var defaultValuesProvider:Provider = null;

            if (uniforms.bindingMap.defaultValues.providers.length > 0) {
                defaultValuesProvider = uniforms.bindingMap.defaultValues.providers[0];
            }
            else {
                defaultValuesProvider = Provider.create();
                uniforms.bindingMap.defaultValues.addProvider(defaultValuesProvider);
            }

            for (uniformName in Reflect.fields(uniformsNode)) {
                var uniformNode = Reflect.field(uniformsNode, uniformName);

                var binding:Binding = new Binding();
                if (parseBinding(uniformNode, scope, binding)) {
                    uniforms.bindingMap.bindings.set(uniformName, binding);
                }

                parseSamplerStates(uniformNode, scope, uniformName, defaultValuesProvider, uniforms.bindingMap);

                parseDefaultValue(uniformNode, scope, uniformName, defaultValuesProvider);
            }
        }
        // FIXME: throw otherwise
    }

    public function parseMacros(node:Any, scope:Scope, macros:MacroBlock) {
        var macrosNode = Reflect.field(node, "macros");

        if (isDynamic(macrosNode)) {
            var defaultValuesProvider:Provider = null;

            if (macros.bindingMap.defaultValues.providers.length > 0) {
                defaultValuesProvider = macros.bindingMap.defaultValues.providers[0];
            }
            else {
                defaultValuesProvider = Provider.create();
                macros.bindingMap.defaultValues.addProvider(defaultValuesProvider);
            }

            for (macroName in Reflect.fields(macrosNode)) {
                var macroNode = Reflect.field(macrosNode, macroName);

                var binding:MacroBinding = new MacroBinding();
                if (parseBinding(macroNode, scope, binding)) {
                    parseMacroBinding(macroNode, scope, binding);
                    macros.bindingMap.bindings.set(macroName, binding);
                }

                parseDefaultValue(macroNode, scope, macroName, defaultValuesProvider);

                macros.bindingMap.types.set(macroName, MacroType.UNSET);
                if (isDynamic(macroNode)) {
                    var typeNode = Reflect.field(macroNode, "type");
                    if (Std.is(typeNode, String)) {
                        macros.bindingMap.types.set(macroName, MacroBindingMap.stringToMacroType(typeNode));
                    }
                }
            }
        }
        // FIXME: throw otherwise
    }

    private function parseStates(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        var statesNode = Reflect.field(node, "states");
        var memberNames = Reflect.fields(statesNode);
        if (isDynamic(statesNode)) {
            for (stateName in memberNames) {

                if (Lambda.has(States.PROPERTY_NAMES, stateName)) {
                    // Parse states
                    var parse_states = Reflect.field(statesNode, stateName);
                    if (isDynamic(parse_states)) {
                        var binding:Binding = new Binding();
                        if (parseBinding(parse_states, scope, binding)) {
                            stateBlock.bindingMap.bindings.set(stateName, binding);
                        }
                        else {
                            parseState(parse_states, scope, stateBlock, stateName);
                        }

                        // Don't forget to parse default value, even if there is no binding
                        if (Reflect.hasField(parse_states, "default")) {
                            var defaultValueNode = Reflect.field(parse_states, "default");
                            parseState(defaultValueNode, scope, stateBlock, stateName);
                        }
                    }
                    else {
                        parseState(parse_states, scope, stateBlock, stateName);
                    }
                }
                else if (Lambda.has(_extraStateNames, stateName)) {
                    var parse_states = Reflect.field(statesNode, stateName);
                    // Parse extra states
                    if (stateName == EXTRA_PROPERTY_BLENDING_MODE) {
                        parseBlendingMode(parse_states, scope, stateBlock);
                    }
                    else if (stateName == EXTRA_PROPERTY_STENCIL_TEST) {
                        parseStencilState(parse_states, scope, stateBlock);
                    }
                }
                else {
                    //throw ""; // FIXME: log warning because the state name does not match any known state
                }
            }
        }
    }

    private function parseState(node:Dynamic, scope:Scope, stateBlock:StateBlock, stateProperty:String) {
        if (stateProperty == States.PROPERTY_PRIORITY) {
            parsePriority(node, scope, stateBlock);
        }
        else if (stateProperty == _extraStateNames[0]) {
            parseBlendingMode(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_BLENDING_SOURCE) {
            parseBlendingSource(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_BLENDING_DESTINATION) {
            parseBlendingDestination(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_ZSORTED) {
            parseZSort(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_COLOR_MASK) {
            parseColorMask(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_DEPTH_MASK) {
            parseDepthMask(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_DEPTH_FUNCTION) {
            parseDepthFunction(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_TRIANGLE_CULLING) {
            parseTriangleCulling(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_STENCIL_FUNCTION) {
            parseStencilFunction(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_STENCIL_REFERENCE) {
            parseStencilReference(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_STENCIL_MASK) {
            parseStencilMask(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_STENCIL_FAIL_OPERATION) {
            parseStencilFailOperation(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_STENCIL_ZFAIL_OPERATION) {
            parseStencilZFailOperation(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_STENCIL_ZPASS_OPERATION) {
            parseStencilZPassOperation(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_SCISSOR_TEST) {
            parseScissorTest(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_SCISSOR_BOX) {
            parseScissorBox(node, scope, stateBlock);
        }
        else if (stateProperty == States.PROPERTY_TARGET) {
            parseTarget(node, scope, stateBlock);
        }
    }

    private function parsePriority(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (node != null) {
            var priority = 0.0;

            if (Std.is(node, Int)) {
                priority = node ;
            }
            else if (Std.is(node, Float)) {
                priority = node ;
            }
            else if (Std.is(node, String)) {
                priority = getPriorityValue(node);
            }
            else if (Std.is(node, Array)) {
                var tmp:Array<Any> = cast node;
                if (Std.is(tmp[0], String) && Std.is(tmp[1], Float)) {
                    priority = getPriorityValue(tmp[0]) + cast tmp[1] ;
                }
            }

            stateBlock.states.priority = (priority);
        }
    }

    private function parseBlendingMode(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, Array)) {
            var blendingSrcString:String = node[0];
            if (_blendingSourceMap.exists(blendingSrcString)) {
                stateBlock.states.blendingSourceFactor = _blendingSourceMap.get(blendingSrcString);
            }

            var blendingDstString = node[1];
            if (_blendingDestinationMap.exists(blendingDstString)) {
                stateBlock.states.blendingDestinationFactor = _blendingDestinationMap.get(blendingDstString);
            }
        }
        else if (Std.is(node, String)) {
            var blendingModeString:String = node ;

            if (_blendingModeMap.exists(blendingModeString)) {
                var blendingMode = _blendingModeMap.get(blendingModeString);

                stateBlock.states.blendingSourceFactor = (blendingMode & 0x00ff);
                stateBlock.states.blendingDestinationFactor = (blendingMode & 0xff00);
            }
        }
    }

    private function parseBlendingSource(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            var blendingSourceString = _blendingSourceMap.get(node);

            stateBlock.states.blendingSourceFactor = blendingSourceString;
        }
    }

    private function parseBlendingDestination(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            var blendingDestination = _blendingDestinationMap.get(node);

            stateBlock.states.blendingDestinationFactor = blendingDestination;
        }
    }

    private function parseZSort(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, Bool)) {
            stateBlock.states.zSorted = (node);
        }
    }

    private function parseColorMask(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, Bool)) {

            stateBlock.states.colorMask = (node);
        }
    }

    private function parseDepthMask(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, Bool)) {
            stateBlock.states.depthMask = (node);
        }
    }

    private function parseDepthFunction(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            var compareModeString = node;
            var exist = _compareFuncMap.exists(compareModeString);

            if (exist) {
                stateBlock.states.depthFunction = _compareFuncMap.get(compareModeString);
            }
        }
    }

    private function parseTriangleCulling(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            var triangleCullingString = node ;
            var exist = _triangleCullingMap.exists(triangleCullingString);

            if (exist) {
                stateBlock.states.triangleCulling = _triangleCullingMap.get(triangleCullingString);
            }
        }
    }

    private function parseTarget(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        var target:AbstractTexture = null;
        var targetName:String = "";

        if (isDynamic(node)) {
            var nameValue = Reflect.field(node, "name");

            if (Std.is(nameValue, String)) {
                targetName = nameValue ;
            }

            if (!Reflect.hasField(node, "size") && !(Reflect.hasField(node, "width") && Reflect.hasField(node, "height"))) {
                return;
            }

            var width = 0;
            var height = 0;

            if (Reflect.hasField(node, "size")) {
                width = height = Reflect.field(node, "size");
            }
            else {
                if (!Reflect.hasField(node, "width") || !Reflect.hasField(node, "height")) {
                    _error.execute(this, (_resolvedFilename + ": render target definition requires both \"width\" and \"height\" properties."));
                }

                width = Reflect.field(node, "width");
                height = Reflect.field(node, "height");
            }

            var isCubeTexture = Reflect.hasField(node, "isCube") ? Reflect.field(node, "isCube") : false;

            if (isCubeTexture) {
                target = CubeTexture.create(_options.context, width, height, false, true);

                if (targetName.length != 0) {
                    _assetLibrary.setCubeTexture(targetName, cast(target));
                }
            }
            else {
                target = Texture.create(_options.context, width, height, false, true);

                if (targetName.length != 0) {
                    _assetLibrary.setTexture(targetName, cast(target));
                }
            }

            target.upload();
            _effectData.set(targetName, target);
        }
        else if (Std.is(node, String)) {
            targetName = node;
            target = _assetLibrary.texture(targetName);
            if (target == null) {
                throw "";
            }

            _effectData.set(targetName, target);
        }

        if (target != null) {
            stateBlock.states.target = (target );
           // trace("      stateBlock.states.target = (target );");
           // trace(target);
        }
    }

    private function parseStencilState(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (isDynamic(node)) {
            var stencilFuncValue = Reflect.field(node, States.PROPERTY_STENCIL_FUNCTION);
            var stencilRefValue = Reflect.field(node, States.PROPERTY_STENCIL_REFERENCE);
            var stencilMaskValue = Reflect.field(node, States.PROPERTY_STENCIL_MASK);
            var stencilOpsValue = Reflect.field(node, EXTRA_PROPERTY_STENCIL_OPS);

            parseStencilFunction(stencilFuncValue, scope, stateBlock);
            parseStencilReference(stencilRefValue, scope, stateBlock);
            parseStencilMask(stencilMaskValue, scope, stateBlock);

            parseStencilOperations(stencilOpsValue, scope, stateBlock);
        }
        else if (Std.is(node, Array)) {
            parseStencilFunction(node[0], scope, stateBlock);
            parseStencilReference(node[1], scope, stateBlock);
            parseStencilMask(node[2], scope, stateBlock);

            parseStencilOperations(node[3], scope, stateBlock);
        }
    }

    private function parseStencilFunction(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            stateBlock.states.stencilFunction = _compareFuncMap.get(node);
        }
    }

    private function parseStencilReference(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, Int)) {
            stateBlock.states.stencilReference = node;
        }
    }

    private function parseStencilMask(node:Dynamic, scope:Scope, stateBlock:StateBlock) {

        if (Std.is(node, Int)) {
            stateBlock.states.stencilMask = node;
        }
    }

    private function parseStencilOperations(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, Array)) {
            if (Std.is(node[0], String)) {
                stateBlock.states.stencilFailOperation = _stencilOpMap.get(node[0]);
            }
            if (Std.is(node[1], String)) {
                stateBlock.states.stencilZFailOperation = _stencilOpMap.get(node[1]);
            }
            if (Std.is(node[2], String)) {
                stateBlock.states.stencilZPassOperation = _stencilOpMap.get(node[2]);
            }
        }
        else {
            parseStencilFailOperation(Reflect.field(node, EXTRA_PROPERTY_STENCIL_FAIL_OP), scope, stateBlock);
            parseStencilZFailOperation(Reflect.field(node, EXTRA_PROPERTY_STENCIL_Z_FAIL_OP), scope, stateBlock);
            parseStencilZPassOperation(Reflect.field(node, EXTRA_PROPERTY_STENCIL_Z_PASS_OP), scope, stateBlock);
        }
    }

    private function parseStencilFailOperation(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            stateBlock.states.stencilFailOperation = _stencilOpMap.get(node);
        }
    }

    private function parseStencilZFailOperation(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            stateBlock.states.stencilZFailOperation = _stencilOpMap.get(node);
        }
    }

    private function parseStencilZPassOperation(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (Std.is(node, String)) {
            stateBlock.states.stencilZPassOperation = _stencilOpMap.get(node);
        }
    }

    private function parseScissorTest(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (node != null && Std.is(node, Bool)) {
            stateBlock.states.scissorTest = (node);
        }
    }

    private function parseScissorBox(node:Dynamic, scope:Scope, stateBlock:StateBlock) {
        if (node != null && Std.is(node, Array)) {
            var scissorBox = new Vec4();

            if (Std.is(node[0], Int)) {
                scissorBox.x = node[0] ;
            }
            if (Std.is(node[1], Int)) {
                scissorBox.y = node[1] ;
            }
            if (Std.is(node[2], Int)) {
                scissorBox.z = node[2] ;
            }
            if (Std.is(node[3], Int)) {
                scissorBox.w = node[3] ;
            }

            stateBlock.states.scissorBox = (scissorBox);
        }
    }

    private function parseSamplerStates(node:Dynamic, scope:Scope, uniformName:String, defaultValues:Provider, bindingMap:BindingMapBase<Binding>) {
        if (isDynamic(node)) {
            var wrapModeNode = Reflect.field(node, SamplerStates.PROPERTY_WRAP_MODE);

            if (Std.is(wrapModeNode, String)) {
                var wrapModeStr = wrapModeNode ;

                var wrapMode = SamplerStates.stringToWrapMode(wrapModeStr);

                defaultValues.set(SamplerStates.uniformNameToSamplerStateName(uniformName, SamplerStates.PROPERTY_WRAP_MODE), wrapMode);
            }
            else if (isDynamic(wrapModeNode)) {
                var uniformWrapModeBindingName = SamplerStates.uniformNameToSamplerStateName(uniformName, SamplerStates.PROPERTY_WRAP_MODE);

                if (!bindingMap.bindings.exists(uniformWrapModeBindingName)) {
                    bindingMap.bindings.set(uniformWrapModeBindingName, new Binding());
                }
                parseBinding(wrapModeNode, scope, bindingMap.bindings.get(uniformWrapModeBindingName));

                parseDefaultValueSamplerStates("WrapMode", wrapModeNode, scope, uniformWrapModeBindingName, defaultValues);
            }

            var textureFilterNode = Reflect.field(node, SamplerStates.PROPERTY_TEXTURE_FILTER);

            if (Std.is(textureFilterNode, String)) {
                var textureFilterStr = textureFilterNode ;

                var textureFilter = SamplerStates.stringToTextureFilter(textureFilterStr);

                defaultValues.set(SamplerStates.uniformNameToSamplerStateName(uniformName, SamplerStates.PROPERTY_TEXTURE_FILTER), textureFilter);
            }
            else if (isDynamic(textureFilterNode)) {
                var uniformTextureFilterBindingName = SamplerStates.uniformNameToSamplerStateName(uniformName, SamplerStates.PROPERTY_TEXTURE_FILTER);
                if (!bindingMap.bindings.exists(uniformTextureFilterBindingName)) {
                    bindingMap.bindings.set(uniformTextureFilterBindingName, new Binding());
                }
                parseBinding(textureFilterNode, scope, bindingMap.bindings.get(uniformTextureFilterBindingName));

                parseDefaultValueSamplerStates("TextureFilter", textureFilterNode, scope, uniformTextureFilterBindingName, defaultValues);
            }

            var mipFilterNode = Reflect.field(node, SamplerStates.PROPERTY_MIP_FILTER);

            if (Std.is(mipFilterNode, String)) {
                var mipFilterStr = mipFilterNode;

                var mipFilter = SamplerStates.stringToMipFilter(mipFilterStr);

                defaultValues.set(SamplerStates.uniformNameToSamplerStateName(uniformName, SamplerStates.PROPERTY_MIP_FILTER), mipFilter);
            }
            else if (isDynamic(mipFilterNode)) {
                var uniformMipFilterBindingName = SamplerStates.uniformNameToSamplerStateName(uniformName, SamplerStates.PROPERTY_MIP_FILTER);
                if (!bindingMap.bindings.exists(uniformMipFilterBindingName)) {
                    bindingMap.bindings.set(uniformMipFilterBindingName, new Binding());
                }
                parseBinding(mipFilterNode, scope, bindingMap.bindings.get(uniformMipFilterBindingName));

                parseDefaultValueSamplerStates("MipFilter", mipFilterNode, scope, uniformMipFilterBindingName, defaultValues);
            }
        }
    }

    private function parseShader(node:Dynamic, scope:Scope, type:ShaderType) {
        if (!Std.is(node, String)) {
            throw "";
        }

        var glsl:String = node ;

        var shader:Shader = Shader.createbySource(_options.context, type, glsl);
        var blocks = new GLSLBlockTree(new GLSLBlock(GLSLBlockType.TEXT, ""));
        var includes = [];
        _shaderToGLSL.set(shader, blocks);
        //todo
        parseGLSL(glsl, _options, blocks, includes);

        shader.source = glsl;


        return shader;
    }

    function parseGLSL(glsl:String,
                       options:Options,
                       blocks:GLSLBlockTree, includes:Array<String>) {
        var stream:Array<String> = glsl.split("\n");
        var i = 0;
        var lastBlockEnd = 0;
        var numIncludes = 0;

        for (line in stream) {
            var pos = line.indexOf("#pragma include ");
            var commentPos = line.indexOf("//");
            if (pos != -1 && (commentPos == -1 || pos < commentPos) && (line.indexOf('"', pos) != -1 || line.indexOf('\'', pos) != -1)) {
                var splitStr = '\'';
                if (line.indexOf('"', pos) != -1) {
                    splitStr = '"';
                }
                var filename:String = line.substring(line.indexOf(splitStr, pos) + splitStr.length, line.lastIndexOf(splitStr));

                if (lastBlockEnd != i) {
                    blocks.leaf.push(new GLSLBlockTree(new GLSLBlock(GLSLBlockType.TEXT, glsl.substr(lastBlockEnd, i - lastBlockEnd))));

                    //  trace("a",lastBlockEnd, i - lastBlockEnd);
                    // trace( glsl.substr(lastBlockEnd, i - lastBlockEnd));
                    //todo
                }
                if (!Lambda.has(includes, filename)) {
                    includes.push(filename);
                    blocks.leaf.push(new GLSLBlockTree(new GLSLBlock(GLSLBlockType.FILE, filename)));
                }


                lastBlockEnd = i + line.length + 1;

                ++numIncludes;
            }
            i += line.length + 1;
        }

        if (i != lastBlockEnd) {
            blocks.leaf.push(new GLSLBlockTree(new GLSLBlock(GLSLBlockType.TEXT, glsl.substr(lastBlockEnd))));
            // trace("b",lastBlockEnd );
            // trace( glsl.substr(lastBlockEnd));
        }


        if (numIncludes > 0){
            loadGLSLDependencies(blocks, options, includes);
        }

    }

    function loadGLSLDependencies(blocks:GLSLBlockTree,
                                  options:Options, includes:Array<String>) {

        for (blockIt in blocks.leaf) {
            var block = blockIt.node;
            if (block.type == GLSLBlockType.FILE) {
                if (options.assetLibrary.hasBlob(block.value)) {
                    var data:Bytes = options.assetLibrary.blob(block.value);
                    parseGLSL(data.toString(), options, blockIt, includes);
                }
                else {
                    //   options.includePaths_clear();
                    var loader:Loader = Loader.createbyOptions(options);

                    _numDependencies++;

                    _loaderCompleteSlots.set(loader, loader.complete.connect(function(_1) {

                        glslIncludeCompleteHandler(_1, blockIt, block.value, includes);
                        _numLoadedDependencies++;
                        checkLoadedAndfinalize();
                    }, 0, true)
                    );

                    _loaderErrorSlots.set(loader, loader.error.connect(function(_1, _2) {
                        dependencyErrorHandler(_1, _2, block.value);
                    }, 0, true));

                    loader.queue(block.value).load();
                }
            }
        }


    }
    inline function checkLoadedAndfinalize(){
        if (_numDependencies == _numLoadedDependencies && _effect != null)
            finalize();
    }
    private function dependencyErrorHandler(loader:Loader, error:String, filename:String) {
        var err = "Unable to load '" + filename + "' required by \"" + _filename + "\", included paths are: " + loader.options.includePaths ;

        _error.execute(this, err);
    }

    public function createStates(block:StateBlock) : States{
        return null ;
    }

    public function concatenateGLSLBlocks(blocks:GLSLBlockTree) {
        var glsl = "";


        // Tuple<GLSLBlockType, String>
        for (block in blocks.leaf){
            glsl += concatenateGLSLBlocks(block);
        }
        if(blocks.node.type==GLSLBlockType.TEXT){
            glsl+=blocks.node.value;
        }else
        {
            trace("concatenateGLSLBlocks",blocks.node.value);
            glsl+=("\n//"+blocks.node.value+"\n");
        }

        return glsl;
    }

    public function glslIncludeCompleteHandler(loader:Loader,
                                               blocks:GLSLBlockTree,
                                               filename:String, includes:Array<String>) {
        var block:GLSLBlock = blocks.node;
        var file:File = loader.files.get(filename);
        var resolvedFilename:String = file.resolvedFilename;
        var options = loader.options;
        var pos = resolvedFilename.lastIndexOf("/");
        if (pos == -1) {
            pos = resolvedFilename.lastIndexOf("\\");
        }
        if (pos != -1) {
            options = options.clone();
            options.includePaths = [];
            options.includePaths.push(resolvedFilename.substr(0, pos));
        }

        parseGLSL(file.data.toString(), options, blocks, includes);

    }

    function loadTexture(textureFilename:String, uniformName:String, defaultValues:Provider) {
        if (_options.assetLibrary.texture(textureFilename) != null) {
            defaultValues.set(uniformName, _assetLibrary.texture(textureFilename));
            return;
        }

        var loader:Loader = Loader.createbyOptions(_options);

        _numDependencies++;

        _loaderCompleteSlots.set(loader, loader.complete.connect(function(loader:Loader) {
            var texture:Texture = _assetLibrary.texture(textureFilename);

            //value.textureValues.push_back(texture);
            defaultValues.set(uniformName, texture);
            texture.upload();

            _numLoadedDependencies++;
            checkLoadedAndfinalize();
        }));

        _loaderErrorSlots.set(loader, loader.error.connect(function(_1, _2) {
            dependencyErrorHandler(_1, _2, textureFilename);
        }
        ));

        loader.queue(textureFilename).load();
    }

    function finalize() {
        for (technique in _globalScope.techniques.keys()) {
            var technique_second:Array<Pass> = _globalScope.techniques.get(technique);
            _effect.addTechnique(technique, technique_second);

            for (pass in technique_second) {
                var vs = pass.program.vertexShader;
                var fs = pass.program.fragmentShader;

                if (_shaderToGLSL.exists(vs))
                    vs.source = ("#define VERTEX_SHADER\n" + concatenateGLSLBlocks(_shaderToGLSL.get(vs)));
                if (_shaderToGLSL.exists(fs))
                    fs.source = ("#define FRAGMENT_SHADER\n" + concatenateGLSLBlocks(_shaderToGLSL.get(fs)));
            }
        }

        _effect.data.copyFrom(_effectData);
        _options.assetLibrary.setEffect(_filename, _effect);

        _complete.execute(this);

        for (lc in _loaderCompleteSlots) {
            lc.dispose();
        }
        _loaderCompleteSlots = new ObjectMap<Loader, SignalSlot<Loader>>();
        for (lc in _loaderErrorSlots) {
            lc.dispose();
        }
        _loaderErrorSlots = new ObjectMap<Loader, SignalSlot2<Loader, String>>();
    }
}

