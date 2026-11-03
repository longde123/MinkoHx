package minko.file;

import haxe.ds.StringMap;
import haxe.format.JsonParser;
import haxe.io.Bytes;
import minko.render.Blending.Source as BlendingSource;
import minko.render.Blending.Destination as BlendingDestination;
import minko.render.TriangleCulling;
import minko.render.pipeline.EffectStage;
import minko.render.pipeline.PipelineEffect;
import minko.render.pipeline.PipelineState;
import minko.render.pipeline.PipelineTechnique;
import minko.render.pipeline.PipelineUniform;
import minko.render.pipeline.UniformSource;

/**
 * Parses a .peffect JSON file into a pipeline-native PipelineEffect.
 *
 * Supported:
 * - inline vertex/fragment strings;
 * - external shader files via { "file": "shaders/x.vert" };
 * - recursive #pragma include "file.glsl" in inline or external sources;
 * - top-level and per-technique macros compiled into #define lines.
 *
 * This parser does not create legacy Effect/Pass objects and does not compile
 * shaders. Shader sources are stored on the technique and compiled lazily by
 * PipelineEffectRenderer.
 */
@:expose("minko.file.PipelineEffectParser")
class PipelineEffectParser extends AbstractParser {
    private static var _macroNamePattern = new EReg("^[A-Za-z_][A-Za-z0-9_]*$", "");

    private var _effect:PipelineEffect;
    private var _buildingEffect:PipelineEffect;
    private var _filename:String;
    private var _resolvedFilename:String;
    private var _assetLibrary:AssetLibrary;
    private var _resolver:PipelineShaderResolver;
    private var _pendingSources:Int;
    private var _sourcesStarted:Bool;
    private var _failed:Bool;
    private var _errorReported:Bool;
    private var _completed:Bool;

    public static function create():PipelineEffectParser {
        return new PipelineEffectParser();
    }

    public var effect(get, null):PipelineEffect;

    function get_effect() {
        return _effect;
    }

    public function new() {
        super();
        _effect = null;
        _buildingEffect = null;
        _filename = "";
        _resolvedFilename = "";
        _assetLibrary = null;
        _resolver = null;
        _pendingSources = 0;
        _sourcesStarted = false;
        _failed = false;
        _errorReported = false;
        _completed = false;
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary):Void {
        if (_resolver != null) {
            _resolver.dispose();
            _resolver = null;
        }

        _filename = filename;
        _resolvedFilename = resolvedFilename;
        _assetLibrary = assetLibrary;
        _effect = null;
        _buildingEffect = null;
        _pendingSources = 0;
        _sourcesStarted = false;
        _failed = false;
        _errorReported = false;
        _completed = false;

        if (data == null) {
            _fail("no data");
            return;
        }

        var json = data.toString();
        if (json.length > 0 && json.charCodeAt(0) == 0xFEFF) {
            json = json.substr(1);
        }

        var root:Dynamic = null;
        try {
            root = JsonParser.parse(json);
        }
        catch (e:Dynamic) {
            _fail("invalid JSON: " + Std.string(e));
            return;
        }

        try {
            _resolver = new PipelineShaderResolver(options != null ? options : Options.empty(), _onResolverError);
            var effect = _parseEffect(root);
            if (_failed) {
                return;
            }
            _buildingEffect = effect;
            _sourcesStarted = true;
            _checkComplete();
        }
        catch (e:Dynamic) {
            _fail(Std.string(e));
        }
    }

    private function _parseEffect(root:Dynamic):PipelineEffect {
        if (!_isObject(root)) {
            throw "root must be a JSON object";
        }

        var name = _filename;
        if (Reflect.hasField(root, "name")) {
            var nameValue = Reflect.field(root, "name");
            if (Std.isOfType(nameValue, String) && StringTools.trim(cast nameValue) != "") {
                name = cast nameValue;
            }
        }

        var effect = PipelineEffect.create(name);
        var topMacros = _parseMacros(Reflect.field(root, "macros"), "macros");

        var techniquesNode = Reflect.field(root, "techniques");
        if (!Std.isOfType(techniquesNode, Array)) {
            throw "\"techniques\" must be an array";
        }

        var techniques:Array<Dynamic> = cast techniquesNode;
        if (techniques.length == 0) {
            throw "\"techniques\" must not be empty";
        }

        var baseDir = _dirname(_resolvedFilename);
        var seenStages = new StringMap<Bool>();
        for (index in 0...techniques.length) {
            var technique = _parseTechnique(techniques[index], index, topMacros, baseDir, seenStages);
            effect.addTechnique(technique);
            if (_failed) {
                break;
            }
        }

        return effect;
    }

