package minko.scene;
class NodeSet extends Node {
    private var _nodes:Array<Node> ;
    public var nodes(get, null):Array<Node>;

    function get_nodes() {
        return _nodes;
    }

    public function new() {
        super();
        _nodes = new Array<Node>();
    }


    override    public function dispose() {
        super.dispose();
        _nodes = null;
    }

    public static function createbyArray(nodes:Array<Node>) {
        var set:NodeSet = new NodeSet();

        set.nodes = nodes.concat([]);

        return set;
    }


    public static function create():NodeSet {
        var set:NodeSet = new NodeSet();

        return set;
    }

    public static function createbyNode(node:Node):NodeSet {
        var set:NodeSet = new NodeSet();

        set.nodes.push(node);

        return set;
    }


    public function size() {
        return _nodes.length;
    }

    public function descendants(andSelf:Bool, ?depthFirst:Bool = false, ?result:NodeSet = null):NodeSet {
        if (result == null) {
            result = create();
        }

        var nodesStack = new Array<Node>();

        for (node in _nodes) {
            nodesStack.push(node);

            while (nodesStack.length != 0) {
                var descendant = nodesStack.shift();
                if (descendant != node || andSelf) {
                    result._nodes.push(descendant);
                }


                nodesStack = (depthFirst ? descendant.children.concat(nodesStack) : nodesStack.concat(descendant.children) );
            }
        }

        return result;
    }

    public function ancestors(?andSelf:Bool = false, ?result:NodeSet = null) {
        if (result == null) {
            result = create();
        }

        for (node in _nodes) {
            if (andSelf) {
                result._nodes.push(node);
            }

            while (node != null) {
                if (node.parent != null) {
                    result._nodes.push(node.parent);
                }
                node = node.parent;
            }
        }

        return result;
    }

    public function childrens(andSelf:Bool, result:NodeSet) {
        if (result == null) {
            result = create();
        }

        for (node in _nodes) {
            if (andSelf) {
                result._nodes.push(node);
            }

            result._nodes = result._nodes.concat(node.children);
        }

        return result;
    }

    public function where(filter:Node -> Bool, ?result:NodeSet = null) {
        if (result == null) {
            result = create();
        }

        for (node in _nodes) {
            if (filter(node)) {
                result._nodes.push(node);
            }
        }

        return result;
    }

    public function roots(?result:NodeSet) {
        if (result == null) {
            result = create();
        }

        for (node in _nodes) {
            if (result._nodes.indexOf(node.root) == -1) {
                result._nodes.push(node.root);
            }
        }

        return result;
    }


}
