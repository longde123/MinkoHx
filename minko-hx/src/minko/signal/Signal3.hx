package minko.signal;
typedef Callback3<A, B, C> = A -> B -> C -> Void;
typedef CallbackRecord3<A, B, C> = Tuple<Float, SignalSlot3<A, B, C>>;
@:expose("minko.signal.SignalSlot3")
class SignalSlot3<A, B, C> {
    public var _signal:Signal3<A, B, C>;
    public var callback:Callback3<A, B, C>;
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
@:expose("minko.signal.Signal3")
class Signal3<A, B, C> {
    var _callbacks:Array<CallbackRecord3<A, B, C>>;
    public var numCallbacks(get, null):Int;

    public function new() {
        _callbacks = [];
    }

    public function copyFrom(other:Signal3<A, B, C>) {
        _callbacks = [for (c in other._callbacks) c];
        return this;
    }

    public function dispose() {
        for (callback in _callbacks) {
            var slot:SignalSlot3<A, B, C> = callback.second;

            if (slot != null) {
                slot._signal = null;
            }
        }
        _callbacks = [];
    }

    public static function create<A, B, C>() {
        return new Signal3<A, B, C>();
    }

    function get_numCallbacks() {
        return _callbacks.length;
    }

    public function connect(callback:Callback3<A, B, C>, ?priority:Float = 0, ?once = false) :SignalSlot3<A, B, C>{
        var connection = new SignalSlot3<A, B, C>(this);
        connection.callback = callback;
        connection.once = once;
        _callbacks.push(new CallbackRecord3(priority, connection));
        _callbacks.sort(function(a:CallbackRecord3<A, B, C>, b:CallbackRecord3<A, B, C>) {
            return Math.floor(b.first - a.first);
        });
        return connection;
    }

    public function execute(a:A, b:B, c:C) {
        var callbacks = _callbacks;
        var onces:Array<SignalSlot3<A, B, C>> = [];
        for (callback in callbacks) {
            var slot:SignalSlot3<A, B, C> = callback.second;
            if (!slot.expired) {
                slot.callback(a, b, c);
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

    public function remove(it:SignalSlot3<A, B, C>) {
        _callbacks = _callbacks.filter(function(b:CallbackRecord3<A, B, C>) {
            return b.second != it;
        });
    }

}