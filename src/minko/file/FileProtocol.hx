package minko.file;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import minko.async.Worker;
import minko.async.WorkerImpl.Message;
import minko.signal.Signal2.SignalSlot2;
class FileProtocol extends AbstractProtocol {
    static public function create() {
        return new FileProtocol();
    }
    private static var _runningLoaders:Array<FileProtocol> = [];

    private var _workerSlots:ObjectMap<Worker, SignalSlot2<Worker, Message>> = new ObjectMap<Worker, SignalSlot2<Worker, Message>>();

    override public function load() {
        var loader:FileProtocol = (this);

        _runningLoaders.push(loader);

        var resolvedFilename:String = this.resolvedFilename;
        var options = _options;

        var cleanFilename = resolvedFilename;

        var prefixPosition = resolvedFilename.indexOf("://");

        if (prefixPosition != -1) {
            cleanFilename = resolvedFilename.substr(prefixPosition + 3);
        }


        //本地

        //异步加载逻辑
        if (_options.loadAsynchronously && AbstractCanvas.defaultCanvas != null && AbstractCanvas.defaultCanvas.isWorkerRegistered("file-protocol")) {

            var worker:Worker = AbstractCanvas.defaultCanvas.getWorker("file-protocol");
            _workerSlots.set(worker, worker.message.connect(function(UnnamedParameter1:Worker, message:Message) {
                if (message.type == "complete") {
                    var bytes = message.data ;
                    data = bytes;
                    _complete.execute(loader);
                    _runningLoaders.remove(loader);
                    _workerSlots.get(worker).disconnect();
                    _workerSlots.remove(worker);
                }
                else if (message.type == "progress") {
                    var ratio:Float = message.data ;

                    _progress.execute(loader, ratio);
                }
                else if (message.type == "error") {
                    var err:String = message.data ;
                    _error.execute(loader, err);
                    _complete.execute(loader);
                    _runningLoaders.remove(loader);
                    _workerSlots.get(worker).disconnect();
                    _workerSlots.remove(worker);
                }
            }));

            var offset:Int = options.seekingOffset;
            var length:Int = options.seekedLength;

            var offsetByteArray = [];//(4);
            offsetByteArray[0] = (offset & 0xff000000) >> 24;
            offsetByteArray[1] = (offset & 0x00ff0000) >> 16;
            offsetByteArray[2] = (offset & 0x0000ff00) >> 8;
            offsetByteArray[3] = (offset & 0x000000ff);

            var lengthByteArray = [];//(4);
            lengthByteArray[0] = (length & 0xff000000) >> 24;
            lengthByteArray[1] = (length & 0x00ff0000) >> 16;
            lengthByteArray[2] = (length & 0x0000ff00) >> 8;
            lengthByteArray[3] = (length & 0x000000ff);

            var cleanFilenameByteArray = [];//(4);
            for (i in 0...cleanFilename.length) {
                cleanFilenameByteArray.push(cleanFilename.charCodeAt(i));
            }
            var input:Bytes = Bytes.alloc(8 + cleanFilenameByteArray.length);
            var pos = 0;
            for (v in offsetByteArray) {
                input.set(pos++, v);
            }
            for (v in lengthByteArray) {
                input.set(pos++, v);
            }
            for (v in cleanFilenameByteArray) {
                input.set(pos++, v);
            }
            worker.start(input);
        }
        else {

            #if !js
            if (sys.FileSystem.exists(cleanFilename)) {
                var offset:Int = options.seekingOffset;
                var length:Int = options.seekedLength;
                _progress.execute(this, 0.0);
                //同步加载逻辑 todo
                var file = sys.io.File.read(cleanFilename, true);
                file.seek(offset, sys.io.FileSeek.SeekBegin);
                data = file.read(length);
                file.close();

                // FIXME: use fixed size buffers and call _progress accordin

                _progress.execute(loader, 1.0);

                _complete.execute(this);
                _runningLoaders.remove(loader);
            }
            else {
                _error.execute(this);
            }
            #end
        }
    }

    public override function fileExists(filename) {


        return false;
    }

    public override function isAbsolutePath(filename) {
        var cleanFilename:String = File.sanitizeFilename(filename);

#if MINKO_PLATFORM == MINKO_PLATFORM_WINDOWS
				return cleanFilename.indexOf(":/") != -1;
#else
        return cleanFilename.indexOf("/") == 0;
#end
    }

    public function new() {
        super();
    }
}
