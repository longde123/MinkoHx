package minko.component;
import haxe.ds.ObjectMap;
import minko.animation.AbstractTimeline;
import minko.scene.Node;
@:expose("minko.component.Animation")
class Animation extends AbstractAnimation {
    private var _timelines:Array<AbstractTimeline> ;


    public static function create(timelines:Array<AbstractTimeline>, isLooping = true) {
        var ptr = new Animation(timelines, isLooping);

        ptr.initialize();

        return ptr;
    }

    public function new(timelines, isLooping) {
        super(isLooping);
        this._timelines = (timelines);
    }

    override public function clone(option:CloneOption) {
        var anim = new Animation(this._timelines, this.isLooping);
        anim.copyFromAnimation(this, option);
        anim.initialize();

        return anim;
    }

    override public function rebindDependencies(componentsMap:ObjectMap<AbstractComponent, AbstractComponent>, nodeMap:ObjectMap<Node, Node>, option:Int) {

        // FIXME: Implement when animation clones are tested (without skinning).
    }

    public var numTimelines(get, null):Int;

    function get_numTimelines() {
        return _timelines.length;
    }

    public function getTimeline(timelineId) {
        return _timelines[timelineId];
    }

    private var timelines(get, null):Array<AbstractTimeline> ;

    function get_timelines() {
        return _timelines;
    }

    override public function initialize() {
        super.initialize();

        _maxTime = 0;

        for (timeline in _timelines) {
            _maxTime = Math.floor(Math.max(_maxTime, timeline.duration));
        }

        setPlaybackWindow(0, _maxTime);
        seek(0);
    }


    public function copyFromAnimation(anim:Animation, option:CloneOption) {
        copyFrom(anim, option);
        this._timelines = [];
        for (i in 0...anim._timelines.length) {
            var clone = anim._timelines[i].clone();
            _timelines[i] = clone;
        }

        return this;
    }

    override public function update() {
        super.update();
        for (timeline in _timelines) {
            var currentTime = _currentTime % (timeline.duration + 1); // Warning: bounds!
            timeline.update(currentTime, target.data);

        }
    }

    override public function frameBeginHandler(manager:SceneManager, time, deltaTime) {
        super.frameBeginHandler(manager, time, deltaTime);
    }

    override public function updateNextLabelIds(time) {
        super.updateNextLabelIds(time);
    }

    override public function checkLabelHit(previousTime, newTime) {
        super.checkLabelHit(previousTime, newTime);
    }
}
