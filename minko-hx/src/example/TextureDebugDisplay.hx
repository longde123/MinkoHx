package example;

import minko.file.Loader;
import minko.render.Texture;
import minko.scene.Node;
import minko.scene.Layout.BuiltinLayout;
import minko.geometry.QuadGeometry;
import minko.file.AssetLibrary;
import minko.material.Material;
import minko.component.Surface;
import minko.component.AbstractComponent;
class TextureDebugDisplay extends AbstractComponent {

    private var _surface:Surface;
    private var _material:Material;
    public var surface(get,null):Surface;
    function get_surface(){
        return _surface;
    }
    public var material(get,null):Material;
    function get_material(){
        return _material;
    }
    public function new() {
        super();
    }

    public static function create() :TextureDebugDisplay{
        return new TextureDebugDisplay();
    }

    public function initialize(assets:AssetLibrary, texture:Texture) {
        if (texture == null) {
            throw ("texture");
        }

        var geom = assets.geometry("debug-quad");

        if (geom==null) {
            geom = QuadGeometry.create(assets.context);
            assets.setGeometry("debug-quad", geom);
        }

        var fx = assets.effect("effect/debug/TextureDebugDisplay.effect");

        if (fx==null) {
            var loader =Loader.createbyLoader(assets.loader);

            loader.options.loadAsynchronously = (false);
            loader.queue("effect/debug/TextureDebugDisplay.effect");
            var _ = loader.complete.connect(function(loader) {
                fx = assets.effect("effect/debug/TextureDebugDisplay.effect");
            });
            loader.load();
        }

        _material = Material.create();
        _material.data.set("texture", texture);

        _surface = Surface.create(geom, _material, fx);
        _surface.layoutMask = (BuiltinLayout.DEBUG_ONLY);
    }

    override public function targetAdded(target:Node) {
        target.addComponent(_surface);
        target.layout = (target.layout | BuiltinLayout.DEBUG_ONLY);
    }

    override public function targetRemoved(target:Node) {
        target.removeComponent(_surface);
    }


}