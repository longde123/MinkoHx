package minko.component;
import minko.data.Provider;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.render.Effect;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal;
@:expose("minko.component.Surface")
class Surface extends AbstractComponent {

    public static inline var SURFACE_COLLECTION_NAME = "surface";
    public static inline var GEOMETRY_COLLECTION_NAME = "geometry";
    public static inline var MATERIAL_COLLECTION_NAME = "material";
    public static inline var EFFECT_COLLECTION_NAME = "effect";

    private var _name:String;

    private var _geometry:Geometry;
    private var _material:Material;
    private var _effect:Effect;
    private var _technique:String;
    private var _provider:Provider;

    private var _geometryChanged:Signal<Surface>;
    private var _materialChanged:Signal<Surface>;
    private var _effectChanged:Signal<Surface>;

    private var _bubbleUpSlot:SignalSlot3<Node, Node, AbstractComponent>;

    override public function dispose() {
        super.dispose();
        _geometryChanged.dispose();
        _materialChanged.dispose();
        _effectChanged.dispose();

        _geometryChanged = null;
        _materialChanged =null;
        _effectChanged = null;

        _provider.dispose();
        _provider=null;
         _geometry=null;
       _material=null;
        _effect=null;
        _technique=null;
    }


    public function new(name, geometry, material, effect, technique) {
        super();
        this._name = name;
        this._geometry = geometry;
        this._material = material;
        this._effect = effect;
        this._provider = Provider.create();
        this._technique = technique;
        if (_effect != null && !_effect.hasTechnique(_technique)) {
            var message = "Effect " + _effect.name + " does not provide a '" + _technique + "' technique.";

            throw (message);
        }

        _geometryChanged = new Signal<Surface>();
        _materialChanged = new Signal<Surface>();
        _effectChanged = new Signal<Surface>();

        initializeIndexRange(geometry);
    }

    public static function create(geometry:Geometry, material:Material, effect:Effect = null, technique = "default", name = ""):Surface {
        return new Surface(name, geometry, material, effect, technique);
    }


    // TODO #Clone
    /*
			AbstractComponent::Ptr
			clone(const CloneOption& option);
			*/


    override function get_uuid() {
        return _provider.uuid;
    }

    public var name(get, set):String;

    function get_name() {
        return _name;
    }

    function set_name(value) {
        _name = value;
        return value;
    }

    public var data(get, null):Provider;

    function get_data() {
        return _provider;
    }
    public var geometry(get, set):Geometry;

    function get_geometry() {
        return _geometry;
    }

    public var firstIndex(null, set):Int;

    function set_firstIndex(index) {
        data.set("firstIndex", index);
        return index;
    }
    public var numIndices(null, set):Int;

    function set_numIndices(numIndices) {
        data.set("numIndices", numIndices);
        return numIndices;
    }

    public var material(get, set):Material;

    function get_material() {
        return _material;
    }


    public var effect(get, set):Effect;

    function set_effect(v) {
        _effect = v;
        return v;
    }

    function get_effect() {
        return _effect;
    }
    public var technique(get, null):String;

    function get_technique() {
        return _technique;
    }


    public var geometryChanged(get, null):Signal<Surface>;

    function get_geometryChanged() {
        return _geometryChanged;
    }
    public var materialChanged(get, null):Signal<Surface>;

    function get_materialChanged() {
        return _materialChanged;
    }
    public var effectChanged(get, null):Signal<Surface>;

    function get_effectChanged() {
        return _effectChanged;
    }


    override public function targetAdded(target:Node) {
        var targetData = target.data ;

        targetData.addProviderbyName(_provider, Surface.SURFACE_COLLECTION_NAME);
        targetData.addProviderbyName(_material.data, Surface.MATERIAL_COLLECTION_NAME);
        targetData.addProviderbyName(_geometry.data, Surface.GEOMETRY_COLLECTION_NAME);

        if (_effect != null) {
            targetData.addProviderbyName(_effect.data, Surface.EFFECT_COLLECTION_NAME);
        }
    }

    override public function targetRemoved(target:Node) {
        // Problem: if we remove the providers right away, all the other components and especially the Renderer and its
        // DrawCallPool will be "notified" by Store::propertyAdded/Removed signals. This will trigger a lot of useless
        // code since, as the Surface is actually being removed, all the corresponding DrawCalls will be removed from
        // the pool anyway.
        // Solution: we wait for the componentRemoved() signal on the target's root. That's the same signal the
        // Renderer is listening too, but with a higher priority. Thus, when we will remove the providers the corresponding
        // signals will be disconnected already.

        _bubbleUpSlot = target.root.componentRemoved.connect(function(n:Node, t:Node, c:AbstractComponent) {
            _bubbleUpSlot.dispose();
            _bubbleUpSlot = null;

            var targetData = target.data ;

            targetData.removeProviderbyName(_provider, Surface.SURFACE_COLLECTION_NAME);
            targetData.removeProviderbyName(_material.data, Surface.MATERIAL_COLLECTION_NAME);
            targetData.removeProviderbyName(_geometry.data, Surface.GEOMETRY_COLLECTION_NAME);

            if (_effect != null) {
                targetData.removeProviderbyName(_effect.data, Surface.EFFECT_COLLECTION_NAME);
            }
        });
    }


    function set_geometry(value) {
        if (value == _geometry) {
            return value;
        }

        var t = target ;

        if (t != null) {
            t.data.removeProviderbyName(_geometry.data, Surface.GEOMETRY_COLLECTION_NAME);
        }

        _geometry = value;

        if (t != null) {
            t.data.addProviderbyName(_geometry.data, Surface.GEOMETRY_COLLECTION_NAME);
        }

        initializeIndexRange(value);

        _geometryChanged.execute((this));
        return value;
    }

    function set_material(value) {
        if (value == _material) {
            return value;
        }

        var t = target;

        if (t != null) {
            t.data.removeProviderbyName(_material.data, Surface.MATERIAL_COLLECTION_NAME);
        }

        _material = value;

        if (t != null) {
            t.data.addProviderbyName(_material.data, Surface.MATERIAL_COLLECTION_NAME);
        }

        _materialChanged.execute((this));
        return value;
    }


    public function setEffectAndTechnique(effect:Effect, technique:String) {
        if (effect == null) {
            throw ("effect");
        }
        if (!effect.hasTechnique(technique)) {
            throw ("The effect \"" + effect.name + "\" does not provide the \"" + _technique + "\" technique.");
        }

        var changed = false;

        if (effect != _effect) {
            changed = true;

            if (target != null) {
                if (_effect != null) {
                    target.data.removeProviderbyName(_effect.data, Surface.EFFECT_COLLECTION_NAME);
                }

                if (effect != null) {
                    target.data.addProviderbyName(effect.data, Surface.EFFECT_COLLECTION_NAME);
                }
            }

            _effect = effect;
        }

        if (technique != _technique) {
            changed = true;
            _technique = technique;
            _provider.set("technique", technique);
        }

        if (changed) {
            _effectChanged.execute((this));
        }
    }

    public function initializeIndexRange(geometry:Geometry) {
        firstIndex = (0);
        numIndices = (geometry.data.hasProperty("numIndices") ? geometry.data.get("numIndices") : 0);
    }
}
