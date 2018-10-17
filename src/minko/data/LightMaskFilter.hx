package minko.data;
import haxe.ds.ObjectMap;
import minko.component.AbstractLight;
import minko.scene.Node;
import minko.scene.NodeSet;
class LightMaskFilter extends AbstractFilter {


    private static var _numLightPropertyNames = new Array<String>();

    private var _target:Node;
    private var _root:Node;
    private var _providerToLight:ObjectMap<Provider, AbstractLight>;

    private var _rootPropertyChangedSlots:List<SignalSlot<Store, Provider, String>>;

    private var _layoutMaskChangedSlots:List<SignalSlot<Provider, String>>;

    public static function create(root:Node = null):LightMaskFilter {
        var ptr = new LightMaskFilter();
        ptr.watchProperty("node.layouts");
        ptr.root = (root);
        return ptr;
    }
    public var root(get, set):Node ;

    function get_root() {
        return _root;
    }

    function set_root(v) {
        _root = v;
    }

    public function new() {
        this._target = null;
        this._root = null;
        this._providerToLight = new ObjectMap<Provider, component.AbstractLight>();
        this._rootPropertyChangedSlots = new List<SignalSlot<Store, Provider, String>>();
    }

    private function reset() {
        _root = null;
        _providerToLight = new ObjectMap<Provider, component.AbstractLight>();
        _rootPropertyChangedSlots.clear();
    }

    private function lightsChangedHandler() {
        if (_root == null) {
            return;
        }
        _layoutMaskChangedSlots.clear();
        _providerToLight = new ObjectMap<Provider, component.AbstractLight>();
        var withLights = NodeSet.create(_root).descendants(true).where(function(n:Node) {
            return n.hasComponent(AbstractLight);
        });

        // FIXME
        //for (auto& n : withLights->nodes())
        //{
        //	auto light = n->component<AbstractLight>();

        //	_providerToLight[light->data()] = light;

        //	_layoutMaskChangedSlots.push_back(light->data()->propertyChanged()->connect([=](Provider::Ptr provider, const std::string& lightProperty)
        //	{
        //		changed()->execute(shared_from_this(), nullptr);
        //	}));
        //}
    }

    private static function initializeNumLightPropertyNames() {
        var names = new Array<String>();

        names.push("ambientLights.length");
        names.push("directionalLights.length");
        names.push("pointLights.length");
        names.push("spotLights.length");

        return names;
    }
}
