package minko.scene;

import haxe.ds.ObjectMap;
import Lambda;
import minko.component.AbstractComponent;
import minko.data.Store;
import minko.scene.Layout.BuiltinLayout;
import minko.signal.Signal2;
import minko.signal.Signal3;
import minko.Uuid.Enable_uuid;
@:expose("minko.scene.Node")
class Node extends Enable_uuid {

    private var _name:String;
    private var _children:Array<Node>;
    private var _root:Node;
    private var _parent:Node;
    private var _container:Store;
    private var _components:Array<AbstractComponent>;
    private var _layout:Layout;
    private var _added:Signal3<Node, Node, Node>;
    private var _removed:Signal3<Node, Node, Node>;
    private var _layoutChanged:Signal2<Node, Node>;
    private var _componentAdded:Signal3<Node, Node, AbstractComponent>;
    private var _componentRemoved:Signal3<Node, Node, AbstractComponent>;

    public static function create(n = ""):Node {

        var node = new Node(n);
        node._root = node;
        return node;
    }

    public static function createbyLayout(n:String, l:Layout):Node {

        var node = new Node(n);
        node._root = node;
        node.layout = l;
        return node;
    }

    public function new(?n = "") {
        super();
        this._name = n;
        this._layout = BuiltinLayout.DEFAULT;
        _children = [];
        _container = new Store();
        _components = [];
        _added = new Signal3<Node, Node, Node>();
        _removed = new Signal3<Node, Node, Node>();
        _layoutChanged = new Signal2<Node, Node>();
        _componentAdded = new Signal3<Node, Node, AbstractComponent>();
        _componentRemoved = new Signal3<Node, Node, AbstractComponent>();
    }

    public function clone(option:CloneOption):Node {
        var clone = cloneNode();
        var nodeMap:ObjectMap<Node, Node> = new ObjectMap<Node, Node>(); // map linking nodes to their clone
        var componentsMap:ObjectMap<AbstractComponent, AbstractComponent> = new ObjectMap<AbstractComponent, AbstractComponent>(); // map linking components to their clone

        listItems(clone, nodeMap, componentsMap);

        rebindComponentsDependencies(componentsMap, nodeMap, option);

        for (itn in nodeMap.keys()) {
            var node = itn;

            var originComponents:Array<AbstractComponent> = cast node.getComponents(AbstractComponent);

            for (itc in componentsMap.keys()) {
                var component = itc;

                // if the current node has a particular component, we clone it
                if (Lambda.has(originComponents, component)) {
                    nodeMap.get(node).addComponent(componentsMap.get(component));
                }
            }
        }

        return nodeMap.get(this);
    }

    public function cloneNode() {
        var clone = Node.create();

        clone._name = this.name + "_clone";

        for (child in children) {
            clone.addChild(child.cloneNode());
        }

        return clone;
    }

    public function listItems(clonedRoot:Node, nodeMap:ObjectMap<Node, Node>, components:ObjectMap<AbstractComponent, AbstractComponent>) {
        for (component in _components) {
            components.set(component, component.clone(CloneOption.DEEP));
        }

        nodeMap.set(this, clonedRoot);

        for (childId in 0...children.length) {
            var child = children[childId];
            var clonedChild = clonedRoot.children[childId];

            child.listItems(clonedChild, nodeMap, components);
        }
    }

    public function rebindComponentsDependencies(componentsMap:ObjectMap<AbstractComponent, AbstractComponent>, nodeMap:ObjectMap<Node, Node>, option:Int) {
        for (comp in componentsMap.keys()) {
            var compClone:AbstractComponent = cast(componentsMap.get(comp), AbstractComponent);

            if (compClone != null) {
                compClone.rebindDependencies(componentsMap, nodeMap, option);
            }
        }
    }

    public var name(get, set):String;

    public function get_name() {
        return _name;
    }

    public function set_name(v) {
        _name = v;
        return v;
    }

    public var layout(get, set):Layout;

    public function get_layout() {
        return _layout;
    }

    public function set_layout(v:Layout) {
        if (v != _layout) {
            _layout = v;

            // bubble down
            var descendants:NodeSet = NodeSet.createbyNode(this).descendants(true);
            for (descendant in descendants.nodes) {
                descendant._layoutChanged.execute(descendant, this);
            }

            // bubble up
            var ancestors:NodeSet = NodeSet.createbyNode(this).ancestors();
            for (ancestor in ancestors.nodes) {
                ancestor._layoutChanged.execute(ancestor, this);
            }
        }

        return v;
    }

    public var parent(get, null):Node;

    function get_parent() {
        return _parent ;
    }

    public var root(get, null):Node;

    function get_root() {
        return _root ;
    }

    public var children(get, null):Array<Node>;

    function get_children() {
        return _children;
    }
    public var data(get, null):Store;

    function get_data() {
        return _container;
    }

    public var added(get, null):Signal3<Node, Node, Node>;

    function get_added() {
        return _added;
    }

    public var removed(get, null):Signal3<Node, Node, Node>;

