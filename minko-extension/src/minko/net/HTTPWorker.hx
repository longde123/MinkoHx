package minko.net;
import haxe.io.Bytes;
import minko.async.WorkerImpl;
class HTTPWorker extends WorkerImpl {
    public function new() {
        super();
    }

    override public function start(input:Bytes) {

        run(input);
    }

    public function run(inputStream:Bytes):Void {
        /*
        var index = 0;
        var usernameSize = 0;
        var passwordSize = 0;
        var numAdditionalHeaders = 0;
        var verifyPeer = true;
        var urlSize = inputStream.getInt32(index);
        index += 4;
        var urlData:String = "";
        if (urlSize > 0)
            urlData = inputStream.getString(index, urlSize);
        index += urlSize;
        usernameSize = inputStream.getInt32(index);
        index += 4;
        var usernameData:String = "";
        if (usernameSize > 0)
            usernameData = inputStream.getString(index, usernameSize);
        index += usernameSize;

        passwordSize = inputStream.getInt32(index);
        index += 4;
        var passwordData = "";

        if (passwordSize > 0)
            passwordData = inputStream.getString(index, passwordSize);
        index += passwordSize;
        var url = urlData ;
        var username = usernameData ;
        var password = passwordData ;

        numAdditionalHeaders = inputStream.getInt32(index);

        var additionalHeaders = [];

        for (i in 0...numAdditionalHeaders) {
            var keySize = inputStream.getInt32(index);
            index += 4;
            var valueSize = inputStream.getInt32(index);
            index += 4;
            var keyData = "";
            if (keySize > 0)
                keyData = inputStream.getString(index, keySize);
            index += keySize;
            var valueData = "";
            if (valueSize > 0)
                valueData = inputStream.getString(index, valueSize);
            index += valueSize;
            additionalHeaders.push(new Tuple<String, String>( keyData, valueData ));
        }

        verifyPeer = inputStream.get(index);

        var request = new HTTPRequest(url, username, password, additionalHeaders );

        request.verifyPeer = (verifyPeer);

        var _0 = request.progress.connect(function(p) {

            post({ type:"progress", value:p });
        });

        var _1 = request.error.connect(function(e, errorMessage) {
            post({ type:"progress", value:errorMessage });
        });

        var _2 = request.complete.connect(function(output) {

            post({ type:"progress", value:output });
        });

        request.run();
        */
    }
}
