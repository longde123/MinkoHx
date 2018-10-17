package minko.file;
import haxe.io.Bytes;
import minko.async.WorkerImpl;
import minko.utils.MathUtil;
import sys.io.FileInput;
import sys.io.FileSeek;
class APKProtocolWorker extends WorkerImpl {
    public function new() {
    }

    override public function start(input:Bytes) {
        run(input);
    }

    public function run(inputStream:Bytes):Void {
        var seekingOffset = inputStream.getInt32(0);
        var seekedLength = inputStream.getInt32(4);
        var filename = inputStream.getString(8, inputStream.length - 8);
        var output:Bytes = null;
        post({ type:"progress", data:0.0});
        var file:FileInput = sys.io.File.read(filename, true);
        if (file != null) {
            var length = seekedLength > 0 ? seekedLength : (file.tell() - seekingOffset);
            var chunkSize = MathUtil.clp2((length / 50) / 1024);
            if (chunkSize > 1024)
                chunkSize = 1024;
            else if (chunkSize <= 0)
                chunkSize = 8;
            chunkSize *= 1024;
            output = Bytes.alloc(length);
            file.seek(seekingOffset, FileSeek.SeekBegin);
            var offset = 0;
            while (offset < length) {
                var nextOffset = offset + chunkSize;
                var readSize = chunkSize;
                if (nextOffset > length)
                    readSize = length % chunkSize;
                // output.resize(offset + readSize);
                var _output = file.read(readSize);
                output.blit(offset, _output, 0, readSize);
                var progress = (offset + readSize) / (length);
                progress *= 100.0;
                post({ type:"progress", data:progress});
                offset = nextOffset;
            }
            file.close();
            post({ type:"complete", data:output});
        }
        else {
            post({ type:"error", data:""});
        }
    }
}
