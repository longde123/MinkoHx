package minko.component;
import minko.utils.TimeUtil;
import Lambda;
import haxe.ds.StringMap;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal2;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal3;
import minko.signal.Signal;
@:expose("minko.component.AnimationLabel")
class AnimationLabel {
    public var name:String;
    public var time:Int ; // label time in milliseconds

    public function new(n, t) {
        this.name = n;
        this.time = t;
    }
}
@:expose("minko.component.AbstractAnimation")
class AbstractAnimation extends AbstractComponent {

    private var _maxTime:Int;
    private var _currentTime:Int; // relative to animation
    private var _targetAddedSlot:SignalSlot2<AbstractComponent, Node> ;
    private var _targetRemovedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _addedSlot:SignalSlot3<Node, Node, Node >;
    private var _removedSlot:SignalSlot3<Node, Node, Node >;
    private var _loopMinTime:Int;
    private var _loopMaxTime:Int;
    private var _loopTimeRange:Int;
    private var _previousTime:Int;
    private var _previousGlobalTime:Int;
    private var _isPlaying:Bool;
    private var _isLooping:Bool;
    private var _isReversed:Bool;
    private var _mustUpdateOnce:Bool;
    private var _clockStart:Float;
    private var _timeFunction:Int -> Int;
    private var _labels:Array<AnimationLabel>;
    private var _nextLabelIds:Array<Int>;
    private var _sceneManager:SceneManager;
    private var _started:Signal<AbstractAnimation>;
    private var _looped:Signal<AbstractAnimation>;
    private var _stopped:Signal<AbstractAnimation>;
    private var _labelHit:Signal3<AbstractAnimation, String, Int>;
    private var _frameBeginSlot:SignalSlot3<SceneManager, Float, Float>;


    public function play():Void {
        _previousGlobalTime = _timeFunction(_sceneManager != null ? Math.floor(_sceneManager.time) : 0);
        _isPlaying = true;
        _started.execute(this);
        checkLabelHit(_currentTime, _currentTime);

    }

    public function stop():Void  {
        if (_isPlaying) {
            updateNextLabelIds(_currentTime);
            checkLabelHit(_currentTime, _currentTime);
        }

        _isPlaying = false;
        _stopped.execute((this));
        _mustUpdateOnce = true;
        _previousGlobalTime = _timeFunction(_sceneManager != null ? Std.int(_sceneManager.time) : 0);


    }

    override public function clone(option:CloneOption) {
        return null;
    }
    public function seekLabel(labelName)  :Void{
        return seek(labelTimebyName(labelName));
    }
    public function seek(currentTime:Int):Void  {
        if (!isInPlaybackWindow(currentTime)) {
            throw ("Provided time value is outside of playback window. In order to reset playback window, call resetPlaybackWindow().");
        }

        _currentTime = currentTime;

        updateNextLabelIds(_currentTime);

    }



    public var currentTime(get, null):Int;

    function get_currentTime() {
        return _currentTime;
    }

    public var loopStartTime(get, null):Int;

    function get_loopStartTime() {
        return !_isReversed ? _loopMinTime : _loopMaxTime;
    }
    public var loopEndTime(get, null):Int;

    function get_loopEndTime() {
        return !_isReversed ? _loopMaxTime : _loopMinTime;
    }

    public function hasLabel(name:String):Bool {
        return  Lambda.exists(_labels ,function(l:AnimationLabel) return l.name ==name) ;
    }
    public function getLabel(name:String):AnimationLabel {
        return  Lambda.find(_labels ,function(l:AnimationLabel) return l.name ==name) ;
    }
    public function addLabel(name:String, time:Int) :Void {
        if (hasLabel(name)) {
            throw ("A label called '" + name + "' already exists.");
        }


        _labels.push(new AnimationLabel(name, time));

        updateNextLabelIds(_currentTime);

    }

    public function changeLabel(name:String, newName:String) :Void {
        var foundLabelIt = hasLabel(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }


        var label = getLabel(name);
        label.name = newName;

    }

    public function setTimeForLabel(name:String, newTime:Int):Void {
        var foundLabelIt = hasLabel(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }
        var label = getLabel(name);

        label.time = newTime;

    }

