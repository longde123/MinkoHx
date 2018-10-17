package minko.file;
import haxe.io.Bytes;
import minko.async.Worker;
import minko.async.WorkerImpl.Message;
import minko.signal.Signal2.SignalSlot2;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileSeek;
class APKProtocol extends FileProtocol {
    static var _activeInstances:Array<APKProtocol> = [];

    public var _workerSlot:SignalSlot2< Worker, Message>;

    static public function create():APKProtocol {
        return new APKProtocol();
    }

    override public function load() {
        var resolvedFilename = this.resolvedFilename;

        var options = _options;

        var protocolPrefixPosition = resolvedFilename.indexOf("://");

        if (protocolPrefixPosition != -1) {
            resolvedFilename = resolvedFilename.substr(protocolPrefixPosition + 3);
        }

        if (resolvedFilename.indexOf("./") == 0) {
            resolvedFilename = resolvedFilename.substr(2);
        }

        _options = options;

        var file:FileInput = File.read(resolvedFilename, true);

        var loader = this;

        if (file != null) {
            if (_options.loadAsynchronously && AbstractCanvas.defaultCanvas != null && AbstractCanvas.defaultCanvas.isWorkerRegistered("apk-protocol")) {
                file.close();

                var worker = AbstractCanvas.defaultCanvas.getWorker("apk-protocol");
                var instance:APKProtocol = (this);
                _activeInstances.push(this);

                _workerSlot = worker.message.connect(function(UnnamedParameter1:Worker, message:Message) {
                    if (message.type == "complete") {
                        data = message.data;

                        complete.execute(instance);

                        _activeInstances.remove(instance);

                        _workerSlot = null;
                    }
                    else if (message.type == "progress") {
                        // FIXME
                    }
                    else if (message.type == "error") {
                        error.execute(instance);

                        _activeInstances.remove(instance);

                        _workerSlot = null;
                    }
                });

                var offset = options.seekingOffset;
                var length = options.seekedLength;

                var inputStream = Bytes.alloc(256);
                var index = 0;
                inputStream.setInt32(index, offset);
                index += 4;
                inputStream.setInt32(index, length);
                index += 4;
                var resolvedFilenameBytes = Bytes.ofString(resolvedFilename);
                inputStream.blit(index, resolvedFilenameBytes, 0, resolvedFilenameBytes.length);
                index += resolvedFilenameBytes.length;

                worker.start(inputStream);
            }
            else {
                var offset = options.seekingOffset;
                var size = options.seekedLength > 0 ? options.seekedLength : file.tell();

                _progress.execute(this, 0.0);

                file.seek(offset, FileSeek.SeekBegin);
                data = file.read(size);
                file.close();

                _progress.execute(loader, 1.0);

                _complete.execute(this);
            }
        }
        else {
            _error.execute(this);
        }
    }

    override public function fileExists(filename:String) {
        var resolvedFilename:String = filename;

        var protocolPrefixPosition = resolvedFilename.indexOf("://");

        if (protocolPrefixPosition != -1) {
            resolvedFilename = filename.substr(protocolPrefixPosition + 3);
        }

        if (resolvedFilename.indexOf("./") == 0) {
            resolvedFilename = resolvedFilename.substr(2);
        }

        var file = File.read(resolvedFilename, true);

        return file != null;
    }

    override public function isAbsolutePath(filename:String) {
        return filename.indexOf("://") != -1 || filename.indexOf("/") == 0;
    }
}
