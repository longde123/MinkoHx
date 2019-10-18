package minko.net;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.Json;
import js.html.Uint8Array;
import js.html.XMLHttpRequest;
import js.html.XMLHttpRequestResponseType;
import minko.file.AbstractProtocol;
import minko.file.Options.FileStatus;
import Reflect;
import String;
@:expose("minko.net.WebHTTPProtocol")
class WebHTTPProtocol extends AbstractProtocol {
    private var _workerSlots:Array<Any>;
    var _handle:Int;
    static var _httpProtocolReferences:Array<AbstractProtocol> = [];
    var _status:FileStatus;

    public static function create():WebHTTPProtocol {

        return new WebHTTPProtocol() ;
    }

    public function new() {
        super();
        _status = FileStatus.Pending;
    }

    function wget2CompleteHandler(id, arg:WebHTTPProtocol, data, size) {
        arg.completeHandler(data);
    }

    function wget2ErrorHandler(id, arg:WebHTTPProtocol, code, message) {
        arg.errorHandler(code, message);
    }

    function wget2ProgressHandler(id, arg:WebHTTPProtocol, loadedBytes, totalBytes) {
        arg.progressHandler(loadedBytes, totalBytes);
    }

    override public function load() {
        _httpProtocolReferences.push(this);

        _options.protocolFunction = function(filename) {
            return function() {
                return new WebHTTPProtocol ();
            };
        };

        progress.execute(this, 0.0);

        var username:Bytes = null;
        var password:Bytes = null;
        var additionalHeaders = new Array<Tuple<String, String>>();
        var verifyPeer = true;


        if (Std.is(_options, HTTPOptions)) {
            var httpOptions:HTTPOptions = cast(_options, HTTPOptions);
            username = Bytes.ofString(httpOptions.username);
            password = Bytes.ofString(httpOptions.password);

            additionalHeaders = httpOptions.additionalHeaders;

            verifyPeer = httpOptions.verifyPeer;
        }

        var seekingOffset = _options.seekingOffset;
        var seekedLength = _options.seekedLength;

        if (seekingOffset >= 0 && seekedLength > 0) {
            var rangeMin = Std.string(seekingOffset);
            var rangeMax = Std.string(seekingOffset + seekedLength - 1);

            additionalHeaders.push(new Tuple<String, String>( "Range", "bytes=" + rangeMin + "-" + rangeMax ));
        }
        if (options.loadAsynchronously) {
            var additionalHeadersJsonString = "";
            if (additionalHeaders.length != 0) {
                var additionalHeaderCount = 0;

                additionalHeadersJsonString += "{ ";

                for (additionalHeader in additionalHeaders) {
                    additionalHeadersJsonString += ("\"" + additionalHeader.first + "\" : \"" + additionalHeader.second + "\"");

                    if (additionalHeaderCount < additionalHeaders.length - 1)
                        additionalHeadersJsonString += ", ";

                    ++additionalHeaderCount;
                }

                additionalHeadersJsonString += " }";
            }

            _handle =  EmscriptenAsync.emscripten_async_wget3_data(
                resolvedFilename,
                "GET",
                "",
                additionalHeadersJsonString,
                this,
                true,
                wget2CompleteHandler,
                wget2ErrorHandler,
                wget2ProgressHandler
            );
        }
        else {

            var xhr = new XMLHttpRequest();
            xhr.open('GET', resolvedFilename, false);
            xhr.overrideMimeType('text/plain; charset=x-user-defined');
            for (additionalHeader in additionalHeaders) {
                xhr.setRequestHeader(additionalHeader.first, additionalHeader.second);
            }

            xhr.send(null);
            var size = -1;
            var bytes:Bytes = null;

            if ((xhr.readyState == 4 && xhr.status == 0)
            || (xhr.status == 200 || xhr.status == 206)) {
                var array = new Uint8Array(xhr.responseText.length);
                for (i in 0...xhr.responseText.length)
                    array[i] = xhr.responseText.charCodeAt(i) & 0xFF;
                bytes = Bytes.ofData(array.buffer);
                size = (xhr.responseText.length);
            }
            else {
                size = (-1);
            }

            if (size >= 0) {
                completeHandler(bytes);
                // trace(resolvedFilename+"\n");
                // trace(bytes.toString());
            }
            else {
                errorHandler(0, "");
            }
        }

    }