    public function removeLabel(name:String):Void {
        var foundLabelIt = hasLabel(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }
        _labels=_labels.filter(function(l:AnimationLabel) return l.name!=name);
    }

    public function setPlaybackWindow(beginTime:Int, endTime:Int, ? forceRestart:Bool = false):Void {
        _loopMinTime = beginTime;
        _loopMaxTime = endTime;

        if (_loopMinTime > _loopMaxTime) {
            _loopMinTime = endTime;
            _loopMaxTime = beginTime;
        }

        _loopTimeRange = _loopMaxTime - _loopMinTime + 1;

        if (!isInPlaybackWindow(_currentTime) || forceRestart) {
            _currentTime = loopStartTime;
        }

        updateNextLabelIds(_currentTime);

    }

    public function setPlaybackWindowbyName(beginLabelName:String, endLabelName:String, ?forceRestart = false) :Void{
          setPlaybackWindow(labelTimeLabel(beginLabelName), labelTimeLabel(endLabelName), forceRestart);
    }

    public function resetPlaybackWindow() :Void{
          setPlaybackWindow(0, _maxTime);
    }

    public var numLabels(get, null):Int;

    function get_numLabels() {
        return _labels.length;
    }


    inline   function labelTimeLabel(labelId:String):Int {
        return getLabel(labelId).time;
    }
    public function labelName(  labelId:Int)  :String
    {
        return _labels[labelId].name;
    }

    public  function labelTime(  labelId:Int) :Int
    {
        return _labels[labelId].time;
    }

    public function labelTimebyName(name:String):Int {
        var foundLabelIt = hasLabel(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }

        return labelTimeLabel( name);
    }

    public var isPlaying(get, set):Bool;

    function get_isPlaying() {
        return _isPlaying;
    }

    function set_isPlaying(value) {
        _isPlaying = value;
        return value;
    }

    public var isLooping(get, set):Bool;

    function get_isLooping() {
        return _isLooping;
    }

    function set_isLooping(value) {
        _isLooping = value;
        return value;
    }

    public var isReversed(get, set):Bool;

    function get_isReversed() {
        return _isReversed;
    }

    function set_isReversed(value) {
        _isReversed = value;
        return value;
    }

    public var maxTime(get, null):Int;

    function get_maxTime() {
        return _maxTime;
    }
    public var timeFunction(null, set):Int -> Int;

    function set_timeFunction(func) {
        _timeFunction = func;
        return func;
    }

    public var started(get, null):Signal<AbstractAnimation>;

    function get_started() {
        return _started;
    }

    public var looped(get, null):Signal<AbstractAnimation>;

    function get_looped() {
        return _looped;
    }

    public var stopped(get, null):Signal<AbstractAnimation>;

    function get_stopped() {
        return _stopped;
    }

    public var labelHit(get, null):Signal3<AbstractAnimation, String, Int>;

    function get_labelHit() {
        return _labelHit;
    }

    public function new(isLooping) {
        super();
        this._maxTime = 0;
        this._loopMinTime = 0;
        this._loopMaxTime = 0;
        this._loopTimeRange = 0;
        this._currentTime = 0;
        this._previousTime = 0;
        this._previousGlobalTime = 0;
        this._isPlaying = false;
        this._isLooping = isLooping;
        this._isReversed = false;
        this._mustUpdateOnce = false;
        this._clockStart = TimeUtil.getTimerMilliseconds();
        this._timeFunction = null;
        this._labels = new Array<AnimationLabel>();

        this._nextLabelIds = new Array<Int>();
        this._sceneManager = null;
        this._started = new Signal<AbstractAnimation>();
        this._looped = new Signal<AbstractAnimation>();
        this._stopped = new Signal<AbstractAnimation>();
        this._labelHit = new Signal3<AbstractAnimation, String, Int>();
        this._targetAddedSlot = null;
        this._targetRemovedSlot = null;
        this._addedSlot = null;
        this._removedSlot = null;
        this._frameBeginSlot = null;
        _timeFunction = function(t) return t;
    }

