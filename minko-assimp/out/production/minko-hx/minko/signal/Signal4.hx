package minko.signal;
typedef Callback4<A, B, C, D> = A -> B -> C -> D -> Void;
typedef CallbackRecord4<A, B, C, D> = Tuple<Float, SignalSlot4<A, B, C, D>>;
@:expose("minko.signal.SignalSlot4")
class SignalSlot4<A, B, C, D> {
    public var _signal:Signal4<A, B, C, D>;
    public var callback:Callback4<A, B, C, D>;
    public var expired:Bool;
    public var once:Bool;

    public function new(_s) {
        expired = false;
        _signal = _s;
    }

    public function disconnect() {
        if (_signal != null) {
            _signal.remove(this);
            _signal = null ;
        }
    }

    public function dispose() {
        disconnect();
    }
}
@:expose("minko.signal.Signal4")
class Signal4<A, B, C, D> {
    public var _callbacks:Array<CallbackRecord4<A, B, C, D>>;
    public var numCallbacks(get, null):Int;

    public function new() {
        _callbacks = [];
    }

    public function copyFrom(other:Signal4<A, B, C, D>) {
        _callbacks = [for (c in other._callbacks) c];
        return this;
    }

    public function dispose() {
        for (callback in _callbacks) {
            var slot:SignalSlot4<A, B, C, D> = callback.second;

            if (slot != null) {
                slot._signal = null;
            }
        }
        _callbacks = [];
    }

    public static function create<A, B, C, D>() {
        return new Signal4<A, B, C, D>();
    }

    function get_numCallbacks() {
        return _callbacks.length;
    }

    public function connect(callback:Callback4<A, B, C, D>, ?priority:Float = 0, ?once = false) {
        var connection = new SignalSlot4<A, B, C, D>(this);
        connection.callback = callback;
        connection.once = once;
        _callbacks.push(new CallbackRecord4(priority, connection));
        _callbacks.sort(function(a:CallbackRecord4<A, B, C, D>, b:CallbackRecord4<A, B, C, D>) {
            return Math.floor(b.first - a.first);
        });
        return connection;
    }

    public function execute(a:A, b:B, c:C, d:D) {
        var callbacks = _callbacks;
        var onces:Array<SignalSlot4<A, B, C, D>> = [];
        for (callback in callbacks) {
            var slot:SignalSlot4<A, B, C, D> = callback.second;
            if (!slot.expired) {
                slot.callback(a, b, c, d);
                if (slot.once) {
                    slot.expired = true;
                    onces.push(slot);
                }
            }
        }
        for (callback in onces) {
            callback.disconnect();
        }
    }

    public function remove(it:SignalSlot4<A, B, C, D>) {
        _callbacks = _callbacks.filter(function(b) {
            return b.second != it;
        });
    }

}