    private function _parseTechnique(node:Dynamic, index:Int, topMacros:StringMap<String>,
                                     baseDir:String, seenStages:StringMap<Bool>):PipelineTechnique {
        var context = "technique[" + index + "]";
        if (!_isObject(node)) {
            throw context + " must be an object";
        }

        var stage = _parseStage(Reflect.field(node, "stage"), index);
        var stageKey = _stageName(stage);
        if (seenStages.exists(stageKey)) {
            throw context + ": duplicate stage \"" + stageKey + "\"";
        }
        seenStages.set(stageKey, true);

        var vertexRef = _parseShaderRef(Reflect.field(node, "vertexShader"), "vertexShader", context);
        var fragmentRef = _parseShaderRef(Reflect.field(node, "fragmentShader"), "fragmentShader", context);
        var uniforms = _parseUniforms(Reflect.field(node, "uniforms"), index);
        var state = _parseState(Reflect.field(node, "states"), index);
        var macros = _mergeMacros(topMacros, _parseMacros(Reflect.field(node, "macros"), context + ".macros"));

        var technique = new PipelineTechnique(stage, "", "", uniforms, state, "", macros);

        _pendingSources += 2;
        _resolveShader(technique, true, vertexRef, baseDir);
        if (!_failed) {
            _resolveShader(technique, false, fragmentRef, baseDir);
        }

        return technique;
    }

    private function _resolveShader(technique:PipelineTechnique, isVertex:Bool, ref:{inlineSource:String, filename:String},
                                    baseDir:String):Void {
        if (_failed || _resolver == null) {
            return;
        }

        var done = function(source:String) {
            if (_failed) {
                return;
            }
            if (isVertex) {
                technique.vertexSource = source;
            }
            else {
                technique.fragmentSource = source;
            }
            _pendingSources--;
            _checkComplete();
        };

        if (ref.filename != null) {
            _resolver.resolveFile(ref.filename, baseDir, done);
        }
        else {
            _resolver.resolveInline(ref.inlineSource, baseDir, done);
        }
    }

    private function _parseShaderRef(node:Dynamic, field:String, context:String):{inlineSource:String, filename:String} {
        if (Std.isOfType(node, String) && StringTools.trim(cast node) != "") {
            return {inlineSource: cast node, filename: null};
        }

        if (_isObject(node)) {
            var fileValue:Dynamic = Reflect.field(node, "file");
            if (Std.isOfType(fileValue, String) && StringTools.trim(cast fileValue) != "") {
                return {inlineSource: null, filename: cast fileValue};
            }
            throw context + ": \"" + field + "\" object requires a non-empty \"file\" string";
        }

        throw context + ": \"" + field + "\" must be an inline string or { \"file\": \"...\" }";
    }

    private function _parseMacros(node:Dynamic, context:String):StringMap<String> {
        var macros = new StringMap<String>();
        if (node == null) {
            return macros;
        }
        if (!_isObject(node)) {
            throw context + " must be an object";
        }

        for (name in Reflect.fields(node)) {
            if (!_macroNamePattern.match(name)) {
                throw context + ": invalid macro name \"" + name + "\"";
            }

            var value:Dynamic = Reflect.field(node, name);
            if (value == null) {
                macros.set(name, null);
                continue;
            }
            if (Std.isOfType(value, Bool)) {
                macros.set(name, cast(value, Bool) ? "" : null);
                continue;
            }
            if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
                macros.set(name, Std.string(value));
                continue;
            }
            if (Std.isOfType(value, String)) {
                var stringValue:String = cast value;
                if (stringValue.indexOf("\n") != -1 || stringValue.indexOf("\r") != -1) {
                    throw context + "." + name + ": macro value must not contain newlines";
                }
                macros.set(name, stringValue);
                continue;
            }

            throw context + "." + name + ": macro value must be a boolean, number or string";
        }

