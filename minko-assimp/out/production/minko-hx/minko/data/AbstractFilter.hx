package minko.data;
import minko.component.AbstractComponent;
import minko.component.Surface;
import minko.scene.Node;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal2;
import minko.signal.Signal3.SignalSlot3;
@:expose("minko.data.AbstractFilter")
class AbstractFilter {

    private var _currentSurface:Surface;
    private var _currentSurfaceRemovedSlot:SignalSlot2<AbstractComponent, Node> ;
    private var _currentSurfaceTargetRemovedSlot:SignalSlot3<Node, Node, Node>;
    private var _changed:Signal2<AbstractFilter, Surface>;
    private var _watchedProperties:Array<String>;
    public var currentSurface(get, null):Surface;

    public function get_currentSurface() {
        return _currentSurface;
    }

    public var changed(get, null):Signal2<AbstractFilter, Surface> ;

    public function get_changed() {
        return _changed;
    }

    public function new() {

        this._watchedProperties = new Array<String>();
        this._currentSurface = null;
        this._currentSurfaceRemovedSlot = null;
        this._currentSurfaceTargetRemovedSlot = null;
        this._changed = new Signal2<AbstractFilter, Surface>();
    }

    public function watchProperty(propertyName:String):Void {
        _watchedProperties.push(propertyName);

        this.changed.execute(this, null);
    }

    public function unwatchProperty(propertyName:String):Void {
        var it = Lambda.find(_watchedProperties, function(value) return value == propertyName);

        if (it == null) {
            throw ("This property is not watching currently.");
        }

        _watchedProperties.remove(propertyName);
        //_surfaceTargetPropertyChangedSlots.clear();

        this.changed.execute(this, null);
    }


    private function currentSurfaceRemovedHandler(UnnamedParameter1:AbstractComponent, UnnamedParameter2:Node) {
        forgetCurrentSurface();
    }

    private function currentSurfaceTargetRemovedHandler(UnnamedParameter1:Node, UnnamedParameter2:Node, UnnamedParameter3:Node) {
        forgetCurrentSurface();
    }

    private function forgetCurrentSurface() {
        _currentSurface = null;

        _currentSurfaceRemovedSlot.dispose();
        _currentSurfaceRemovedSlot = null;
        _currentSurfaceTargetRemovedSlot.dispose();
        _currentSurfaceTargetRemovedSlot = null;
    }
}
