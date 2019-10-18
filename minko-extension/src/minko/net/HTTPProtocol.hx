package minko.net;
import haxe.io.Bytes;
import minko.async.Worker;
import minko.async.WorkerImpl.Message;
import minko.file.AbstractProtocol;
import minko.file.Options.FileStatus;
class HTTPProtocol extends AbstractProtocol {
    private var _workerSlots:Array<Any>;

    static var _httpProtocolReferences:Array<AbstractProtocol> = [];

    var _status:FileStatus;

    public static function create():HTTPProtocol {
        return new HTTPProtocol() ;
    }

    public function new() {
        super();
        _status = FileStatus.Pending;
    }

    override public function load() {
        _httpProtocolReferences.push(this);

        _options.protocolFunction = function(filename) {
            return function() {
                return new HTTPProtocol ();
            };
        };

        progress.execute(this, 0.0);

        var username:Bytes = null;
        var password:Bytes = null;
        var additionalHeaders = new Array<Tuple<String, String>>();
        var verifyPeer = true;

        var httpOptions:HTTPOptions = (_options);

        if (httpOptions != null) {
            username = httpOptions.username;
            password = httpOptions.password;

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
            var worker = AbstractCanvas.defaultCanvas.getWorker("http");

            _workerSlots.push(worker.message.connect(function(w:Worker, message:Message) {
                if (message.type == "complete") {
                    completeHandler(message.data);
                }
                else if (message.type == "progress") {
                    var ratio = message.data ;
                    progressHandler(ratio * 100, 100);
                }
                else if (message.type == "error") {
                    errorHandler();
                }
            }));

            var offset = _options.seekingOffset;
            var length = _options.seekedLength;

            var inputStream:Bytes = Bytes.alloc(256);

            var resolvedFilename:Bytes = this.resolvedFilename;
            var resolvedFilenameSize = resolvedFilename.length;

            var usernameSize = username.length;
            var passwordSize = password.length;

            var numAdditionalHeaders = additionalHeaders.length;
            var index = 0;

            inputStream.setInt32(index, resolvedFilenameSize);
            index += 4;
            if (resolvedFilenameSize > 0)
                inputStream.blit(index, resolvedFilename, 0, resolvedFilenameSize);
            index += resolvedFilenameSize;

            inputStream.setInt32(index, usernameSize);
            index += 4;
            if (usernameSize > 0)
                inputStream.blit(index, username, 0, usernameSize);
            index += usernameSize;

            inputStream.setInt32(index, passwordSize);
            index += 4;
            if (passwordSize > 0)
                inputStream.blit(index, password, passwordSize);
            index += passwordSize;


            inputStream.setInt32(index, numAdditionalHeaders);
            index += 4;
            for (additionalHeader in additionalHeaders) {
                var key:Bytes = additionalHeader.first;
                var value:Bytes = additionalHeader.second;

                var keySize = key.length;
                var valueSize = value.length;

                inputStream.setInt32(index, keySize);
                index += 4;
                inputStream.setInt32(index, valueSize);
                index += 4;
                if (keySize > 0) {
                    inputStream.blit(index, key, 0, keySize);
                    index += keySize;
                }
                if (valueSize > 0) {
                    inputStream.blit(index, value, 0, valueSize);
                    index += valueSize;
                }
            }
            inputStream.set(index, verifyPeer);
            worker.start(inputStream);
        }
        else {
            var request:HTTPRequest = new HTTPRequest(resolvedFilename, username, password, additionalHeaders);

            request.verifyPeer = (verifyPeer);

            var requestIsSuccessfull = true;

            var requestErrorSlot = request.error.connect(function(error, errorMessage) {
                requestIsSuccessfull = false;

                this.error.execute(this);
            });

            var requestProgressSlot = request.progress.connect(function(p) {
                progressHandler(p * 100, 100);
            });

            request.run();

            if (requestIsSuccessfull) {
                var output = request.output;

                completeHandler(output);
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
        return HTTPRequest.fileExists(filename, username, password, additionalHeaders, false);
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
        this.progress.execute(this, progress);
    }
}