    public function copyFrom(absAnimation:AbstractAnimation, option:CloneOption):AbstractAnimation {

        this._maxTime = absAnimation._maxTime;
        this._loopMinTime = absAnimation._loopMinTime;
        this._loopMaxTime = absAnimation._loopMaxTime;
        this._loopTimeRange = absAnimation._loopTimeRange;
        this._currentTime = 0;
        this._previousTime = 0;
        this._previousGlobalTime = 0;
        this._isPlaying = false;
        this._isLooping = absAnimation._isLooping;
        this._isReversed = absAnimation._isReversed;
        this._mustUpdateOnce = absAnimation._mustUpdateOnce;
        this._clockStart = TimeUtil.getTimerMilliseconds();
        this._timeFunction = null;
        this._labels = new Array<AnimationLabel>();
        this._nextLabelIds = new Array<Int>();
        this._sceneManager = null;
        this._started = new Signal<AbstractAnimation>();
        this._looped = new Signal<AbstractAnimation>();
        this._stopped = new Signal<AbstractAnimation>();
        this._labelHit = new Signal3<AbstractAnimation, String, Int>();
        this._targetAddedSlot = null;
        this._targetRemovedSlot = null;
        this._addedSlot = null;
        this._removedSlot = null;
        this._frameBeginSlot = null;
        if (option == CloneOption.DEEP) {
            _currentTime = absAnimation._currentTime;
            _previousTime = absAnimation._previousTime;
            _previousGlobalTime = absAnimation._previousGlobalTime;
            _isPlaying = absAnimation._isPlaying;
        }
        _timeFunction = function(t) return t;
        return this;
    }

    override public function dispose():Void {

        _targetAddedSlot = null;
        _targetRemovedSlot = null;
        _addedSlot = null;
        _removedSlot = null;
        _frameBeginSlot = null;
    }

    public function initialize() :Void{
    }

    override public function targetAdded(node:Node):Void {
        _addedSlot = node.added.connect(addedHandler);

        _removedSlot = node.removed.connect(removedHandler);

        _target = node;
    }

    override public function targetRemoved(node:Node) :Void{
        _addedSlot = null;
        _removedSlot = null;
    }

    public function addedHandler(node:Node, target:Node, parent:Node):Void {
        findSceneManager();
    }

    public function removedHandler(node:Node, target:Node, parent:Node):Void {
        findSceneManager();
    }

    public function componentAddedHandler(node:Node, target:Node, component:AbstractComponent):Void {

    }

    public function componentRemovedHandler(node:Node, target:Node, component:AbstractComponent) :Void{

    }

    public function findSceneManager() {
        var roots:NodeSet = NodeSet.createbyNode(target).roots().where(function(node:Node) {
            return node.hasComponent(SceneManager);
        });

        if (roots.nodes.length > 1) {
            throw ("Renderer cannot be in two separate scenes.");
        }
        else if (roots.nodes.length == 1) {
            setSceneManager(cast roots.nodes[0].getComponent(SceneManager));
        }
        else {
            setSceneManager(null);
        }
    }

    public function setSceneManager(sceneManager:SceneManager) :Void{
        if (sceneManager != null && sceneManager != _sceneManager) {
            _frameBeginSlot = sceneManager.frameBegin.connect(frameBeginHandler);

            if (_sceneManager == null) {
                _previousGlobalTime = _timeFunction(Math.floor(sceneManager.time));
            }
        }
        else if (_frameBeginSlot != null && sceneManager == null) {
            stop();
            _frameBeginSlot.dispose();
            _frameBeginSlot = null;
        }

        _sceneManager = sceneManager;
    }

