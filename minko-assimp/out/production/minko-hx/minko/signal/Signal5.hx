package minko.signal;
typedef Callback5<A, B, C, D, E> = A -> B -> C -> D -> E -> Void;
typedef CallbackRecord5<A, B, C, D, E> = Tuple<Float, SignalSlot5<A, B, C, D, E>>;
@:expose("minko.signal.SignalSlot5")
class SignalSlot5<A, B, C, D, E> {
    public var _signal:Signal5<A, B, C, D, E>;
    public var callback:Callback5<A, B, C, D, E>;
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
@:expose("minko.signal.Signal5")
class Signal5<A, B, C, D, E> {
    public var _callbacks:Array<CallbackRecord5<A, B, C, D, E>>;
    public var numCallbacks(get, null):Int;

    public function new() {
        _callbacks = [];
    }

    public function copyFrom(other:Signal5<A, B, C, D, E>) {
        _callbacks = [for (c in other._callbacks) c];
        return this;
    }

    public function dispose() {
        for (callback in _callbacks) {
            var slot:SignalSlot5<A, B, C, D, E> = callback.second;

            if (slot != null) {
                slot._signal = null;
            }
        }
        _callbacks = [];
    }

    public static function create<A, B, C, D, E>() {
        return new Signal5<A, B, C, D, E>();
    }

    function get_numCallbacks() {
        return _callbacks.length;
    }

    public function connect(callback:Callback5<A, B, C, D, E>, ?priority:Float = 0, ?once = false) {
        var connection = new SignalSlot5<A, B, C, D, E>(this);
        connection.callback = callback;
        connection.once = once;
        _callbacks.push(new CallbackRecord5(priority, connection));
        _callbacks.sort(function(a:CallbackRecord5<A, B, C, D, E>, b:CallbackRecord5<A, B, C, D, E>) {
            return Math.floor(b.first - a.first);
        });
        return connection;
    }

    public function execute(a:A, b:B, c:C, d:D, e:E) {
        var callbacks = _callbacks;
        var onces:Array<SignalSlot5<A, B, C, D, E>> = [];
        for (callback in callbacks) {
            var slot:SignalSlot5<A, B, C, D, E> = callback.second;
            if (!slot.expired) {
                slot.callback(a, b, c, d, e);
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

    public function remove(it2:SignalSlot5<A, B, C, D, E>) {
        _callbacks = _callbacks.filter(function(it:CallbackRecord5<A, B, C, D, E>) {
            return it.second != it2;
        });
    }

}
