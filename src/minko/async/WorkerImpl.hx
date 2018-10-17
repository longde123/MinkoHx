package minko.async;
import haxe.io.Bytes;
import minko.signal.Signal2;
typedef Message = {
type:String,
data:Any
};
class WorkerImpl {

    public function start(input:Bytes) {

    }


    public function poll() {

    }

    public function post(message:Message) {

    }

    public var message(get, null):Signal2<Worker, Message>;

    function get_message() {
        return null;
    }

    public function dispose() {
        //std::cout << "ThreadWorkerImpl::~ThreadWorkerImpl()" << std::endl;
    }

    public function new(that, name) {
    }
}
