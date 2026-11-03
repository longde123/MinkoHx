package minko.signal;
typedef Callback<A> = A -> Void;
typedef CallbackRecord<A> = Tuple<Float, SignalSlot<A>>;
@:expose("minko.signal.SignalSlot")
class SignalSlot<A> {
    public var _signal:Signal<A>;
    public var callback:Callback<A>;
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
@:expose("minko.signal.Signal")
class Signal<A> {
    private var _callbacks:Array<CallbackRecord<A>>;
    public var numCallbacks(get, null):Int;

    public function new() {
        _callbacks = [];
    }

    public function copyFrom(other:Signal<A>) {
        _callbacks = [for (c in other._callbacks) c];
        return this;
    }

    public function dispose() {
        for (callback in _callbacks) {
            var slot = callback.second;

            if (slot != null) {
                slot._signal = null;
            }
        }
        _callbacks = [];
    }

    public static function create<A>() {
        return new Signal<A>();
    }

    function get_numCallbacks() {
        return _callbacks.length;
    }

    public function connect(callback:Callback<A>, ?priority:Float = 0, ?once = false) {
        var connection = new SignalSlot<A>(this);
        connection.callback = callback;
        connection.once = once;
        _callbacks.push(new CallbackRecord(priority, connection));
        _callbacks.sort(function(a:CallbackRecord<A>, b:CallbackRecord<A>) {
            return Math.floor(b.first - a.first);
        });
        return connection;

    }

    public function execute(a:A) {

        var callbacks = _callbacks;
        var onces:Array<SignalSlot<A>> = [];
        for (callback in callbacks) {
            var slot:SignalSlot<A> = callback.second;
            if (!slot.expired) {
                slot.callback(a);
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


    public function remove(it:SignalSlot<A>) {
        _callbacks = _callbacks.filter(function(b) {
            return b.second != it;
        });
    }

}