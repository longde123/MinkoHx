package minko.component;
import glm.Mat4;
import minko.data.Provider;
import minko.data.Store;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
@:expose("minko.component.AbstractDiscreteLight")
class AbstractDiscreteLight extends AbstractLight {

    private var _modelToWorldChangedSlot:SignalSlot3<Store, Provider, String>;
    public var diffuse(get, set):Float;

    function get_diffuse() {
        return data.get("diffuse");
    }

    function set_diffuse(diffuse) {
        data.set("diffuse", diffuse);

        return diffuse;
    }

    public var specular(get, set):Float;

    function get_specular() {
        return data.get("specular");
    }

    function set_specular(specular) {
        data.set("specular", specular);
        return specular;
    }

    public function new(arrayName, diffuse = 1.0, specular = 1.0) {
        super(arrayName);
        data.set("diffuse", diffuse).set("specular", specular);
    }

    override public function targetAdded(target:Node) {
        super.targetAdded(target);
        _modelToWorldChangedSlot = target.data.getPropertyChanged("modelToWorldMatrix").connect(function(_1, _2, _3) {
            modelToWorldMatrixChangedHandler(_1, _3);
        });

        if (target.data.hasProperty("modelToWorldMatrix")) {
            updateModelToWorldMatrix(target.data.get("modelToWorldMatrix"));
        }
    }

    override public function targetRemoved(target:Node) {
        super.targetRemoved(target);
        _modelToWorldChangedSlot = null;
    }

    public function modelToWorldMatrixChangedHandler(container:Store, propertyName:String) {
        updateModelToWorldMatrix(container.get(propertyName));
    }

    public function updateModelToWorldMatrix(modelToWorld:Mat4) {

    }
}
