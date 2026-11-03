package minko.render.pipeline;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.component.PerspectiveCamera;
import minko.component.Surface;
import minko.component.Transform;
import minko.component.Transform.RootTransform;
import minko.material.PBRMaterial;
import minko.material.PhongMaterial;
import minko.scene.Node;
import minko.scene.NodeSet;

/**
 * Builds a RenderQueue from a scene graph.
 *
 * World transforms come from each node's Transform; nodes without a Transform
 * use identity.
 */
class SceneCollector {
    public static function collect(root:Node, queue:RenderQueue):PerspectiveCamera {
        queue.clear();
        if (root == null) {
            return null;
        }

        var camera:PerspectiveCamera = null;
        var rootTransform = root.getComponent(RootTransform);
        var nodes = NodeSet.createbyNode(root).descendants(true).nodes;

        for (node in nodes) {
            var nodeCamera = node.getComponent(PerspectiveCamera);
            if (camera == null && nodeCamera != null) {
                camera = cast nodeCamera;
            }

            var transform:Transform = cast(node.getComponent(Transform), Transform);
            var world:Mat4 = null;
            if (transform != null) {
                world = rootTransform != null ? transform.modelToWorldMatrix : transform.matrix;
            }

            for (component in node.components) {
                if (!Std.isOfType(component, Surface)) {
                    continue;
                }
                var surface = cast(component, Surface);
                if (surface.geometry == null) {
                    continue;
                }

                if (world == null) {
                    world = Mat4.identity(new Mat4());
                }

                var item = new RenderItem(surface.geometry, surface.material, surface.pipelineEffect, world);
                var transparent = false;
                if (surface.material != null && surface.material.hasProperty(PBRMaterial.BASE_COLOR)) {
                    var baseColor = surface.material.get(PBRMaterial.BASE_COLOR);
                    if (baseColor != null) {
                        transparent = (cast baseColor : Vec4).w < 1.0;
                    }
                }
                else if (surface.material != null && surface.material.hasProperty(PhongMaterial.ALPHA)) {
                    var alpha = surface.material.get(PhongMaterial.ALPHA);
                    if (alpha != null) {
                        transparent = (cast alpha : Float) < 1.0;
                    }
                }
                queue.add(item, transparent);
            }
        }

        return camera;
    }
}
