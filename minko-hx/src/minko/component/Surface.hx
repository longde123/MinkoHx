package minko.component;

import minko.geometry.Geometry;
import minko.material.Material;
import minko.render.pipeline.PipelineEffect;

/**
 * Geometry/material pair rendered by the new pipeline.
 *
 * The legacy Effect/technique and generic property-store bindings were removed
 * with the old renderer. Render items are collected directly from this
 * component.
 */
@:expose("minko.component.Surface")
class Surface extends AbstractComponent {
    private var _name:String;
    private var _geometry:Geometry;
    private var _material:Material;
    private var _pipelineEffect:PipelineEffect;

    public function new(geometry:Geometry, material:Material, ?pipelineEffect:PipelineEffect, name:String = "Surface") {
        super();
        _name = name;
        _geometry = geometry;
        _material = material;
        _pipelineEffect = pipelineEffect;
    }

    public static function create(geometry:Geometry, material:Material, ?pipelineEffect:PipelineEffect, ?name:String):Surface {
        return new Surface(geometry, material, pipelineEffect, name == null ? "Surface" : name);
    }

    override public function dispose():Void {
        _geometry = null;
        _material = null;
        _pipelineEffect = null;
        super.dispose();
    }

    public var name(get, set):String;

    function get_name() {
        return _name;
    }

    function set_name(value:String) {
        _name = value;
        return value;
    }

    public var geometry(get, set):Geometry;

    function get_geometry() {
        return _geometry;
    }

    function set_geometry(value:Geometry) {
        _geometry = value;
        return value;
    }

    public var material(get, set):Material;

    function get_material() {
        return _material;
    }

    function set_material(value:Material) {
        _material = value;
        return value;
    }

    public var pipelineEffect(get, set):PipelineEffect;

    function get_pipelineEffect() {
        return _pipelineEffect;
    }

    function set_pipelineEffect(value:PipelineEffect) {
        _pipelineEffect = value;
        return value;
    }
}