    function get_removed() {
        return _removed;
    }
    public var layoutChanged(get, null):Signal2<Node, Node>;

    function get_layoutChanged() {
        return _layoutChanged;
    }
    public var componentAdded(get, null):Signal3<Node, Node, AbstractComponent>;

    function get_componentAdded() {
        return _componentAdded;
    }

    public var componentRemoved(get, null):Signal3<Node, Node, AbstractComponent>;

    function get_componentRemoved() {
        return _componentRemoved;
    }

    public function addChild(child:Node):Node {
        if (child.parent != null) {
            child.parent.removeChild(child);
        }

        _children.push(child);

        child._parent = this;
        child.updateRoot();

        // bubble down
        var descendants:NodeSet = NodeSet.createbyNode(child).descendants(true);
        for (descendant in descendants.nodes) {
            descendant._added.execute(descendant, child, this);
        }

        // bubble up
        var ancestors:NodeSet = NodeSet.createbyNode(this).ancestors(true);
        for (ancestor in ancestors.nodes) {
            ancestor._added.execute(ancestor, child, this);
        }

        return this;
    }

    public function removeChild(child:Node) {
        var it = Lambda.has(_children, child);

        if (it == false) {
            throw ("child");
        }
        _children.remove(child);

        child._parent = null;
        child.updateRoot();

        // bubble down
        var descendants:NodeSet = NodeSet.createbyNode(child).descendants(true);
        for (descendant in descendants.nodes) {
            descendant._removed.execute(descendant, child, this);
        }

        // bubble up
        var ancestors:NodeSet = NodeSet.createbyNode(this).ancestors(true);
        for (ancestor in ancestors.nodes) {
            ancestor._removed.execute(ancestor, child, this);
        }

        return this;
    }

    public function removeChildren() {
        var numChildren = _children.length;

        var i = numChildren - 1;
        while (i >= 0) {
            removeChild(_children[i]);
            --i;
        }

        return this;
    }

    public function contains(node:Node) {
        return Lambda.has(_children, node);
    }

    public function addComponent(component:AbstractComponent):Node {
        if (component == null) {
            throw ("component");
        }
        var it = Lambda.has(_components, component);
        if (it) {
            throw ("The same component cannot be added twice.");
        }

        if (component.target != null) {
            component.target.removeComponent(component);
        }
        _components.push(component);
        component.target = (this);

        // bubble down
        var descendants:NodeSet = NodeSet.createbyNode(this).descendants(true);
        for (descendant in descendants.nodes) {
            descendant._componentAdded.execute(descendant, this, component);
        }

        // bubble up
        var ancestors:NodeSet = NodeSet.createbyNode(this).ancestors();
        for (ancestor in ancestors.nodes) {
            ancestor._componentAdded.execute(ancestor, this, component);
        }

        return this;
    }

    public function removeComponent(component:AbstractComponent) {
        if (component == null) {
            throw ("component");
        }

        var it = Lambda.has(_components, component);

        if (it == false) {
            throw ("component");
        }

        _components.remove(component);
        component.target = (null);

        // bubble down
        var descendants:NodeSet = NodeSet.createbyNode(this).descendants(true);
        for (descendant in descendants.nodes) {
            descendant._componentRemoved.execute(descendant, this, component);
        }
        var ancestor = parent;
        // bubble up
        while (ancestor != null) {
            ancestor._componentRemoved.execute(ancestor, this, component);
            ancestor = ancestor.parent;
        }

        return this;
    }

    public function existsComponent(c:AbstractComponent) {
        return Lambda.has(_components, c);
    }

    public function hasComponent(cClass:Class<AbstractComponent>) {
        return Lambda.exists(_components, function(c:AbstractComponent) {
            return Std.is(c, cClass);
        });
    }

    public function getComponent(cClass:Class<AbstractComponent>) {
        return Lambda.find(_components, function(c:AbstractComponent) {
            return Std.is(c, cClass);
        });
    }

    public function getComponents(cClass:Class<AbstractComponent>):Array<AbstractComponent> {
        return _components.filter(function(c:AbstractComponent) {

            return Std.is(c, cClass);
        });
    }


    public var components(get, null):Array<AbstractComponent>;

    function get_components() {
        return _components;
    }


    public function setNode(uuid, name) {
        this.uuid = uuid;
        this._name = name;
        this._layout = BuiltinLayout.DEFAULT;
    }

    public function updateRoot() {
        _root = (parent != null ? (parent.root != null ? parent._root : _parent) : this);

        for (child in _children) {
            child.updateRoot();
        }
    }

    public function dispose():Void {
        for (child in _children) {
            child.dispose();
        }
        for(component in _components){
            removeComponent(component);
            component.dispose();
        }
        _container.dispose();

        _added.dispose();
        _removed.dispose();
        _layoutChanged.dispose();
        _componentAdded.dispose();
        _componentRemoved.dispose();

        _children=null;
        _components=null;
        _container=null;

        _added=null;
        _removed=null;
        _layoutChanged=null;
        _componentAdded=null;
        _componentRemoved=null;
    }
}
