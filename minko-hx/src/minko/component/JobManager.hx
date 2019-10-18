package minko.component;
import minko.utils.TimeUtil;
import haxe.ds.ObjectMap;
import minko.scene.Node;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal;
class PriorityComparator {
    public static function functorMethod(left:Job, right:Job) {
        return Math.floor(left.priority - right.priority);
    }
}
@:expose("minko.component.Job")
class Job {
    private var _jobManager:JobManager;
    private var _running:Bool;
    var _priorityChanged:Signal<Float>;
    var _beforePriorityChanged:Signal<Float>;
    var _priority:Float;
    public var complete(get, null):Int;
    function get_complete() {
        return 0;
    }

    public function beforeFirstStep() {

    }

    public function step() {

    }

    public var priority(get, set):Float;

    function get_priority() {
        return _priority;
    }
    function set_priority(p) {
          _priority=p;
        return p;
    }
    public function afterLastStep() {

    }
    public var running(get, set):Bool;

    function get_running() {
        return _running;
    }

    function set_running(value) {
        _running = value;
        return value;
    }
    public var jobManager(get, set):JobManager;

    function get_jobManager() {
        return _jobManager ;
    }

    function set_jobManager(v) {
        _jobManager = v;
        return v;
    }

    public var beforePriorityChanged(get, null):Signal<Float>;

    function get_beforePriorityChanged() {
        return _beforePriorityChanged;
    }
    public var priorityChanged(get, null):Signal<Float>;

    function get_priorityChanged() {
        return _priorityChanged;
    }

    public function new() {
        this._jobManager = new JobManager(24);
        this._running = false;
        this._priorityChanged = new Signal<Float>();
    }
}
@:expose("minko.component.JobManager")
class JobManager extends AbstractScript {

    static inline var _defaultMinimumNumStepsPerFrame = 1 ;
    static inline var CLOCKS_PER_SEC = 1000;
    private var _loadingFramerate:Int;
    private var _frameTime:Float;
    private var _jobs:Array<Job>;
    private var _jobPriorityChangedSlots:ObjectMap<Job, SignalSlot<Float>>;
    private var _sortingNeeded:Bool;
    private var _frameStartTime:Float;

    public static function create(loadingFramerate) {
        return new JobManager(loadingFramerate);
    }

    public function pushJob(job:Job) {
        _jobPriorityChangedSlots.set(job, job.priorityChanged.connect(function(priority) {
            _sortingNeeded = true;
        }));

        job.jobManager = (this);

        insertJob(job);

        return (this);
    }

    override public function update(target:Node) {
        //todo;
        _frameStartTime = TimeUtil.getTimerMilliseconds();
    }

    override public function end(target:Node) {
        if (_jobs.length == 0) {
            return;
        }

        var consumeTime = (TimeUtil.getTimerMilliseconds() - _frameStartTime) / CLOCKS_PER_SEC;
        var currentJob:Job = null;

        var numStepPerformed = 0;

        while (consumeTime < _frameTime || numStepPerformed < _defaultMinimumNumStepsPerFrame) {
            if (_sortingNeeded) {
                _sortingNeeded = false;

                currentJob = null;

                _jobs.sort(PriorityComparator.functorMethod);
            }

            if (!hasPendingJob()) {
                break;
            }

            if (currentJob == null) {
                currentJob = _jobs[_jobs.length - 1];
                if (!currentJob.running) {
                    currentJob.running = (true);
                    currentJob.beforeFirstStep();
                }
            }

            var currentJobComplete = currentJob.complete;

            if (currentJobComplete == 0) {
                currentJob.step();
                currentJobComplete |= currentJob.complete;
            }

            if (currentJobComplete == 1) {
                _jobs.pop();
                currentJob.afterLastStep();
                _jobPriorityChangedSlots.remove(currentJob);
                currentJob = null;
            }

            ++numStepPerformed;

            consumeTime = ( (TimeUtil.getTimerMilliseconds() - _frameStartTime) / CLOCKS_PER_SEC);
        }
    }

    public function new(loadingFramerate) {
        super();
        this._loadingFramerate = loadingFramerate;
        this._sortingNeeded = false;
        _frameTime = 1.0 / loadingFramerate;
    }

    private function insertJob(job:Job) {
        _jobs.push(job);
        _sortingNeeded = true;
    }

    private function hasPendingJob() {
        return _jobs.length > 0 && _jobs[_jobs.length - 1].priority > 0.0;
    }
}
