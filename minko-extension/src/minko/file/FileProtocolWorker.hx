package minko.file;
import haxe.io.BytesOutput;
using minko.utils.BytesTool;
import haxe.io.BytesInput;
import minko.utils.MathUtil;
import haxe.io.Bytes;
import minko.async.Worker;
import sys.io.FileInput;
class FileProtocolWorker extends Worker {
    public static function create(name) {
        return new FileProtocolWorker(name);
    }

    public function new(name) {
        super(name);
    }


    override public function run(input:Bytes) {
        var r:BytesInput = new BytesInput(input);
        var seekingOffset = r.readInt32();
        var seekedLength = r.readInt32();
        var filename = r.readUTF();

        var output:BytesOutput = new BytesOutput();

        post({type: "progress", data:0});

        if (sys.FileSystem.exists(filename)) {
            var fileInput:FileInput = sys.io.File.read(filename, true);
            var length = seekedLength > 0 ? seekedLength : (fileInput.tell() - seekingOffset);

            var chunkSize = MathUtil.clp2((length / 50) / 1024);

            if (chunkSize > 1024)
                chunkSize = 1024;
            else if (chunkSize <= 0)
                chunkSize = 8;

            chunkSize *= 1024;

            fileInput.seek(seekingOffset, sys.io.FileSeek.SeekBegin);

            var offset = 0;

            var bytes = Bytes.alloc(chunkSize);
            while (offset < length) {
                var nextOffset = offset + chunkSize;
                var readSize = chunkSize;

                if (nextOffset > length)
                    readSize = length % chunkSize;

                // output = Bytes.alloc(offset + readSize);

                fileInput.readBytes(bytes, offset, readSize);
                output.writeBytes(bytes, offset, readSize)
                //file.read(&*output.begin() + offset, readSize);

                var progress = (offset + readSize) / (length);

                progress *= 100.0;

                post({type: "progress", data:progress});

                offset = nextOffset;
            }

            fileInput.close();

            post({ type:"complete", data:output });
        }
        else {
            post({ type:"error", data:"" });
        }
    }

}