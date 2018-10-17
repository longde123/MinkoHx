package minko.file;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import Lambda;
import minko.audio.Sound;
import minko.component.AbstractScript;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.CubeTexture;
import minko.render.Effect;
import minko.render.RectangleTexture;
import minko.render.Texture;
import minko.scene.Layout;
import minko.scene.Node;
import minko.signal.Signal2;
import minko.signal.Signal;
class AssetLibrary {
    private var _context:AbstractContext;
    private var _loader:Loader;
    private var _materials:StringMap< Material>;
    private var _geometries:StringMap<Geometry>;
    private var _effects:StringMap< Effect>;
    private var _textures:StringMap<Texture>;
    private var _cubeTextures:StringMap<CubeTexture>;
    private var _rectangleTextures:StringMap<RectangleTexture>;
    private var _symbols:StringMap<Node>;
    private var _blobs:StringMap<Bytes>;
    private var _scripts:StringMap<AbstractScript>;
    private var _layouts:StringMap<Int>;
    private var _sounds:StringMap<Sound>;
    private var _assetDescriptors:StringMap<AbstractAssetDescriptor>;
    private var _parserError:Signal2<AssetLibrary, AbstractParser>;
    private var _ready:Signal<AssetLibrary>;
    public var numGeometries(get, null):Int;

    function get_numGeometries() {
        return Lambda.count(_geometries);
    }
    public var numMaterials(get, null):Int;

    function get_numMaterials() {
        return Lambda.count(_materials);
    }
    public var numEffects(get, null):Int;

    function get_numEffects() {
        return Lambda.count(_effects);
    }
    public var numTextures(get, null):Int;

    function get_numTextures() {
        return Lambda.count(_textures);
    }
    public var context(get, null):AbstractContext;

    function get_context() {
        return _context;
    }
    public var loader(get, null):Loader;

    function get_loader() {
        return _loader;
    }


    static public function create(context):AssetLibrary {
        var al = new AssetLibrary(context);

        al._loader.options.context = (context);
        al._loader.options.assetLibrary = (al);

        return al;
    }

    static public function createbyAssetLibrary(original:AssetLibrary) {
        var al:AssetLibrary = create(original._context);

        for (it in original._materials.keys()) {
            al._materials.set(it, original._materials.get(it));
        }

        for (it in original._geometries.keys()) {
            al._geometries.set(it, original._geometries.get(it));
        }
        for (it in original._effects.keys()) {
            al._effects.set(it, original._effects.get(it));
        }
        for (it in original._textures.keys()) {
            al._textures.set(it, original._textures.get(it));
        }

        for (it in original._cubeTextures.keys()) {
            al._cubeTextures.set(it, original._cubeTextures.get(it));
        }

        for (it in original._rectangleTextures.keys()) {
            al._rectangleTextures.set(it, original._rectangleTextures.get(it));
        }

        for (it in original._symbols.keys()) {
            al._symbols.set(it, original._symbols.get(it));
        }
        for (it in original._blobs.keys()) {
            al._blobs.set(it, original._blobs.get(it));
        }

        for (it in original._scripts.keys()) {
            al._scripts.set(it, original._scripts.get(it));
        }

        for (it in original._layouts.keys()) {
            al._layouts.set(it, original._layouts.get(it));
        }

        for (it in original._assetDescriptors.keys()) {
            al._assetDescriptors.set(it, original._assetDescriptors.get(it));
        }


        return al;
    }

    public function new(context:AbstractContext) {
        this._context = context;
        this._loader = Loader.create();
        this._materials = new StringMap< Material>();
        this._geometries = new StringMap<Geometry>();
        this._effects = new StringMap< Effect>();
        this._textures = new StringMap<Texture>();
        this._cubeTextures = new StringMap<CubeTexture>();
        this._rectangleTextures = new StringMap<RectangleTexture>();
        this._symbols = new StringMap<Node>();
        this._blobs = new StringMap<Bytes>();
        this._scripts = new StringMap<AbstractScript>();
        this._layouts = new StringMap<Int>();
        this._sounds = new StringMap<Sound>();
        this._assetDescriptors = new StringMap<AbstractAssetDescriptor>();
        this._parserError = new Signal2<AssetLibrary, AbstractParser>();
        this._ready = new Signal<AssetLibrary>();
    }

    public function disposeLoader() {
        _loader = null;
    }

    public function geometry(name) {
        return _geometries.exists(name) ? _geometries.get(name) : null;
    }

    public function setGeometry(name, geometry):AssetLibrary {
        var tempname = name;
        if (_geometries.exists(tempname)) {
            tempname = tempname + "_" + numGeometries;
        }

        _geometries.set(tempname, geometry);

        return this;
    }

