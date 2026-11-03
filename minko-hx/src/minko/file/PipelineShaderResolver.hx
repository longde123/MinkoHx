package minko.file;

import haxe.ds.StringMap;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import StringBuf;

/**
 * Resolves external shader files and #pragma include directives for
 * PipelineEffectParser.
 *
 * Each file is loaded through a dedicated Loader created from a cloned Options
 * whose include paths start with the directory of the including file. Includes
 * are expanded recursively, cached by resolved filename, and checked for
 * cycles.
 */
class PipelineShaderResolver {
    private static var _includePattern = new EReg("^#[ \\t]*pragma[ \\t]+include[ \\t]+[\"']([^\"']+)[\"'][ \\t]*$", "");

    private var _options:Options;
    private var _onError:String->Void;
    private var _fallbackAssetLibrary:AssetLibrary;
    private var _includeCache:StringMap<String>;
    private var _completeSlots:Array<SignalSlot<Loader>>;
    private var _errorSlots:Array<SignalSlot2<Loader, String>>;
    private var _failed:Bool;
    private var _disposed:Bool;

    public function new(options:Options, onError:String->Void) {
        _options = options != null ? options : Options.empty();
        _onError = onError;
        _fallbackAssetLibrary = null;
        _includeCache = new StringMap<String>();
        _completeSlots = [];
        _errorSlots = [];
        _failed = false;
        _disposed = false;
    }

    public function resolveInline(source:String, baseDir:String, done:String->Void):Void {
        if (_failed || _disposed) {
            return;
        }
        if (source == null) {
            _fail("shader source is null");
            return;
        }
        _resolveSource(source, baseDir, [], done);
    }

    public function resolveFile(filename:String, baseDir:String, done:String->Void):Void {
        if (_failed || _disposed) {
            return;
        }
        _loadFile(filename, baseDir, "shader", function(content:String, resolvedFilename:String) {
            if (_failed || _disposed) {
                return;
            }
            _resolveSource(content, _dirname(resolvedFilename), [resolvedFilename], done);
        });
    }

    private function _resolveSource(source:String, baseDir:String, stack:Array<String>, done:String->Void):Void {
        if (_failed || _disposed) {
            return;
        }
        var lines = source.split("\n");
        _expandLines(lines, 0, new StringBuf(), baseDir, stack, done);
    }

    private function _expandLines(lines:Array<String>, index:Int, output:StringBuf, baseDir:String,
                                  stack:Array<String>, done:String->Void):Void {
        if (_failed || _disposed) {
            return;
        }
        if (index >= lines.length) {
            done(output.toString());
            return;
        }

        var line = lines[index];
        var include = _parseInclude(line);
        if (include == null) {
            output.add(line);
            if (index + 1 < lines.length) {
                output.add("\n");
            }
            _expandLines(lines, index + 1, output, baseDir, stack, done);
            return;
        }

        _loadInclude(include, baseDir, stack, function(expanded:String) {
            if (_failed || _disposed) {
                return;
            }
            output.add(expanded);
            if (expanded.length > 0 && expanded.charAt(expanded.length - 1) != "\n") {
                output.add("\n");
            }
            _expandLines(lines, index + 1, output, baseDir, stack, done);
        });
    }

    private function _loadInclude(filename:String, baseDir:String, stack:Array<String>, done:String->Void):Void {
        if (_failed || _disposed) {
            return;
        }

        _loadFile(filename, baseDir, "include", function(content:String, resolvedFilename:String) {
            if (_failed || _disposed) {
                return;
            }

            var key = _canonical(resolvedFilename);
            if (stack.indexOf(key) != -1) {
                var chain = stack.concat([key]).join(" -> ");
                _fail("recursive #pragma include: " + chain);
                return;
            }

            if (_includeCache.exists(key)) {
                done(_includeCache.get(key));
                return;
            }

            _resolveSource(content, _dirname(resolvedFilename), stack.concat([key]), function(expanded:String) {
                if (_failed || _disposed) {
                    return;
                }
                _includeCache.set(key, expanded);
                done(expanded);
            });
        });
    }

    private function _loadFile(filename:String, baseDir:String, kind:String,
                              callback:String->String->Void):Void {
        if (_failed || _disposed) {
            return;
        }

        var loadOptions = _makeOptions(baseDir);
        var loader = Loader.createbyOptions(loadOptions);

        var completeSlot = loader.complete.connect(function(l:Loader) {
            if (_failed || _disposed) {
                return;
            }
            var file:File = l.files.get(filename);
            if (file == null || file.data == null) {
                _fail("unable to read " + kind + " '" + filename + "'");
                return;
            }

            var content = file.data.toString();
            if (content.length > 0 && content.charCodeAt(0) == 0xFEFF) {
                content = content.substr(1);
            }

            var resolvedFilename = file.resolvedFilename;
            if (resolvedFilename == null || resolvedFilename == "") {
                resolvedFilename = filename;
            }
            callback(content, resolvedFilename);
        });

        var errorSlot = loader.error.connect(function(_:Loader, message:String) {
            _fail("unable to load " + kind + " '" + filename + "': " + message);
        });

        _completeSlots.push(completeSlot);
        _errorSlots.push(errorSlot);

        loader.queue(filename).load();
    }

    private function _makeOptions(baseDir:String):Options {
        var copy = _options.clone();
        var paths = [];
        if (baseDir != null && baseDir != "") {
            paths.push(baseDir);
        }
        for (path in copy.includePaths) {
            paths.push(path);
        }
        copy.includePaths = paths;

        // Shader files have no dedicated parser. Always keep the loader's
        // "store as blob" path enabled so the load can complete, even when the
        // caller disabled it for general assets.
        copy.storeDataIfNotParsed = true;

        if (copy.assetLibrary == null) {
            if (_fallbackAssetLibrary == null) {
                _fallbackAssetLibrary = AssetLibrary.create(copy.context);
            }
            copy.assetLibrary = _fallbackAssetLibrary;
        }
        return copy;
    }

    private function _parseInclude(line:String):String {
        var trimmed = StringTools.trim(line);
        if (trimmed.length == 0 || trimmed.charAt(0) != "#") {
            return null;
        }
        if (trimmed.indexOf("//") == 0) {
            return null;
        }
        if (!_includePattern.match(trimmed)) {
            return null;
        }
        return _includePattern.matched(1);
    }

    private function _canonical(path:String):String {
        return StringTools.replace(path, "\\", "/");
    }

    private function _dirname(path:String):String {
        var normalized = _canonical(path);
        var pos = normalized.lastIndexOf("/");
        return pos == -1 ? "" : normalized.substr(0, pos);
    }

    private function _fail(message:String):Void {
        if (_failed || _disposed) {
            return;
        }
        _failed = true;
        _disposeSlots();
        if (_onError != null) {
            _onError(message);
        }
    }

    private function _disposeSlots():Void {
        for (slot in _completeSlots) {
            if (slot != null) {
                slot.dispose();
            }
        }
        _completeSlots = [];
        for (slot in _errorSlots) {
            if (slot != null) {
                slot.dispose();
            }
        }
        _errorSlots = [];
    }

    public function dispose():Void {
        _disposed = true;
        _failed = true;
        _disposeSlots();
        _includeCache = null;
        _options = null;
        _onError = null;
        _fallbackAssetLibrary = null;
    }
}
