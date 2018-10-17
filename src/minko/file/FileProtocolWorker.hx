package minko.file;
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
        var seekingOffset = (input.get(0) << 24) +
        (input.get(1) << 16) +
        (input.get(2) << 8) +
        (input.get(3));

        var seekedLength = ( input.get(4) << 24) +
        ( input.get(5) << 16) +
        ( input.get(6) << 8) +
        (input.get(7));

        var filename = input.getString(8, input.length - 8);

        var output:Bytes;

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

            while (offset < length) {
                var nextOffset = offset + chunkSize;
                var readSize = chunkSize;

                if (nextOffset > length)
                    readSize = length % chunkSize;

                output = Bytes.alloc(offset + readSize);

                var bytes = fileInput.readBytes(readSize);
                output.blit(offset, bytes, readSize)
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
