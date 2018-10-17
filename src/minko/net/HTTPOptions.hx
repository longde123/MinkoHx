package minko.net;
import minko.file.Options;
class HTTPOptions extends Options {
    private var _username:String;
    private var _password:String;
    private var _additionalHeaders:Array<Tuple<String, String>>;
    private var _verifyPeer:Bool;

    public var username(get, set):String;

    function get_username() {
        return _username;
    }

    function set_username(v) {
        _username = v;
        return v;
    }
    public var password(get, set):String;

    function get_password() {
        return _password;
    }

    function set_password(v) {
        _password = v;
        return v;
    }
    public var additionalHeaders(get, null):Array<Tuple<String, String>>;

    function get_additionalHeaders() {
        return _additionalHeaders;
    }
    public var verifyPeer(get, set):Bool;

    function get_verifyPeer() {
        return _verifyPeer;
    }

    function set_verifyPeer(v) {
        _verifyPeer = v;
        return v;
    }

    static public function create() {
        var instance = new HTTPOptions() ;

        instance.initialize();

        return instance;
    }

    static public function createbyOptions(copy:Options) {
        var instance:HTTPOptions = new HTTPOptions().copyFrom(copy);

        instance.initialize();

        return instance;
    }

    public function new() {
        super();
        _username = "";
        _password = "";
        _additionalHeaders = [];
        _verifyPeer = true;
    }

    override public function copyFrom(copy:Options) {
        super.copyFrom(copy);
        _username = ( cast(copy, HTTPOptions)._username);
        _password = (cast(copy, HTTPOptions)._password);
        _additionalHeaders = (cast(copy, HTTPOptions)._additionalHeaders);
        _verifyPeer = (cast(copy, HTTPOptions)._verifyPeer);
        return cast this;
    }


    override public function clone() {
        var copy:HTTPOptions = new HTTPOptions().copyFrom(this);

        copy.initialize();

        return cast copy;
    }
}