    public function geometryName(geometry:Geometry) {

        for (it in _geometries.keys()) {
            var itr = _geometries.get(it);
            if (itr == geometry) {
                return it;
            }
        }
        throw ("AssetLibrary does not reference this geometry.");
    }

    public function texture(name):Texture {
        var foundTextureIt = _textures.exists(name);

        return foundTextureIt ? _textures.get(name) : null;
    }

    public function setTexture(name, texture) {
        _textures.set(name, texture);

        return this;
    }

    public function getTextureByUuid(uuid, failIfNotReady) {
        var it = Lambda.find(_textures, function(t:Texture) {
            return t.sampler.uuid == uuid && (!failIfNotReady || t.isReady);
        });

        return it;
    }

    public function cubeTexture(name) {
        var foundTextureIt = _cubeTextures.exists(name);

        return foundTextureIt ? _cubeTextures.get(name) : null;
    }

    public function setCubeTexture(name, texture) {
        _cubeTextures.set(name, texture);

        return this;
    }

    public function rectangleTexture(name) {
        var foundTextureIt = _rectangleTextures.exists(name);

        return foundTextureIt ? _rectangleTextures.get(name) : null;
    }

    public function setRectangleTexture(name, texture) {
        _rectangleTextures.set(name, texture);

        return this;
    }

    public function textureName(texture:AbstractTexture) {
        for (it in _textures.keys()) {
            var itr = _textures.get(it);
            if (itr == texture)
                return it;
        }


        throw ("AssetLibrary does not reference this texture.");
    }

    public function symbol(name) {
        return _symbols.exists(name) ? _symbols.get(name) : null;
    }

    public function setSymbol(name, node) {
        _symbols.set(name, node);

        return this;
    }

    public function symbolName(node) {
        for (it in _symbols.keys()) {
            var itr = _symbols.get(it);
            if (itr == node)
                return it;
        }


        throw ("AssetLibrary does not reference this symbol.");
    }

    public function material(name) {
        return _materials.exists(name) ? _materials.get(name) : null;
    }

    public function setMaterial(name, material):AssetLibrary {
        var mat = (material);

        #if DEBUG
		if (mat == null)
		{
			throw new System.ArgumentException("material");
		}
	#end

        _materials.set(name, material);

        return this;
    }


    public function materialName(material) {
        for (it in _materials.keys()) {
            var itr = _materials.get(it);
            if (itr == material) {
                return it;
            }
        }


        throw ("AssetLibrary does not reference this material.");
    }

    public function effect(name) {
        return _effects.exists(name) ? _effects.get(name) : null;
    }

    public function setEffect(name, effect) {
        _effects.set(name, effect);

        return this;
    }

    public function effectName(effect:Effect) {
        for (it in _effects.keys()) {
            var itr = _effects.get(it);
            if (itr == effect) {
                return it;
            }
        }


        throw ("AssetLibrary does not reference this effect.");
    }

    public function hasBlob(name) {
        return _blobs.exists(name) ;
    }

    public function blob(name) {
        if (!_blobs.exists(name)) {
            throw "";
        }

        return _blobs.get(name);
    }

    public function setBlob(name, blob) {
        _blobs.set(name, blob);

        return this;
    }

    public function script(name) {
        return _scripts.exists(name) ? _scripts.get(name) : null;
    }

    public function setScript(name, script) {
        _scripts.set(name, script);

        return this;
    }

    public function scriptName(script) {

        for (it in _scripts.keys()) {
            var itr = _scripts.get(it);
            if (itr == script) {
                return it;
            }
        }
        throw ("AssetLibrary does not reference this script.");
    }

    public function layout(name) {
        if (_layouts.exists(name) == false) {
            var existingMask:Layout = 0;

            for (layout in _layouts.keys()) {
                existingMask |= _layouts.get(layout);
            }

            var mask:Layout = 1;
            var i = 0;
            while (i < 32 && (existingMask & mask) == 1) {
                ++i;
                mask <<= 1;
                continue;
            }

            if (mask == 0) {
                throw "";
            }

            _layouts.set(name, mask);
        }

        return _layouts.get(name);
    }

    public function setLayout(name, mask) {
        _layouts.set(name, mask);

        return this;
    }

    public function sound(name) {
        return _sounds.get(name);
    }

    public function setSound(name, sound) {
        _sounds.set(name, sound);
        return this;
    }

    public function assetDescriptor(name) {
        return _assetDescriptors.exists(name) ? _assetDescriptors.get(name) : null;
    }

    public function setAssetDescriptor(name, assetDescriptor) {
        _assetDescriptors.set(name, assetDescriptor);
        return this;
    }
}
