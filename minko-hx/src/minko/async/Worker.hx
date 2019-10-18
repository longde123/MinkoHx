package minko.async;
import haxe.io.Bytes;
import minko.async.WorkerImpl.Message;
import minko.signal.Signal2;
@:expose
class Worker {

    public function start(input:Bytes) {
        _impl.start(input);
    }

    public var message(get, null):Signal2<Worker, Message>;

    function get_message() {
        return _impl.message ;
    }


    public function post(message) {
        _impl.post(message);
    }


    public function run(input:Bytes) {

    }

    public function poll() {
        _impl.poll();
    }

    public function dispose() {
    }

    public function new(name:String) {
        _impl = new WorkerImpl(this, name);
    }

    private var _impl:WorkerImpl;

}
