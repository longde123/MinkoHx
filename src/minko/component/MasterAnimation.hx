package minko.component;
import haxe.ds.ObjectMap;
import minko.scene.Node;
import minko.scene.NodeSet;
class MasterAnimation extends AbstractAnimation {
    private var _animations:Array<AbstractAnimation> ;

    public static function create(isLooping = true) {
        var ptr = new MasterAnimation(isLooping) ;

        return ptr;
    }

    override public function play() {
        super.play();

        for (animation in _animations) {
            animation.play();
        }

        return cast(this, AbstractAnimation);
    }

    override public function stop() {
        super.stop();

        for (animation in _animations) {
            animation.stop();
        }

        return cast(this, AbstractAnimation);
    }

    override public function seek(time:Int) {
        super.seek(time);

        for (animation in _animations) {
            animation.seek(time);
        }

        return cast(this, AbstractAnimation);
    }

    override public function seekLabel(labelName) {
        return seek(labelTimebyName(labelName));
    }

    override public function clone(option:CloneOption) {
        var anim:MasterAnimation = new MasterAnimation(this.isLooping);
        anim.copyFrom(this, option);
        return anim;
    }

    override public function addLabel(name, time) {
        super.addLabel(name, time);

        for (animation in _animations) {
            animation.addLabel(name, time);
        }

        return cast(this, AbstractAnimation);
    }

    override public function changeLabel(name, newName) {
        super.changeLabel(name, newName);

        for (animation in _animations) {
            animation.changeLabel(name, newName);
        }

        return cast(this, AbstractAnimation);
    }

    override public function setTimeForLabel(name, newTime) {
        super.setTimeForLabel(name, newTime);

        for (animation in _animations) {
            animation.setTimeForLabel(name, newTime);
        }

        return cast(this, AbstractAnimation);
    }

    override public function removeLabel(name) {
        super.removeLabel(name);

        for (animation in _animations) {
            animation.removeLabel(name);
        }

        return cast(this, AbstractAnimation);
    }


    override public function setPlaybackWindow(beginLabelName, endLabelName, ?forceRestart = false) {
        super.setPlaybackWindow(beginLabelName, endLabelName, forceRestart);

        for (animation in _animations) {
            animation.setPlaybackWindow(beginLabelName, endLabelName, forceRestart);
        }

        return cast(this, AbstractAnimation);
    }

    override public function resetPlaybackWindow() {
        super.resetPlaybackWindow();

        for (animation in _animations) {
            animation.resetPlaybackWindow();
        }

        return cast(this, AbstractAnimation);
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

        var _this:AbstractAnimation = setPlaybackWindow(0, _maxTime);
        _this.seek(0).play();
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
