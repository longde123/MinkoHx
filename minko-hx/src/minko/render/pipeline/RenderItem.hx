package minko.render.pipeline;

import glm.Mat4;
import minko.geometry.Geometry;
import minko.material.Material;

class RenderItem {
    public var geometry:Geometry;
    public var material:Material;
    public var pipelineEffect:PipelineEffect;
    private var _worldMatrix:Mat4;
    public var normalMatrix:Mat4;
    public var layerMask:Int;
    public var renderPathMask:Int;
    public var castShadow:Bool;
    public var receiveShadow:Bool;
    public var depth:Float;

    public function new(geometry:Geometry, material:Material, pipelineEffect:PipelineEffect, worldMatrix:Mat4) {
        this.geometry = geometry;
        this.material = material;
        this.pipelineEffect = pipelineEffect;
        this.normalMatrix = null;
        this._worldMatrix = worldMatrix;
        this.layerMask = 0xffffffff;
        this.renderPathMask = 0xffffffff;
        this.castShadow = true;
        this.receiveShadow = true;
        this.depth = 0.0;
    }

    public var worldMatrix(get, set):Mat4;

    function get_worldMatrix() {
        return _worldMatrix;
    }

    function set_worldMatrix(value:Mat4) {
        _worldMatrix = value;
        normalMatrix = null;
        return value;
    }
}
