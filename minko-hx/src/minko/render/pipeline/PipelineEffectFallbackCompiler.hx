package minko.render.pipeline;

import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

/**
 * Adapts a multi-output MRT GBuffer technique to the three single-output
 * stages used by GBufferFallbackRenderer.
 *
 * Only simple top-level `gl_FragData[N] = expr;` assignments are supported.
 * If the shader uses gl_FragData in control flow, the compiler returns null and
 * the fallback renderer keeps the PBR G-buffer path for that item.
 */
class PipelineEffectFallbackCompiler {
    private var _cache:ObjectMap<PipelineEffect, FallbackVariants>;

    public function new() {
        _cache = new ObjectMap<PipelineEffect, FallbackVariants>();
    }

    public function variants(effect:PipelineEffect):Array<PipelineTechnique> {
        if (effect == null) {
            return null;
        }

        var technique = effect.techniqueFor(EffectStage.GBuffer);
        if (technique == null) {
            return null;
        }

        var cached = _cache.get(effect);
        if (cached != null && cached.source == technique.fragmentSource && cached.macroVersion == technique.macroVersion) {
            return cached.techniques;
        }

        var transformed = _split(technique);
        if (transformed == null) {
            return null;
        }

        var entry = new FallbackVariants(technique.fragmentSource, technique.macroVersion, transformed);
        _cache.set(effect, entry);
        return transformed;
    }

    public function clear():Void {
        _cache = new ObjectMap<PipelineEffect, FallbackVariants>();
    }

    private function _split(technique:PipelineTechnique):Array<PipelineTechnique> {
        var source = technique.fragmentSource;
        var regexp = ~/gl_FragData\s*\[\s*([0-9]+)\s*\]\s*=\s*([^;]+);/;
        var matches:Array<{index:Int, expression:String, start:Int, length:Int}> = [];

        var offset = 0;
        for (line in source.split("\n")) {
            if (regexp.match(line)) {
                var position = regexp.matchedPos();
                matches.push({
                    index: Std.parseInt(regexp.matched(1)),
                    expression: regexp.matched(2),
                    start: offset + position.pos,
                    length: position.len
                });
            }
            offset += line.length + 1;
        }

        if (matches.length == 0) {
            return null;
        }

        var result:Array<PipelineTechnique> = [];
        for (attachment in 0...3) {
            var buffer = new StringBuf();
            var cursor = 0;
            var found = false;
            for (match in matches) {
                buffer.add(source.substr(cursor, match.start - cursor));
                if (match.index == attachment) {
                    buffer.add("gl_FragColor = " + match.expression + ";");
                    found = true;
                }
                cursor = match.start + match.length;
            }
            buffer.add(source.substr(cursor));

            var variantSource = buffer.toString();
            if (!found) {
                return null;
            }
            if (variantSource.indexOf("gl_FragData") >= 0) {
                return null;
            }

            var macros = new StringMap<String>();
            for (key in technique.macros.keys()) {
                macros.set(key, technique.macros.get(key));
            }
            var stage = attachment == 0 ? EffectStage.GBufferAlbedo
                : attachment == 1 ? EffectStage.GBufferNormal
                : EffectStage.GBufferEmissive;
            var variant = new PipelineTechnique(stage, technique.vertexSource, variantSource,
                technique.uniforms, technique.state, technique.name + ":fallback" + attachment, macros);
            variant.macroVersion = technique.macroVersion;
            result.push(variant);
        }

        return result;
    }
}

private class FallbackVariants {
    public var source:String;
    public var macroVersion:Int;
    public var techniques:Array<PipelineTechnique>;

    public function new(source:String, macroVersion:Int, techniques:Array<PipelineTechnique>) {
        this.source = source;
        this.macroVersion = macroVersion;
        this.techniques = techniques;
    }
}
