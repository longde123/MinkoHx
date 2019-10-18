package minko.component;
import haxe.ds.ObjectMap;
import minko.scene.Node;
import minko.scene.NodeSet;
@:expose("minko.component.MasterAnimation")
class MasterAnimation extends AbstractAnimation {
    private var _animations:Array<AbstractAnimation> ;

    public static function create(isLooping = true) {
        var ptr = new MasterAnimation(isLooping) ;

        return ptr;
    }



    override public function play():Void {
        super.play();

        for (animation in _animations) {
            animation.play();
        }

    }

    override public function stop() :Void{
        super.stop();

        for (animation in _animations) {
            animation.stop();
        }

    }

    override public function seek(time:Int)  :Void{
        super.seek(time);

        for (animation in _animations) {
            animation.seek(time);
        }

    }


    override public function clone(option:CloneOption) {
        var anim:MasterAnimation = new MasterAnimation(this.isLooping);
        anim.copyFrom(this, option);
        return anim;
    }

    override public function addLabel(name, time):Void {
        super.addLabel(name, time);

        for (animation in _animations) {
            animation.addLabel(name, time);
        }

    }

    override public function changeLabel(name, newName):Void {
        super.changeLabel(name, newName);

        for (animation in _animations) {
            animation.changeLabel(name, newName);
        }

    }

    override public function setTimeForLabel(name, newTime):Void  {
        super.setTimeForLabel(name, newTime);

        for (animation in _animations) {
            animation.setTimeForLabel(name, newTime);
        }

    }

    override public function removeLabel(name):Void  {
        super.removeLabel(name);

        for (animation in _animations) {
            animation.removeLabel(name);
        }

    }


    override public function setPlaybackWindow(beginLabelName, endLabelName, ?forceRestart = false):Void {
        super.setPlaybackWindow(beginLabelName, endLabelName, forceRestart);

        for (animation in _animations) {
            animation.setPlaybackWindow(beginLabelName, endLabelName, forceRestart);
        }
    }

    override public function resetPlaybackWindow():Void {
        super.resetPlaybackWindow();

        for (animation in _animations) {
            animation.resetPlaybackWindow();
        }

    }

    public function initAnimations() {
        var target = this.target;
        var targetParent = target.parent;

        var rootNode = targetParent != null ? targetParent : target;

        var descendants:NodeSet = NodeSet.createbyNode(rootNode).descendants(true);
        var nodes:Array<Node> = descendants.nodes;
        for (descendant in nodes) {
            for (skinning in descendant.getComponents(Skinning)) {
                _animations.push(cast skinning);
            }

            for (animation in descendant.getComponents(Animation)) {
                _animations.push(cast animation);
            }
        }

        _maxTime = 0;

        for (animation in _animations) {
            _maxTime = Math.floor(Math.max(_maxTime, animation.maxTime));
        }

        setPlaybackWindow(0, _maxTime);
        seek(0);
        play();
    }

    override public function rebindDependencies(componentsMap:ObjectMap<AbstractComponent, AbstractComponent>, nodeMap:ObjectMap<Node, Node>, option:Int) {
        var newAnimations = new Array<AbstractAnimation>();
        for (animation in _animations) {
            var it:AbstractAnimation = cast componentsMap.get(animation);
            if (it != null) {
                newAnimations.push(animation);
            }
        }

        _animations = (newAnimations);
    }

    override function set_timeFunction(func:Int -> Int) {
        super.set_timeFunction(func);

        for (animation in _animations) {
            animation.timeFunction = (func);
        }
        return func;
    }

    override function set_isReversed(value) {
        super.set_isReversed(value);

        for (animation in _animations) {
            animation.set_isReversed(value);
        }
        return value;
    }

    public function new(isLooping) {
        super(isLooping);
        this._animations = [];
        /*
				_maxTime = 0;

				for (auto& animation : _animations)
				{
					animation->_master = std::dynamic_pointer_cast<MasterAnimation>(shared_from_this());
					_maxTime = std::max(_maxTime, animation->_maxTime);
				}

				setPlaybackWindow(0, _maxTime)->seek(0)->play();
				*/
    }

    override public function targetAdded(target:Node) {
        _addedSlot = target.added.connect(addedHandler);

        _removedSlot = target.removed.connect(removedHandler);

        _target = target;

        initAnimations();
    }

    override public function targetRemoved(target:Node) {
    }


    /*virtual*/
    override public function update() {
        for (animation in _animations) {
            var anim:Animation = cast(animation);
            if (anim != null) {
                anim._currentTime = _currentTime;
                anim.update();
            }
        }
    }
}
