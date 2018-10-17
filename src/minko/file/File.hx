package minko.file;
import haxe.io.Bytes;

class File {

    public var _filename:String;

    public var _data:Bytes;
    public var _resolvedFilename:String;

    public static function create() {
        return new File();
    }
    public var filename(get, set):String;

    function get_filename() {
        return _filename;
    }

    function set_filename(v) {
        _filename = v;
        return v;
    }
    public var resolvedFilename(get, set):String;

    function get_resolvedFilename() {
        return _resolvedFilename;
    }

    function set_resolvedFilename(v) {
        _resolvedFilename = v;
        return v;
    }
    public var data(get, null):Bytes;

    function get_data() {
        return _data;
    }

    public static function getCurrentWorkingDirectory() {
        return ".";
    }

    public static function getBinaryDirectory() {
        return ".";
    }

    public static function sanitizeFilename(filename) {


        var f:String = StringTools.replace(filename, "\\", "/");

        return f;
    }

    public static function canonizeFilename(filename:String) {
        var r = new EReg("[\\/]", "ig");

        var segments = r.split(filename);

        // Moving path into a stack (but using deque for later iterative access).
        var path = [];

        for (current in segments) {
            if (StringTools.trim(current) == "" || current == ".") {
                continue;
            }
            if (current != "..") {
                path.push(current);
            }
            else if (path.length > 0 && path[path.length - 1] != "..") {
                path.pop();
            }
            else {
                path.push(current);
            }
        }

        // Keep leading '/' if absolute and reset stream.
        var ss = (filename.length > 0 && filename.charAt(0) == '/' ? "/" : "");

        // Recompose path.
        var output:String = ss + path.join("/");

        // Remove trailing '/' inserted by ostream_iterator.
        if (path.length != 0) {
            output = output.substr(0, output.length);
        }

        // Relative to nothing means relative to current directory.
        if (output.length == 0) {
            output = ".";
        }

        return output;
    }

    public static function removePrefixPathFromFilename(filename) {
        var cleanFilename = sanitizeFilename(filename);
        var filenameWithoutPrefixPath:String = cleanFilename;
        var lastSeparatorPosition = filenameWithoutPrefixPath.lastIndexOf("/");
        if (lastSeparatorPosition != -1) {
            filenameWithoutPrefixPath = filenameWithoutPrefixPath.substr(lastSeparatorPosition + 1);
        }
        return filenameWithoutPrefixPath;
    }

    public static function extractPrefixPathFromFilename(filename) {
        var cleanFilename = sanitizeFilename(filename);

        var prefixPath:String = cleanFilename;

        var lastSeparatorPosition = prefixPath.lastIndexOf("/");

        if (lastSeparatorPosition != -1) {
            prefixPath = prefixPath.substr(0, lastSeparatorPosition);
        }
        else {
            return "";
        }

        return prefixPath;
    }

    public static function getExtension(filename:String) {
        var extension = "";
        var lastDotPosition = filename.lastIndexOf(".");
        if (lastDotPosition != -1) {
            extension = filename.substr(lastDotPosition + 1);
            extension = extension.toLowerCase();
        }
        return extension;
    }

    public static function replaceExtension(filename, extension) {
        var transformedFilename:String = filename;
        var lastDotPosition = transformedFilename.lastIndexOf(".");
        if (lastDotPosition != -1) {
            var previousExtension = transformedFilename.substr(lastDotPosition + 1);
            transformedFilename = transformedFilename.substr(0, transformedFilename.length - (previousExtension.length + 1));
        }
        transformedFilename += "." + extension;
        return transformedFilename;
    }

    public function new() {
    }
}
