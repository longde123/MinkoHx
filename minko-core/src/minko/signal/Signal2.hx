package minko.signal;
typedef Callback2<A, B> = A -> B -> Void;
typedef CallbackRecord2<A, B> = Tuple<Float, SignalSlot2<A, B>>;
@:expose("minko.signal.SignalSlot2")
class SignalSlot2<A, B> {
    public var _signal:Signal2<A, B>;
    public var callback:Callback2<A, B>;
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
@:expose("minko.signal.Signal2")
class Signal2<A, B> {
    public var _callbacks:Array<CallbackRecord2<A, B>>;
    public var numCallbacks(get, null):Int;

    public function new() {
        _callbacks = [];
    }

    public function copyFrom(other:Signal2<A, B>) {
        _callbacks = [for (c in other._callbacks) c];
        return this;
    }

    public function dispose() {
        for (callback in _callbacks) {
            var slot:SignalSlot2<A, B> = callback.second;

            if (slot != null) {
                slot._signal = null;
            }
        }
        _callbacks = [];
    }

    public static function create<A, B>() {
        return new Signal2<A, B>();
    }

    function get_numCallbacks() {
        return _callbacks.length;
    }

    public function connect(callback:Callback2<A, B>, ?priority:Float = 0, ?once = false) {
        var connection = new SignalSlot2<A, B>(this);
        connection.callback = callback;
        connection.once = once;
        _callbacks.push(new CallbackRecord2(priority, connection));
        _callbacks.sort(function(a:CallbackRecord2<A, B>, b:CallbackRecord2<A, B>) {
            return Math.floor(b.first - a.first);
        });
        return connection;
    }

    public function remove(it:SignalSlot2<A, B>) {
        _callbacks = _callbacks.filter(function(b:CallbackRecord2<A, B>) {
            return b.second != it;
        });
    }

    public function execute(a:A, b:B) {
        var callbacks = _callbacks;
        var onces:Array<SignalSlot2<A, B>> = [];
        for (callback in callbacks) {
            var slot:SignalSlot2<A, B> = callback.second;
            if (!slot.expired) {
                slot.callback(a, b);
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
}