        return macros;
    }

    private function _mergeMacros(base:StringMap<String>, overrides:StringMap<String>):StringMap<String> {
        var merged = new StringMap<String>();
        for (name in base.keys()) {
            merged.set(name, base.get(name));
        }
        for (name in overrides.keys()) {
            merged.set(name, overrides.get(name));
        }
        return merged;
    }

    private function _onResolverError(message:String):Void {
        _fail(message);
    }

    private function _checkComplete():Void {
        if (_completed || _failed || !_sourcesStarted || _pendingSources != 0) {
            return;
        }

        var effect = _buildingEffect;
        if (effect == null) {
            return;
        }

        _completed = true;
        _effect = effect;
        _buildingEffect = null;

        if (_assetLibrary != null) {
            _assetLibrary.setPipelineEffect(_filename, effect);
        }
        if (_resolver != null) {
            _resolver.dispose();
            _resolver = null;
        }

        _progress.execute(this, 1.0);
        _complete.execute(this);
    }

    private function _parseStage(value:Dynamic, index:Int):EffectStage {
        if (!Std.isOfType(value, String)) {
            throw "technique[" + index + "]: \"stage\" must be a string";
        }

        var stageName:String = cast value;
        switch (stageName) {
            case "forward":
                return EffectStage.Forward;
            case "transparent":
                return EffectStage.Transparent;
            case "gbuffer":
                return EffectStage.GBuffer;
            case "gbuffer-albedo":
                return EffectStage.GBufferAlbedo;
            case "gbuffer-normal":
                return EffectStage.GBufferNormal;
            case "gbuffer-emissive":
                return EffectStage.GBufferEmissive;
            case "shadow":
                return EffectStage.Shadow;
            default:
                throw "technique[" + index + "]: unknown stage \"" + stageName + "\"";
        }
    }

    private function _stageName(stage:EffectStage):String {
        switch (stage) {
            case EffectStage.Forward:
                return "forward";
            case EffectStage.Transparent:
                return "transparent";
            case EffectStage.GBuffer:
                return "gbuffer";
            case EffectStage.GBufferAlbedo:
                return "gbuffer-albedo";
            case EffectStage.GBufferNormal:
                return "gbuffer-normal";
            case EffectStage.GBufferEmissive:
                return "gbuffer-emissive";
            case EffectStage.Shadow:
                return "shadow";
            default:
                return "unknown";
        }
    }

    private function _parseUniforms(node:Dynamic, techniqueIndex:Int):Array<PipelineUniform> {
        var uniforms = new Array<PipelineUniform>();
        if (node == null) {
            return uniforms;
        }
        if (!_isObject(node)) {
            throw "technique[" + techniqueIndex + "]: \"uniforms\" must be an object";
        }

        for (name in Reflect.fields(node)) {
            uniforms.push(_parseUniform(name, Reflect.field(node, name), techniqueIndex));
        }
        return uniforms;
    }

    private function _parseUniform(name:String, node:Dynamic, techniqueIndex:Int):PipelineUniform {
        var context = "technique[" + techniqueIndex + "].uniforms." + name;
        if (!_isObject(node)) {
            throw context + ": expected { \"source\" | \"material\" | \"value\" }";
        }

        var hasSource = Reflect.hasField(node, "source");
        var hasMaterial = Reflect.hasField(node, "material");
        var hasValue = Reflect.hasField(node, "value");
        var modes = (hasSource ? 1 : 0) + (hasMaterial ? 1 : 0) + (hasValue ? 1 : 0);

        if (modes != 1) {
            throw context + ": exactly one of \"source\", \"material\" or \"value\" is required";
        }

        if (hasSource) {
            return new PipelineUniform(name, _parseSource(Reflect.field(node, "source"), context));
        }

        if (hasMaterial) {
            var property:Dynamic = Reflect.field(node, "material");
            if (!Std.isOfType(property, String) || StringTools.trim(cast property) == "") {
                throw context + ": \"material\" must be a non-empty string";
            }
            return PipelineUniform.material(name, cast property);
        }

        return PipelineUniform.constant(name, Reflect.field(node, "value"));
    }

    private function _parseSource(value:Dynamic, context:String):UniformSource {
        if (!Std.isOfType(value, String)) {
            throw context + ": \"source\" must be a string";
        }

        var source:String = cast value;
        switch (source) {
            case "modelMatrix":
                return UniformSource.ModelMatrix;
            case "normalMatrix":
                return UniformSource.NormalMatrix;
            case "viewMatrix":
                return UniformSource.ViewMatrix;
            case "projectionMatrix":
                return UniformSource.ProjectionMatrix;
            case "cameraPosition":
                return UniformSource.CameraPosition;
            case "time":
                return UniformSource.Time;
            case "lightDirection":
                return UniformSource.LightDirection;
            case "lightColor":
                return UniformSource.LightColor;
            case "lightIntensity":
                return UniformSource.LightIntensity;
            case "lightViewProjection":
                return UniformSource.LightViewProjection;
            case "shadowMap":
                return UniformSource.ShadowMap;
            case "hasShadowMap":
                return UniformSource.HasShadowMap;
            default:
                throw context + ": unknown source \"" + source + "\"";
        }
    }

    private function _parseState(node:Dynamic, techniqueIndex:Int):PipelineState {
        var state = PipelineState.opaque();
        if (node == null) {
            return state;
        }
        if (!_isObject(node)) {
            throw "technique[" + techniqueIndex + "]: \"states\" must be an object";
        }

        for (name in Reflect.fields(node)) {
            var value:Dynamic = Reflect.field(node, name);
            var context = "technique[" + techniqueIndex + "].states." + name;
            switch (name) {
                case "depthTest":
                    state.depthTest = _requireBool(value, context);
                case "depthWrite":
                    state.depthWrite = _requireBool(value, context);
                case "colorMask":
                    state.colorMask = _requireBool(value, context);
                case "blending":
                    _applyBlending(state, value, context);
                case "triangleCulling":
                    state.triangleCulling = _parseCulling(value, context);
                default:
                    throw context + ": unknown state";
            }
        }

        return state;
    }

    private function _applyBlending(state:PipelineState, value:Dynamic, context:String):Void {
        if (!Std.isOfType(value, String)) {
            throw context + " must be one of \"default\", \"alpha\" or \"additive\"";
        }

        var mode:String = cast value;
        switch (mode) {
            case "default":
                state.blendingSource = BlendingSource.ONE;
                state.blendingDestination = BlendingDestination.ZERO;
            case "alpha":
                state.blendingSource = BlendingSource.SRC_ALPHA;
                state.blendingDestination = BlendingDestination.ONE_MINUS_SRC_ALPHA;
            case "additive":
                state.blendingSource = BlendingSource.SRC_ALPHA;
                state.blendingDestination = BlendingDestination.ONE;
            default:
                throw context + ": unknown blending \"" + mode + "\"";
        }
    }

    private function _parseCulling(value:Dynamic, context:String):TriangleCulling {
        if (!Std.isOfType(value, String)) {
            throw context + " must be one of \"none\", \"front\", \"back\" or \"both\"";
        }

        var culling:String = cast value;
        switch (culling) {
            case "none":
                return TriangleCulling.NONE;
            case "front":
                return TriangleCulling.FRONT;
            case "back":
                return TriangleCulling.BACK;
            case "both":
                return TriangleCulling.BOTH;
            default:
                throw context + ": unknown triangleCulling \"" + culling + "\"";
        }
    }

    private function _requireBool(value:Dynamic, context:String):Bool {
        if (!Std.isOfType(value, Bool)) {
            throw context + " must be a boolean";
        }
        return cast value;
    }

    private function _isObject(value:Dynamic):Bool {
        if (value == null
            || Std.isOfType(value, Array)
            || Std.isOfType(value, String)
            || Std.isOfType(value, Int)
            || Std.isOfType(value, Float)
            || Std.isOfType(value, Bool)) {
            return false;
        }
        return Reflect.isObject(value);
    }

    private function _dirname(path:String):String {
        if (path == null) {
            return "";
        }
        var normalized = StringTools.replace(path, "\\", "/");
        var pos = normalized.lastIndexOf("/");
        return pos == -1 ? "" : normalized.substr(0, pos);
    }

    private function _fail(message:String):Void {
        if (_errorReported || _completed) {
            return;
        }

        _errorReported = true;
        _failed = true;
        _effect = null;
        _buildingEffect = null;

        if (_resolver != null) {
            _resolver.dispose();
            _resolver = null;
        }

        _error.execute(this, _resolvedFilename + ": " + message);
    }

    override public function dispose():Void {
        if (_resolver != null) {
            _resolver.dispose();
            _resolver = null;
        }
        _effect = null;
        _buildingEffect = null;
        _assetLibrary = null;
        _filename = "";
        _resolvedFilename = "";
    }
}
