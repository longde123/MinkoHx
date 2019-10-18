package assimp.format.gltf2.types;

import String;
import String;
import assimp.format.gltf2.schema.GLTF.TMeshPrimitiveType;
import assimp.format.gltf2.schema.GLTF.TMeshPrimitive;
import haxe.ds.Vector;

typedef TAttribute = {
    var name:String;
    var accessor:Accessor;
}
typedef TAccessorList = Array<TAttribute> ;
typedef TAccessorListAndIndex = {
    var index:Int;
    var list:Null<TAccessorList>;
}
class TAttributes {
    public var position:Null<TAccessorList>;
    public var normal:Null<TAccessorList>;
    public var tangent:Null<TAccessorList>;
    public var texcoord:Null<TAccessorList>;
    public var color:Null<TAccessorList>;
    public var joint:Null<TAccessorList>;
    public var jointmatrix:Null<TAccessorList>;
    public var weight:Null<TAccessorList>;

    public function new() {
        position = new TAccessorList();
        normal = new TAccessorList();
        tangent = new TAccessorList();
        texcoord = new TAccessorList();
        color = new TAccessorList();
        joint = new TAccessorList();
        jointmatrix = new TAccessorList();
        weight = new TAccessorList();
    }
}

class TTarget {
    public var position:Null<TAccessorList>;
    public var normal:Null<TAccessorList>;
    public var tangent:Null<TAccessorList>;

    public function new() {
        position = new TAccessorList();
        normal = new TAccessorList();
        tangent = new TAccessorList();
    }
}
@:allow(assimp.format.gltf2.types.Mesh)
class MeshPrimitive {

    function getAttribVector(attr:String):TAccessorListAndIndex {
        var name = attr;
        var idx = 0;
        if (attr.indexOf("_") != -1) {
            name = attr.substr(0, attr.indexOf("_"));
            idx = Std.parseInt(attr.substr(attr.indexOf("_") + 1));
        }

        var aList:Null<TAccessorList> = switch(name){
            case "POSITION": attributes.position;
            case "NORMAL": attributes.normal;
            case "TANGENT":attributes.tangent ;
            case "TEXCOORD": attributes.texcoord;
            case "COLOR":attributes.color;
            case "JOINTS" | "JOINT":attributes.joint;
            case "JOINTMATRIX":attributes.jointmatrix;
            case "WEIGHTS" | "WEIGHT":attributes.weight;
            default:null;
        }

        return {
            index:idx,
            list:aList
        };


    }

    function getAttribTargetVector(targetIndex:Int, attr:String):TAccessorListAndIndex {
        var target:TTarget = targets[targetIndex];
        var name = attr;
        var idx = 0;
        if (attr.indexOf("_") != -1) {
            name = attr.substr(0, attr.indexOf("_"));
            idx = Std.parseInt(attr.substr(attr.indexOf("_") + 1));
        }

        var aList:Null<TAccessorList> = switch(name){
            case "POSITION":target.position;
            case "NORMAL":target.normal;
            case "TANGENT":target.tangent;
            default:null;
        }
        return {
            index:idx,
            list:aList
        };

    }
    public var attributes(default, null):TAttributes = null;
    public var targets(default, null):Vector<TTarget> = null;

    public var indices(default, null):Null<Accessor> = null;
    public var material(default, null):Null<Material> = null;
    public var mode(default, null):Null<TMeshPrimitiveType> = null;


    function new() {

    }

    function load(gltf:GLTF2, primitive:TMeshPrimitive):Void {
        // load the attributes
        var names:Array<String> = Reflect.fields(primitive.attributes);
        attributes = new TAttributes();//names.length);
        for (i in 0...names.length) {
            var aid:Int = Reflect.field(primitive.attributes, names[i]);
            var vec:TAccessorListAndIndex = getAttribVector(names[i]);
            vec.list[vec.index] = {
                name: names[i],
                accessor: gltf.accessors[aid]
            };
        }
        // load the targets
        if (primitive.targets != null) {
            targets = new Vector<TTarget>(primitive.targets.length);//Vector<TAttribute>(targets_names.length);
            for (targetIndex in 0...primitive.targets.length) {
                var target = primitive.targets[targetIndex];
                var targets_names:Array<String> = Reflect.fields(target);
                for (i in 0...targets_names.length) {
                    var aid:Int = Reflect.field(target, targets_names[i]);
                    var vec:TAccessorListAndIndex = getAttribTargetVector(targetIndex, targets_names[i]);
                    vec.list[vec.index] = {
                        name: targets_names[i],
                        accessor: gltf.accessors[aid]
                    };
                }
            }

        }

        mode = primitive.mode != null ? primitive.mode : TMeshPrimitiveType.TRIANGLES;

        if (primitive.indices != null) indices = gltf.accessors[primitive.indices];
        if (primitive.material != null) material = gltf.materials[primitive.material];
    }

}
