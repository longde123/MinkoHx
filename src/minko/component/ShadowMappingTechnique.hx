package minko.component;


import minko.data.Provider;
import minko.scene.Node;

@:enum abstract Technique(Int) from Int to Int{

    var DEFAULT = 0;
    var ESM = 1;
    var PCF = 2;
    var PCF_POISSON = 3;
}
class ShadowMappingTechnique extends AbstractComponent {

    private var _technique:Int;
    private var _data:Provider;

    public static function create(technique:Int) {
        return new ShadowMappingTechnique(technique);
    }

    public function new(technique:Int) {
        super();
        this._technique = technique;
        this._data = Provider.create();
        _data.set("shadowMappingTechnique", technique);
    }

    override public function targetAdded(target:Node) {
        target.data.addProvider(_data);
    }

}
