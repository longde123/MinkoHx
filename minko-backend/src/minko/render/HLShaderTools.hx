package minko.render;

import haxe.ds.StringMap;

class HLUniformDecl {
    public var name:String;
    public var type:String;
    public var arraySize:Int;
    public var isArray:Bool;

    public function new(name:String, type:String, arraySize:Int, isArray:Bool) {
        this.name = name;
        this.type = type;
        this.arraySize = arraySize;
        this.isArray = isArray;
    }
}

/**
 * HashLink/OpenGL compatibility helpers.
 *
 * hlsdl only exposes `glUniform1i`, `glUniform4fv` and `glUniformMatrix4fv`.
 * To support the scalar/vec2/vec3/int/bool uniforms used by Minko effects, the
 * GLSL source is rewritten so those uniforms are declared as vec4 and every use
 * is wrapped in a swizzle/cast. The original source is still used for reflection
 * so DrawCall keeps sending the original value types.
 */
class HLShaderTools {

    static var REWRITABLE_TYPES = ["float", "vec2", "vec3", "int", "ivec2", "ivec3", "ivec4", "bool", "bvec2", "bvec3", "bvec4"];

    public static function isRewritable(type:String):Bool {
        return Lambda.has(REWRITABLE_TYPES, type);
    }

    static function stripComments(s:String):String {
        var out = new StringBuf();
        var i = 0;
        var n = s.length;
        var inLine = false;
        var inBlock = false;
        while (i < n) {
            var c = s.charAt(i);
            var c2 = i + 1 < n ? s.charAt(i + 1) : "";
            if (inLine) {
                if (c == "\n") {
                    inLine = false;
                    out.add(c);
                }
                i++;
                continue;
            }
            if (inBlock) {
                if (c == "*" && c2 == "/") {
                    inBlock = false;
                    i += 2;
                }
                else {
                    if (c == "\n") out.add(c);
                    i++;
                }
                continue;
            }
            if (c == "/" && c2 == "/") {
                inLine = true;
                i += 2;
                continue;
            }
            if (c == "/" && c2 == "*") {
                inBlock = true;
                i += 2;
                continue;
            }
            out.add(c);
            i++;
        }
        return out.toString();
    }

    static function collectDefines(source:String):StringMap<String> {
        var defines = new StringMap<String>();
        var re = new EReg("#define[ \\t]+([A-Za-z_][A-Za-z0-9_]*)[ \\t]+([^\\r\\n]+)", "g");
        re.map(source, function(e:EReg):String {
            var name = e.matched(1);
            var value = StringTools.trim(e.matched(2));
            if (!defines.exists(name)) defines.set(name, value);
            return "";
        });
        return defines;
    }

    static function resolveInt(expr:String, defines:StringMap<String>, depth = 0):Int {
        if (depth > 8) return -1;
        expr = StringTools.trim(expr);
        while (expr.length >= 2 && expr.charAt(0) == "(" && expr.charAt(expr.length - 1) == ")") {
            expr = StringTools.trim(expr.substr(1, expr.length - 2));
        }
        if (expr == "") return -1;
        if (defines.exists(expr)) return resolveInt(defines.get(expr), defines, depth + 1);
        if (new EReg("^-?[0-9]+$", "").match(expr)) return Std.parseInt(expr);
        return -1;
    }

    static function parseDeclarators(body:String, defines:StringMap<String>, type:String, out:Array<HLUniformDecl>):Bool {
        var ok = true;
        for (part in body.split(",")) {
            var decl = StringTools.trim(part);
            if (decl == "") continue;
            var re = new EReg("^([A-Za-z_][A-Za-z0-9_]*)[ \\t\\r\\n]*(?:\\[([^\\]]+)\\])?$", "");
            if (!re.match(decl)) {
                ok = false;
                continue;
            }
            var name = re.matched(1);
            var sizeExpr = re.matched(2);
            var size = sizeExpr == null ? 1 : resolveInt(sizeExpr, defines);
            if (size == 0) size = -1;
            out.push(new HLUniformDecl(name, type, size, sizeExpr != null));
        }
        return ok;
    }

    public static function parseUniforms(rawSource:String, recursiveIncludes = false):Array<HLUniformDecl> {
        var source = stripComments(rawSource);
        var defines = collectDefines(source);
        var uniforms = new Array<HLUniformDecl>();
        var seen = new StringMap<Bool>();
        var re = new EReg("uniform[ \\t\\r\\n]+(?:(?:lowp|mediump|highp)[ \\t\\r\\n]+)?([A-Za-z_][A-Za-z0-9_]*)[ \\t\\r\\n]+([^;]+);", "g");
        re.map(source, function(e:EReg):String {
            var type = e.matched(1);
            if (type == "struct") return "";
            var body = e.matched(2);
            var tmp = new Array<HLUniformDecl>();
            parseDeclarators(body, defines, type, tmp);
            for (u in tmp) {
                if (!seen.exists(u.name)) {
                    seen.set(u.name, true);
                    uniforms.push(u);
                }
            }
            return "";
        });
        return uniforms;
    }