    override public function fileExists(filename) {
        var username = "";
        var password = "";
        var additionalHeaders = new Array<Tuple<String, String>>();
        var verifyPeer = true;

        if (Std.is(_options, HTTPOptions)) {
            var httpOptions:HTTPOptions = cast(_options);
            username = httpOptions.username;
            password = httpOptions.password;

            additionalHeaders = httpOptions.additionalHeaders;

            verifyPeer = httpOptions.verifyPeer;
        }
        additionalHeaders.push(new Tuple<String, String>("Access-Control-Allow-Methods", "GET, POST,PUT"));
        var xhr = new XMLHttpRequest();

        xhr.open('HEAD', filename, false);

        if (additionalHeaders != null) {
            for (additionalHeader in additionalHeaders) {
                if (additionalHeader.first == "")
                    continue;

                xhr.setRequestHeader(additionalHeader.first, additionalHeader.second);
            }
        }
        try {
            xhr.send(null);
        } catch (e:Any) {
            return false;
            trace(e);
        }

        var status = xhr.status;

        return (xhr.readyState == 4 && xhr.status == 0)
        || (status >= 200 && status < 300);


    }

    override public function isAbsolutePath(filename:String) {
        return filename.indexOf("://") != -1;
    }

    function completeHandler(data) {
        if (_status == FileStatus.Aborted)
            return;

        this.data = (data);

        progress.execute(this, 1.0);
        complete.execute(this);

        _httpProtocolReferences.remove(this);

    }

    function errorHandler(code, message = "") {
        //LOG_ERROR(message);

        error.execute(this, message);

        _httpProtocolReferences.remove(this);
    }

    function progressHandler(loadedBytes, totalBytes) {
        if (_status == FileStatus.Aborted)
            return;

        var progress = 0.0;

        if (totalBytes != 0)
            progress = (loadedBytes) / (totalBytes);
        if (options.fileStatusFunction != null) {
            var fileStatus = options.fileStatusFunction(file, progress);

            if (fileStatus == FileStatus.Aborted) {
                _status = FileStatus.Aborted;

                EmscriptenAsync.emscripten_async_wget2_abort(_handle);

                error.execute(this, "");

                return;
            }
        }
        this.progress.execute(this, progress);
    }


}

class   EmscriptenAsync{

    static var nextWgetRequestHandle = 0;
    static var wgetRequests:IntMap<XMLHttpRequest> = new IntMap<XMLHttpRequest>();

    static function getNextWgetRequestHandle() {
        var a = nextWgetRequestHandle;
        nextWgetRequestHandle++;
        return a;
    };

    static public function emscripten_async_wget2_abort(handle) {
        var http = wgetRequests.get(handle);
        if (http != null) {
            http.abort();
        }

    }

    static public function emscripten_async_wget3_data(url, request, param, additionalHeader, arg, free, onload, onerror, onprogress) {
        var _url:String = (url);
        var _request:String = (request);
        var _param:String = (param);

        var http = new XMLHttpRequest();
        http.open(_request, _url, true);
        http.responseType = XMLHttpRequestResponseType.ARRAYBUFFER;

        var handle = getNextWgetRequestHandle();

        // LOAD
        http.onload = function http_onload(e) {
            if (http.status == 200 || http.status == 206 || _url.substr(0, 4).toLowerCase() != "http") {
                var byteArray = new Uint8Array(http.response);
                var buffer = Bytes.ofData(byteArray.buffer);
                if (onload != null) onload(handle, arg, buffer, byteArray.length);
                if (free) buffer = null;
            } else {
                if (onerror != null) onerror(handle, arg, http.status, http.statusText);
            }
            wgetRequests.remove(handle);
        };

        // ERROR
        http.onerror = function http_onerror(e) {
            if (onerror != null) {
                onerror(handle, arg, http.status, http.statusText);
            }
            wgetRequests.remove(handle);
        };

        // PROGRESS
        http.onprogress = function http_onprogress(e) {
            if (onprogress != null) onprogress(handle, arg, e.loaded, e.lengthComputable || e.lengthComputable == null ? e.total : 0);
        };

        // ABORT
        http.onabort = function http_onabort(e) {
            wgetRequests.remove(handle);
        };

        if (additionalHeader != "") {
            var additionalHeaderObject = Json.parse(additionalHeader);
            for (entry in Reflect.fields(additionalHeaderObject)) {
                http.setRequestHeader(entry, Reflect.field(additionalHeaderObject, entry));
            }
        }


        if (_request == "POST") {
            //Send the proper header information along with the request
            http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
            http.setRequestHeader("Content-length", Std.string(_param.length));
            http.setRequestHeader("Connection", "close");
            http.send(_param);
        } else {
            http.send(null);
        }

        wgetRequests.set(handle, http);

        return handle;
    }

}
