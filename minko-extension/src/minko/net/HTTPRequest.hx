package minko.net;
import haxe.io.Bytes;
import minko.signal.Signal2;
import minko.signal.Signal;
class HTTPRequest {
    private var _url:String;
    private var _output:Bytes;
    private var _username:String;
    private var _password:String;
    private var _additionalHeaders:Array<Tuple<String, String>>;
    private var _verifyPeer:Bool;
    private var _progress:Signal<Float> ;
    private var _error:Signal2<Int, String>;
    private var _complete:Signal<Bytes>;

    public var verifyPeer(null, set):Bool;

    function set_verifyPeer(value) {
        _verifyPeer = value;
        return value;
    }
    public var output(get, null):Bytes;

    function get_output() {
        return _output;
    }

    private var progress(get, null):Signal<Float> ;

    function get_progress() {
        return _progress;
    }

    private var error(get, null):Signal2<Int, String>;

    function get_error() {
        return _error;
    }

    private var complete(get, null):Signal<Bytes>;

    function get_complete() {
        return _complete;
    }

    public function new(url, username = "", password = "", additionalHeaders = null) {

    }

    public function run() {

    }

    static public function fileExists(filename:String, username:String, password:String, additionalHeaders:Array<Tuple<String, String>>, verifyPeer:Bool) {
        return false;
    }
}
