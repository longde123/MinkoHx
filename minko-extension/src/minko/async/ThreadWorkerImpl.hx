package minko.async;

import cpp.vm.Deque;
import cpp.vm.Thread;
import haxe.io.Bytes;
import minko.async.WorkerImpl.Message;
import minko.signal.Signal2;
import neko.vm.Mutex;

class ThreadWorkerImpl extends WorkerImpl {
    private var _that:Worker;
    private var _name:String;
    private var _mutex:Mutex ;
    private var _messages:Deque<Message> ;
    private var _message:Signal2<Worker, Message>;
    private var _input:Bytes;
    private var _thread:Thread;

    override public function start(input:Bytes) {
        _thread = Thread.create(function() {
            run(input);
        });
    }

    public function run(input:Bytes):Void {
        _that.run(input);
    }

    override public function poll() {
        _mutex.acquire();
        var msg = _messages.pop();
        if (msg != null) {
            _message.execute(_that, msg);
        }
        _mutex.release();
    }

    override public function post(message:Message) {
        _mutex.acquire();
        _messages.push(message);
        _mutex.release();
    }


    override function get_message() {
        return _message;
    }

    override public function dispose() {
        //std::cout << "ThreadWorkerImpl::~ThreadWorkerImpl()" << std::endl;
    }

    public function new(that, name) {
        super(that, name);
        this._that = that;
        this._name = name;
        _messages = new Deque<Message>();
        _mutex = new Mutex();
    }


}