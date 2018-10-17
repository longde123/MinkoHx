package minko.component;
import haxe.ds.StringMap;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal2;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal3;
import minko.signal.Signal;
class Label {
    public var name:String;
    public var time:Int ; // label time in milliseconds

    public function new(n, t) {
        this.name = n;
        this.time = t;
    }
}
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
    private var _labels:Array<Label>;
    private var _labelNameToIndex:StringMap<Int> ;
    private var _nextLabelIds:Array<Int>;
    private var _sceneManager:SceneManager;
    private var _started:Signal<AbstractAnimation>;
    private var _looped:Signal<AbstractAnimation>;
    private var _stopped:Signal<AbstractAnimation>;
    private var _labelHit:Signal3<AbstractAnimation, String, Int>;
    private var _frameBeginSlot:SignalSlot3<SceneManager, Float, Float>;


    public function play() {
        _previousGlobalTime = _timeFunction(_sceneManager != null ? Math.floor(_sceneManager.time) : 0);
        _isPlaying = true;
        _started.execute(this);
        checkLabelHit(_currentTime, _currentTime);

        return (this);
    }

    public function stop() {
        if (_isPlaying) {
            updateNextLabelIds(_currentTime);
            checkLabelHit(_currentTime, _currentTime);
        }

        _isPlaying = false;
        _stopped.execute((this));
        _mustUpdateOnce = true;
        _previousGlobalTime = _timeFunction(_sceneManager != null ? Std.int(_sceneManager.time) : 0);

        return (this);
    }

    override public function clone(option:CloneOption) {
        return null;
    }

    public function seek(currentTime:Int) {
        if (!isInPlaybackWindow(currentTime)) {
            throw ("Provided time value is outside of playback window. In order to reset playback window, call resetPlaybackWindow().");
        }

        _currentTime = currentTime;

        updateNextLabelIds(_currentTime);

        return (this);
    }

    public function seekLabel(labelName:String) {
        var masterAnim:MasterAnimation = cast(this);

        return masterAnim != null ? masterAnim.seekLabel(labelName) : seek(labelTimebyName(labelName));
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

    public function hasLabel(name) {
        return _labelNameToIndex.exists(name) ;
    }

    public function addLabel(name, time) {
        if (hasLabel(name)) {
            throw ("A label called '" + name + "' already exists.");
        }

        _labelNameToIndex.set(name, _labels.length);
        _labels.push(new Label(name, time));

        updateNextLabelIds(_currentTime);

        return (this);
    }

    public function changeLabel(name, newName) {
        var foundLabelIt = _labelNameToIndex.exists(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }

        var labelId = _labelNameToIndex.get(name);
        var label = _labels[labelId];

        _labelNameToIndex.remove(name);
        label.name = newName;
        _labelNameToIndex.set(newName, labelId);

        return (this);
    }

    public function setTimeForLabel(name, newTime) {
        var foundLabelIt = _labelNameToIndex.exists(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }
        var labelId = _labelNameToIndex.get(name);
        var label = _labels[labelId];

        label.time = newTime;

        return (this);
    }

    public function removeLabel(name) {
        var foundLabelIt = _labelNameToIndex.exists(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }

        var labelId = _labelNameToIndex.get(name);
        var lastLabelName:String = _labels[_labels.length - 1].name;

        _labels[labelId] = _labels[_labels.length - 1];
        _labelNameToIndex.set(lastLabelName, labelId);
        _labels.pop();

        return (this);
    }

    public function setPlaybackWindow(beginTime, endTime, ? forceRestart:Bool = false) {
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

        return (this);
    }

    public function setPlaybackWindowbyName(beginLabelName, endLabelName, ?forceRestart = false) {
        return setPlaybackWindow(labelTime(beginLabelName), labelTime(endLabelName), forceRestart);
    }

    public function resetPlaybackWindow() {
        return setPlaybackWindow(0, _maxTime);
    }

    public var numLabels(get, null):Int;

    function get_numLabels() {
        return _labels.length;
    }


    public function labelName(labelId) {
        return _labels[labelId].name;
    }


    public function labelTime(labelId) {
        return _labels[labelId].time;
    }


    public function labelTimebyName(name) {
        var foundLabelIt = _labelNameToIndex.exists(name);
        if (foundLabelIt == false) {
            throw ("No label called '" + name + "' currently exists.");
        }

        return labelTime(_labelNameToIndex.get(name));
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
        this._clockStart = Date.now().getTime();
        this._timeFunction = null;
        this._labels = new Array<Label>();
        this._labelNameToIndex = new StringMap<Int>();
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

    public function copyFrom(absAnimation:AbstractAnimation, option:CloneOption) {

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
        this._clockStart = Date.now().getTime();
        this._timeFunction = null;
        this._labels = new Array<Label>();
        this._labelNameToIndex = new StringMap<Int>();
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

    override public function dispose() {

        _targetAddedSlot = null;
        _targetRemovedSlot = null;
        _addedSlot = null;
        _removedSlot = null;
        _frameBeginSlot = null;
    }

    public function initialize() {
    }

    override public function targetAdded(node:Node) {
        _addedSlot = node.added.connect(addedHandler);

        _removedSlot = node.removed.connect(removedHandler);

        _target = node;
    }

    override public function targetRemoved(node:Node) {
        _addedSlot = null;
        _removedSlot = null;
    }

    public function addedHandler(node, target, parent) {
        findSceneManager();
    }

    public function removedHandler(node, target, parent) {
        findSceneManager();
    }

    public function componentAddedHandler(node, target, component) {

    }

    public function componentRemovedHandler(node, target, component) {

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

    public function setSceneManager(sceneManager:SceneManager) {
        if (sceneManager != null && sceneManager != _sceneManager) {
            _frameBeginSlot = sceneManager.frameBegin.connect(frameBeginHandler);

            if (_sceneManager == null) {
                _previousGlobalTime = _timeFunction(Math.floor(sceneManager.time));
            }
        }
        else if (_frameBeginSlot != null && sceneManager == null) {
            stop();
            _frameBeginSlot.disconnect();
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

    public function checkLabelHit(previousTime, newTime) {
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

    public function isInPlaybackWindow(time) {
//Debug.Assert(_loopMinTime <= _loopMaxTime);

        return _loopMinTime <= time && time <= _loopMaxTime;
    }

    public function update() {

    }
    /*virtual*/
    public function updateRaw(rawGlobalTime = 0) {
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


//			@uint getTimerMilliseconds();


    public function getNewLoopTime(time, deltaTime) {
        var relTime = (time - _loopMinTime) + deltaTime;
        var timeOffset = (Std.int(relTime + _loopTimeRange) % _loopTimeRange);

        return _loopMinTime + timeOffset;
    }
}