    public static function parseAttributes(rawSource:String):Array<String> {
        var source = stripComments(rawSource);
        var attributes = new Array<String>();
        var seen = new StringMap<Bool>();
        var re = new EReg("attribute[ \\t\\r\\n]+(?:(?:lowp|mediump|highp)[ \\t\\r\\n]+)?([A-Za-z_][A-Za-z0-9_]*)[ \\t\\r\\n]+([A-Za-z_][A-Za-z0-9_]*)", "g");
        re.map(source, function(e:EReg):String {
            var name = e.matched(2);
            if (!seen.exists(name)) {
                seen.set(name, true);
                attributes.push(name);
            }
            return "";
        });
        return attributes;
    }

    static function accessorFor(type:String):String {
        return switch (type) {
            case "float", "int", "bool": ".x";
            case "vec2", "ivec2", "bvec2": ".xy";
            case "vec3", "ivec3", "bvec3": ".xyz";
            case "ivec4", "bvec4": ".xyzw";
            default: "";
        };
    }

    static function wrapFor(type:String, matched:String):String {
        return switch (type) {
            case "float": "(" + matched + ".x)";
            case "vec2": "(" + matched + ".xy)";
            case "vec3": "(" + matched + ".xyz)";
            case "int": "int(" + matched + ".x)";
            case "ivec2": "ivec2(" + matched + ".xy)";
            case "ivec3": "ivec3(" + matched + ".xyz)";
            case "ivec4": "ivec4(" + matched + ".xyzw)";
            case "bool": "(" + matched + ".x != 0.0)";
            case "bvec2": "bvec2(" + matched + ".xy != vec2(0.0))";
            case "bvec3": "bvec3(" + matched + ".xyz != vec3(0.0))";
            case "bvec4": "bvec4(" + matched + ".xyzw != vec4(0.0))";
            default: matched;
        };
    }

    static function escapeEReg(s:String):String {
        // Uniform/attribute names are restricted to [A-Za-z_][A-Za-z0-9_]*,
        // so they never contain regex metacharacters.
        return s;
    }

    public static function rewrite(rawSource:String):String {
        var source = stripComments(rawSource);
        var defines = collectDefines(source);

        var rewrites = new Array<{name:String, type:String}>();
        var declarations = new Array<{marker:String, text:String}>();
        var declRe = new EReg("uniform[ \\t\\r\\n]+(?:(?:lowp|mediump|highp)[ \\t\\r\\n]+)?([A-Za-z_][A-Za-z0-9_]*)[ \\t\\r\\n]+([^;]+);", "g");

        var replaced = declRe.map(source, function(e:EReg):String {
            var type = e.matched(1);
            var body = e.matched(2);
            if (!isRewritable(type)) return e.matched(0);

            var tmp = new Array<HLUniformDecl>();
            if (!parseDeclarators(body, defines, type, tmp) || tmp.length == 0) {
                return e.matched(0);
            }
            for (u in tmp) {
                rewrites.push({name: u.name, type: type});
            }
            var marker = "__MINKO_UNIFORM_DECL_" + declarations.length + "__";
            declarations.push({marker: marker, text: "uniform vec4 " + body + ";"});
            return marker;
        });

        // Longest names first so a prefix cannot shadow a longer uniform name.
        rewrites.sort(function(a, b) return b.name.length - a.name.length);

        for (r in rewrites) {
            var re = new EReg("\\b" + escapeEReg(r.name) + "\\b(\\s*\\[[^\\]]*\\])?", "g");
            replaced = re.map(replaced, function(e:EReg):String {
                return wrapFor(r.type, e.matched(0));
            });
        }

        for (d in declarations) {
            replaced = StringTools.replace(replaced, d.marker, d.text);
        }

        // Desktop GL does not need the OES derivative extension, and enabling it
        // can make some drivers reject the shader. Downgrade the texture-lod
        // extension to a warning as well.
        var oes = new EReg("(?m)^[ \\t]*#extension[ \\t]+GL_OES_standard_derivatives[^\\r\\n]*", "g");
        replaced = oes.map(replaced, function(_) return "");
        replaced = StringTools.replace(replaced,
            "#extension GL_EXT_shader_texture_lod : enable",
            "#extension GL_EXT_shader_texture_lod : warn");

        return replaced;
    }
}