    public function frameBeginHandler(sceneManager:SceneManager, time:Float, UnnamedParameter1:Float) {
        updateRaw(Math.floor(time));
    }
    // record the indices of the labels that lie directly after the specified time value
    // in the animation.
    public function updateNextLabelIds(time) {
        _nextLabelIds = new Array<Int>();

        if (_labels.length == 0) {
            return;
        }

        //  _nextLabelIds.Capacity = _labels.length;

        var UINT_MAX = 10000;
        var nextLabelTime = !_isReversed ? UINT_MAX : 0;

        for (labelId in 0... _labels.length) {
            var labelTime = _labels[labelId].time;

            if (!isInPlaybackWindow(labelTime)) {
                continue;
            }

            if (!_isReversed && time < labelTime) {
                if (labelTime < nextLabelTime) {
                    nextLabelTime = labelTime;

                    _nextLabelIds = new Array<Int>();
                    _nextLabelIds.push(labelId);
                }
                else if (labelTime == nextLabelTime) {
                    _nextLabelIds.push(labelId);
                }
            }
            else if (_isReversed && labelTime < time) {
                if (nextLabelTime < labelTime) {
                    nextLabelTime = labelTime;

                    _nextLabelIds = new Array<Int>();
                    _nextLabelIds.push(labelId);
                }
                else if (labelTime == nextLabelTime) {
                    _nextLabelIds.push(labelId);
                }
            }
        }

        if (_nextLabelIds.length == 0) {
            if (time != loopStartTime) {
                updateNextLabelIds(loopStartTime);
            }
        }
        else if (_isLooping && nextLabelTime == loopEndTime) {
            for (labelId in 0..._labels.length) {
                if (_labels[labelId].time == loopStartTime && _nextLabelIds.indexOf(labelId) == -1) {
                    _nextLabelIds.push(labelId);
                }
            }
        }
    }

    public function checkLabelHit(previousTime:Int, newTime:Int) :Void{
        if (!_isPlaying || _nextLabelIds.length == 0) {
            return;
        }

        var nextLabel = _labels[_nextLabelIds[0]];
        var nextLabelTime = nextLabel.time;

//Debug.Assert(isInPlaybackWindow(nextLabelTime));

        var trigger = false;

        if (!_isReversed) {
            if (previousTime <= newTime) {
                if ((newTime == nextLabelTime) || (previousTime < nextLabelTime && nextLabelTime <= newTime)) {
                    trigger = true;
                }
            }
            else {// newTime < previousTime
                if (previousTime < nextLabelTime) {
                    trigger = true;
                }
                else if (nextLabelTime < newTime) {
                    trigger = true;
                }
            }
        }
        else { // reversed animation
            if (newTime <= previousTime) {
                if ((newTime == nextLabelTime) || (newTime <= nextLabelTime != null && nextLabelTime < previousTime)) {
                    trigger = true;
                }
            }
            else {// previousTime < newTime
                if (nextLabelTime < previousTime) {
                    trigger = true;
                }
                else if (newTime < nextLabelTime) {
                    trigger = true;
                }
            }
        }

        if (trigger) {
            var nextLabelIds = _nextLabelIds;

            for (labelId in nextLabelIds) {
                var label = _labels[labelId];

                _labelHit.execute((this), label.name, label.time);
            }

            updateNextLabelIds(getNewLoopTime(_currentTime, !_isReversed ? 1 : -1));
        }
    }

    public function isInPlaybackWindow(time:Int):Bool {
//Debug.Assert(_loopMinTime <= _loopMaxTime);

        return _loopMinTime <= time && time <= _loopMaxTime;
    }

    public function update():Void {

    }
    /*virtual*/
    public function updateRaw(rawGlobalTime:Int = 0):Bool {
        if (!_isPlaying && !_mustUpdateOnce) {
            return false;
        }

        _mustUpdateOnce = false;

        var globalTime = _timeFunction(rawGlobalTime);
        var globalDeltaTime = globalTime - _previousGlobalTime;
        var deltaTime = Std.int(!_isReversed ? globalDeltaTime : -globalDeltaTime);

        _previousTime = _currentTime;
        if (_isPlaying) {
            _currentTime = getNewLoopTime(_currentTime, deltaTime);
        }
        _previousGlobalTime = globalTime;

        var looped = (!_isReversed && _currentTime < _previousTime) || (_isReversed && _previousTime < _currentTime);

        if (looped) {
            if (_isLooping) {
                _looped.execute((this));
            }
            else {
                _currentTime = loopEndTime;
                stop();
            }
        }

        update();

        checkLabelHit(_previousTime, _currentTime);

        return _isPlaying || _mustUpdateOnce;
    }




    public function getNewLoopTime(time:Int, deltaTime:Int):Int {
        var relTime = (time - _loopMinTime) + deltaTime;
        var timeOffset = (Std.int(relTime + _loopTimeRange) % _loopTimeRange);

        return _loopMinTime + timeOffset;
    }
}
