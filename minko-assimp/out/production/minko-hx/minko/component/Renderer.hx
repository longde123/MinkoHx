package minko.component;
import Array;
import glm.Vec4;
import haxe.ds.ObjectMap;
import minko.data.AbstractFilter;
import minko.data.Binding.Source;
import minko.data.Binding;
import minko.data.Provider;
import minko.data.Store;
import minko.geometry.Geometry;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.DrawCall;
import minko.render.DrawCallPool;
import minko.render.Effect;
import minko.render.VertexBuffer;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Layout;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal4;
import minko.signal.Signal;
typedef EffectVariables = Array<Tuple<String, String>>;
@:expose("minko.component.Renderer")
class Renderer extends AbstractComponent {
    private var _name:String;

    private var _backgroundColor:Int;
    private var _viewportBox:Vec4;
    private var _scissorBox:Vec4 ;
    private var _sceneManager:SceneManager;
    private var _renderingBegin:Signal<Renderer>;
    private var _renderingEnd:Signal<Renderer>;
    private var _beforePresent:Signal<Renderer>;
    private var _renderTarget:AbstractTexture;
    private var _clearBeforeRender:Bool;
    private var _variables:EffectVariables;

    private var _toCollect:Array<Surface>;
    private var _effect:Effect;
    private var _effectTechnique:String;
    private var _priority:Float;
    private var _enabled:Bool;
    private var _postProcessingGeom:Geometry;
    private var _mustZSort:Bool;

    private var _drawCallToZSortNeededSlot:ObjectMap<DrawCall, SignalSlot<DrawCall>>;

    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;
    private var _rootDescendantAddedSlot:SignalSlot3<Node, Node, Node>;
    private var _rootDescendantRemovedSlot:SignalSlot3<Node, Node, Node>;
    private var _componentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _componentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _renderingBeginSlot:SignalSlot3<SceneManager, Int, AbstractTexture>;
    private var _surfaceChangedSlots:ObjectMap<Surface, Array<SignalSlot<Surface>>>;
    private var _worldToScreenMatrixPropertyChangedSlot:SignalSlot3<Store, Provider, String>;

    private var _drawCallPool:DrawCallPool;
    private var _surfaceToDrawCallIterator:ObjectMap<Surface, Int>;

    /*std::set<AbsFilterPtr>										        _targetDataFilters;
			std::set<AbsFilterPtr>										            _rendererDataFilters;
			std::set<AbsFilterPtr>										            _rootDataFilters;
			std::shared_ptr<data::LightMaskFilter>						            _lightMaskFilter;*/

    /*std::unordered_map<AbsFilterPtr, FilterChangedSlot>			        _targetDataFilterChangedSlots;
			std::unordered_map<AbsFilterPtr, FilterChangedSlot>			            _rendererDataFilterChangedSlots;
			std::unordered_map<AbsFilterPtr, FilterChangedSlot>			            _rootDataFilterChangedSlots;*/

    private var _filterChanged:Signal4<Renderer, AbstractFilter, Source, Surface>;
    private var _nodeLayoutChangedSlot:ObjectMap<Node, SignalSlot2<Node, Node>>;
    private var _surfaceLayoutMaskChangedSlot:ObjectMap<Surface, SignalSlot<AbstractComponent>> ;

    private var _numDrawCalls:Int;
    private var _numTriangles:Int;

    public function new(renderTarget:AbstractTexture, effect:Effect, effectTechnique:String, priority:Float)
        //_surfaceTechniqueChangedSlot(),
        /*_targetDataFilters(),
		_rendererDataFilters(),
		_rootDataFilters(),
		_targetDataFilterChangedSlots(),
		_rendererDataFilterChangedSlots(),
		_rootDataFilterChangedSlots(),
		_lightMaskFilter(data::LightMaskFilter::create()),*/ {
        enable_uuid();
        super(cast BuiltinLayout.DEFAULT);
        this._backgroundColor = 0;
        this._viewportBox = new Vec4(0, 0, -1, -1);
        this._scissorBox = new Vec4(0, 0, -1, -1);
        this._enabled = true;
        this._mustZSort = true;
        this._renderingBegin = new Signal<Renderer>();
        this._renderingEnd = new Signal<Renderer>();
        this._beforePresent = new Signal<Renderer>();
        this._effect = effect;
        this._effectTechnique = effectTechnique;
        this._clearBeforeRender = true;
        this._priority = priority;
        this._renderTarget = renderTarget;
        this._postProcessingGeom = null;
        this._filterChanged = new Signal4<Renderer, AbstractFilter, Source, Surface>();
        this._numDrawCalls = 0;
        this._numTriangles = 0;
        this._drawCallPool = new DrawCallPool();

        this._name = "";
        this._sceneManager = null;
        this._variables = new EffectVariables();

        this._toCollect = new Array<Surface>();


        this._drawCallToZSortNeededSlot = new ObjectMap<DrawCall, SignalSlot<DrawCall>>();


        this._surfaceChangedSlots = new ObjectMap<Surface, Array<SignalSlot<Surface>>>();

        this._surfaceToDrawCallIterator = new ObjectMap<Surface, Int>();


        this._filterChanged = new Signal4<Renderer, AbstractFilter, Source, Surface>();
        this._nodeLayoutChangedSlot = new ObjectMap<Node, SignalSlot2<Node, Node>>();
        this._surfaceLayoutMaskChangedSlot = new ObjectMap<Surface, SignalSlot<AbstractComponent>>() ;

    }

    static public function create(backgroundColor = 0x000000,
                                  renderTarget = null,
                                  effect = null,
                                  effectTechnique = "default",
                                  priority = 0.0,
                                  name = ""):Renderer {
        var ctrl:Renderer = new Renderer(renderTarget, effect, effectTechnique, priority) ;

        ctrl.backgroundColor = (backgroundColor);
        ctrl.name = (name);

        return ctrl;
    }

    public var effect(get, set):Effect;

    function get_effect() {
        return _effect;
    }

    function set_effect(v:Effect) {
        changeEffectOrTechnique(v, _effectTechnique);
        return v;
    }

    public function setEffect(effect, technique) {
        changeEffectOrTechnique(effect, technique);
    }
    public var numDrawCalls(get, null):Int;

    function get_numDrawCalls() {
        return _numDrawCalls;
    }
    public var numTriangles(get, null):Int;

    function get_numTriangles() {
        return _numTriangles;
    }
    public var backgroundColor(get, set):Int;

    function get_backgroundColor() {
        return _backgroundColor;
    }

    function set_backgroundColor(value) {
        _backgroundColor = value;
        return value;
    }
    public var name(get, set):String;

    function set_name(value) {
        _name = value;
        return value;
    }

    function get_name() {
        return _name;
    }
    public var priority(get, set):Float;

    function get_priority() {
        return _priority;
    }

    function set_priority(value) {
        _priority = value;
        return value;
    }
    public var viewport(null, set):Vec4;

    function set_viewport(value) {
        _viewportBox = value;
        return value;
    }

    public function scissorBox(x, y, w, h) {
        _scissorBox.x = x;
        _scissorBox.y = y;
        _scissorBox.z = w;
        _scissorBox.w = h;
    }
    public var renderTarget(get, set):AbstractTexture;

    function get_renderTarget() {
        return _renderTarget;
    }

    function set_renderTarget(target) {
        _renderTarget = target;
        return target;
    }
    public var clearBeforeRender(get, set):Bool;

    function get_clearBeforeRender() {
        return _clearBeforeRender;
    }

    function set_clearBeforeRender(value) {
        _clearBeforeRender = value;
        return value;
    }
    public var effectVariables(get, null):EffectVariables;

    function get_effectVariables() {
        return _variables;
    }

    public var effectTechnique(get, set):String;

    function get_effectTechnique() {
        return _effectTechnique;
    }

    function set_effectTechnique(value) {
        changeEffectOrTechnique(_effect, value);
        return value;
    }


    public var enabled(get, set):Bool;

    function get_enabled() {
        return _enabled;
    }

    function set_enabled(value) {
        _enabled = value;
        return value;
    }
    public var drawCallPool(get, null):DrawCallPool;

    function get_drawCallPool() {
        return _drawCallPool;
    }

    public var renderingBegin(get, null):Signal<Renderer>;

    function get_renderingBegin() {
        return _renderingBegin;
    }
    public var beforePresent(get, null):Signal<Renderer>;

    function get_beforePresent() {
        return _beforePresent;
    }
    public var renderingEnd(get, null):Signal<Renderer>;

    function get_renderingEnd() {
        return _renderingEnd;
    }


    /*const std::set<AbsFilterPtr>&
			filters(data::BindingSource source) const
			{
				return
				source == data::BindingSource::TARGET
				? _targetDataFilters
				: source == data::BindingSource::RENDERER
					? _rendererDataFilters
					: _rootDataFilters;
			}*/

    /*Ptr
			setFilterSurface(SurfacePtr);*/

    /*inline
			std::shared_ptr<RendererFilterChangedSignal>
			filterChanged() const
			{
				return _filterChanged;
			}*/


    public function reset() {
        _toCollect = new Array<Surface>();
        for(s in _surfaceToDrawCallIterator.keys()){
            removeSurface(s);
        }
        _surfaceToDrawCallIterator = new ObjectMap<Surface, Int>();
        _drawCallPool.clear();
    }

    public function initializePostProcessingGeometry() {
        var context = _sceneManager.assets.context;
        var vb:VertexBuffer = VertexBuffer.createbyData(context, [ -1.0, 1.0, 0.0, 1.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 0.0, 0.0, 1.0, -1.0, 1.0, 0.0]);
        vb.addAttribute("position", 2);
        vb.addAttribute("uv", 2, 2);

        var p:Provider = Provider.create();
        p.set("postProcessingPosition", vb.attribute("position"));
        p.set("postProcessingUV", vb.attribute("uv"));

        _postProcessingGeom = Geometry.createbyName();
        _postProcessingGeom.addVertexBuffer(vb);
        // _postProcessingGeom->indices(render::IndexBuffer::create(context, { 0, 2, 1, 1, 2, 3 }));

        target.data.addProvider(p);
    }

    override public function targetAdded(target:Node) {
        // Comment due to reflection component
        //if (target->components<Renderer>().size() > 1)
        //	throw std::logic_error("There cannot be two Renderer on the same node.");

        if (_effect != null) {
            target.data.addProviderbyName(_effect.data, Surface.EFFECT_COLLECTION_NAME);
        }

        _addedSlot = target.added.connect(addedHandler);

        _removedSlot = target.removed.connect(removedHandler);


        addedHandler(target.root, target, target.parent);
    }

    public function addedHandler(node:Node, target:Node, parent:Node) {

        findSceneManager();
        removeRootSlot();
        _rootDescendantAddedSlot = target.root.added.connect(rootDescendantAddedHandler, Math.POSITIVE_INFINITY);
        _rootDescendantRemovedSlot = target.root.removed.connect(rootDescendantRemovedHandler, Math.POSITIVE_INFINITY);
        _componentAddedSlot = target.root.componentAdded.connect(componentAddedHandler, Math.POSITIVE_INFINITY);
        _componentRemovedSlot = target.root.componentRemoved.connect(componentRemovedHandler, Math.POSITIVE_INFINITY);
        //_lightMaskFilter->root(target->root());
        reset();

        rootDescendantAddedHandler(null, target.root, null);
    }

    function removeRootSlot() {
        if (_rootDescendantAddedSlot != null)_rootDescendantAddedSlot.dispose();
        if (_rootDescendantRemovedSlot != null)_rootDescendantRemovedSlot.dispose();
        if (_componentAddedSlot != null)_componentAddedSlot.dispose();
        if (_componentRemovedSlot != null)_componentRemovedSlot.dispose();
        _rootDescendantAddedSlot = null;
        _rootDescendantRemovedSlot = null;
        _componentAddedSlot = null;
        _componentRemovedSlot = null;
    }

    override public function targetRemoved(target:Node) {

        removeRootSlot();

        if (_addedSlot != null)_addedSlot.dispose();
        if (_removedSlot != null)_removedSlot.dispose();
        if (_renderingBeginSlot != null)_renderingBeginSlot.dispose();
        _addedSlot = null;
        _removedSlot = null;
        _renderingBeginSlot = null;

        _surfaceChangedSlots = null;


        _drawCallPool.clear();

        if (_effect != null) {
            target.data.removeProviderbyName(_effect.data, Surface.EFFECT_COLLECTION_NAME);
        }
    }


    public function removedHandler(node:Node, target:Node, parent:Node) {
        findSceneManager();
        removeRootSlot();
        rootDescendantRemovedHandler(null, target.root, null);
    }

    public function rootDescendantAddedHandler(node:Node, target:Node, parent:Node) {
        var surfaceNodes:NodeSet = NodeSet.createbyNode(target).descendants(true).where(function(node:Node) {
            return node.hasComponent(Surface);
        });

        for (surfaceNode in surfaceNodes.nodes) {
            for (surface in surfaceNode.getComponents(Surface)) {

                addToCollect(cast surface);
            }
        }
    }

    public function rootDescendantRemovedHandler(node:Node, target:Node, parent:Node) {
        var surfaceNodes:NodeSet = NodeSet.createbyNode(target).descendants(true).where(function(node:Node) {
            return node.hasComponent(Surface);
        });

        for (surfaceNode in surfaceNodes.nodes) {
            for (surface in surfaceNode.getComponents(Surface)) {
                unwatchSurface(cast surface, surfaceNode,true);
                removeSurface(cast surface);
            }
        }
    }

    public function componentAddedHandler(node:Node, target:Node, ctrl:AbstractComponent) {
        //todo


        if (Std.is(ctrl, Surface)) {
            var surfaceCtrl:Surface = cast(ctrl, Surface);
            addToCollect(surfaceCtrl);
        }
        else if (Std.is(ctrl, SceneManager)) {
            var sceneManager:SceneManager = cast(ctrl, SceneManager);
            setSceneManager(sceneManager);
        }
        else if (Std.is(ctrl, PerspectiveCamera)) {
            var perspectiveCamera:PerspectiveCamera = cast(ctrl, PerspectiveCamera);
            _worldToScreenMatrixPropertyChangedSlot = perspectiveCamera.target.data.getPropertyChanged("worldToScreenMatrix").connect(
                function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
                    _mustZSort = true;
                });
        }
    }

    public function addToCollect(surfaceCtrl:Surface):Void {
        if(!Lambda.has(_toCollect,surfaceCtrl))
            _toCollect.push(surfaceCtrl);
    }

    public function componentRemovedHandler(node:Node, target:Node, cmp:AbstractComponent) {
        //todo

        if (Std.is(cmp, Surface)) {
            var surface:Surface = cast(cmp, Surface);
            unwatchSurface(surface, target,false);
            removeSurface(surface);
        }
        else if (Std.is(cmp, SceneManager)) {
            var sceneManager:SceneManager = cast(cmp, SceneManager);
            setSceneManager(null);
        }
        else if (Std.is(cmp, PerspectiveCamera)) {
            var perspectiveCamera:PerspectiveCamera = cast(cmp, PerspectiveCamera);
            _worldToScreenMatrixPropertyChangedSlot.dispose();
            _worldToScreenMatrixPropertyChangedSlot = null;
        }
    }

    public function addSurface(surface:Surface) {
        if (_surfaceToDrawCallIterator.exists(surface)) {
            throw ("surface");
            return;
        }
        if (_surfaceChangedSlots.exists(surface) == false) {
            _surfaceChangedSlots.set(surface, []);
        }
        if (_effect != null || surface.effect != null) {
            if (!checkSurfaceLayout(surface)) {
                return;
            }

            var variables:EffectVariables = _variables.concat([]);

            variables.push(new Tuple<String, String>("surfaceUuid", surface.uuid));
            variables.push(new Tuple<String, String>("geometryUuid", surface.geometry.uuid));
            variables.push(new Tuple<String, String>("materialUuid", surface.material.uuid));
            variables.push(new Tuple<String, String>("effectUuid", _effect != null ? _effect.uuid : surface.effect.uuid));

           // target.layout
            //这里区分 动态静态
            var drawCalls = _drawCallPool.addDrawCalls(_effect != null ? _effect : surface.effect, _effect != null ? _effectTechnique : surface.technique, variables,

            surface.target.root.data, target.data, surface.target.data);
            // rootData:Store, rendererData:Store, targetData:Store
            _surfaceToDrawCallIterator.set(surface, drawCalls);
            _surfaceChangedSlots.get(surface).push(surface.geometryChanged.connect(surfaceGeometryOrMaterialChangedHandler));
            _surfaceChangedSlots.get(surface).push(surface.materialChanged.connect(surfaceGeometryOrMaterialChangedHandler));
        }

        _surfaceChangedSlots.get(surface).push(surface.effectChanged.connect(surfaceEffectChangedHandler));
    }

    public function removeSurface(surface:Surface) {

        _toCollect.remove(surface) ;
        if (_surfaceToDrawCallIterator.exists(surface) == true) {
            _drawCallPool.removeDrawCalls(_surfaceToDrawCallIterator.get(surface));

            _surfaceToDrawCallIterator.remove(surface);

            var changedSlots:Array<SignalSlot<Surface>> = _surfaceChangedSlots.get(surface);
            for (s in changedSlots) {
                s.dispose();
            }
            _surfaceChangedSlots.remove(surface);
        }
    }

    public function surfaceGeometryOrMaterialChangedHandler(surface:Surface) {
        // The surface's material, geometry or effect is different
        // we completely remove the surface and re-add it again because
        // it's way simpler than just updating what has changed.

        var variables:EffectVariables =_variables.concat([]);
        variables.push(new Tuple<String, String>("surfaceUuid", surface.uuid));
        variables.push(new Tuple<String, String>("geometryUuid", surface.geometry.uuid));
        variables.push(new Tuple<String, String>("materialUuid", surface.material.uuid));
        variables.push(new Tuple<String, String>("effectUuid", _effect != null ? _effect.uuid : surface.effect.uuid));

        _drawCallPool.invalidateDrawCalls(_surfaceToDrawCallIterator.get(surface), variables);
        //removeSurface(surface);
        //_toCollect.push(surface);
    }

    public function surfaceEffectChangedHandler(surface:Surface) {
        removeSurface(surface);
        addToCollect(surface);
    }

    public function render(context:AbstractContext, ?renderTarget:AbstractTexture = null) {
        if (!_enabled) {
            return;
        }
        var forceSort = !Lambda.empty(_toCollect);

        // some surfaces have been added during the frame and collected
        // in _toCollect: we now have to take them into account to build
        // the corresponding draw calls before rendering

        for (surface in _toCollect) {
            watchSurface(surface);
            addSurface(surface);
        }
        _toCollect = [];

        _renderingBegin.execute((this));

        var rt:AbstractTexture = _renderTarget != null ? _renderTarget : renderTarget;

        if (_scissorBox.z >= 0 && _scissorBox.w >= 0) {
            context.setScissorTest(true, _scissorBox);
        }
        else {
            context.setScissorTest(false, _scissorBox);
        }

        if (rt != null) {
            context.setRenderToTexture(rt.id, true);
        }
        else {
            context.setRenderToBackBuffer();
        }

        if (_viewportBox.z >= 0 && _viewportBox.w >= 0) {
            context.configureViewport(Math.floor(_viewportBox.x), Math.floor(_viewportBox.y), Math.floor(_viewportBox.z), Math.floor(_viewportBox.w));
        }

        if (_clearBeforeRender) {
            context.clear(((_backgroundColor >> 24) & 0xff) / 255.0, ((_backgroundColor >> 16) & 0xff) / 255.0, ((_backgroundColor >> 8) & 0xff) / 255.0, (_backgroundColor & 0xff) / 255.0);
        }

        _drawCallPool.update(forceSort, _mustZSort);

        _mustZSort = false;
        var drawCallKeys = _drawCallPool.drawCallsKeys;
        var drawCalls = _drawCallPool.drawCalls ;

        _numDrawCalls = 0;
        _numTriangles = 0;
        inline function _render(drawCalls:Array<DrawCall>) {
            for (drawCall in drawCalls) {
                if (drawCall.enabled) {
                    drawCall.render(context, rt, _viewportBox, _backgroundColor);
                    ++_numDrawCalls;
                    _numTriangles += drawCall.numTriangles ;
                }
            }
        }
        for (dk in drawCallKeys) {
            var priorityToDrawCalls = drawCalls.get(dk);
            _render(priorityToDrawCalls.first);
            _render(priorityToDrawCalls.second);
        }

        _beforePresent.execute((this));

        context.present();

        _renderingEnd.execute((this));
    }


    public function clear(canvas:AbstractCanvas) {
        var backgroundColor = new Vec4(((_backgroundColor >> 24) & 0xff) / 255.0, ((_backgroundColor >> 16) & 0xff) / 255.0, ((_backgroundColor >> 8) & 0xff) / 255.0, (_backgroundColor & 0xff) / 255.0 );

        clearbyVector4(canvas, backgroundColor);
    }

    public function clearbyVector4(canvas:AbstractCanvas, clearColor:Vec4) {
        canvas.context.clear(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
        canvas.swapBuffers();
        canvas.context.clear(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
    }

    public function findSceneManager() {
        var roots:NodeSet = NodeSet.createbyNode(target).roots().where(function(node:Node) {
            return node.hasComponent(SceneManager);
        });

        if (roots.nodes.length > 1) {
            throw ("Renderer cannot be in two separate scenes.");
        }
        else if (roots.nodes .length == 1) {
            setSceneManager(cast roots.nodes[0].getComponent(SceneManager));
        }
        else {
            setSceneManager(null);
        }
    }

    public function setSceneManager(sceneManager:SceneManager) {
        if (sceneManager != _sceneManager) {
            if (sceneManager != null) {
                _sceneManager = sceneManager;
                _renderingBeginSlot = _sceneManager.renderingEnd.connect(sceneManagerRenderingBeginHandler, _priority);

                initializePostProcessingGeometry();
            }
            else {
                _sceneManager = null;
                _renderingBeginSlot = null;

                if (_postProcessingGeom != null) {
                    target.data.removeProviderbyName(_postProcessingGeom.data, Surface.GEOMETRY_COLLECTION_NAME);
                    _postProcessingGeom = null;
                }
            }
        }
    }

    public function sceneManagerRenderingBeginHandler(sceneManager:SceneManager, frameId:Int, renderTarget:AbstractTexture) {
        render(sceneManager.assets.context, renderTarget);
    }

    public function addFilter(filter:AbstractFilter, source:Source) {
        // FIXME
        /*
		if (filter)
		{
			auto& filters				= this->filtersRef(source);
			auto& filterChangedSlots	= this->filterChangedSlotsRef(source);

			if (filterChangedSlots.count(filter) == 0)
			{
				filters.push(filter);
				filterChangedSlots[filter] = filter->changed()->connect([=](AbsFilterPtr, SurfacePtr surface){
					filterChangedHandler(filter, source, surface);
				});
			}
		}
		*/

        return (this);
    }

    public function removeFilter(filter:AbstractFilter, source:Source) {
        // FIXME
        /*if (filter)
		{
			auto& filters				= this->filtersRef(source);
			auto& filterChangedSlots	= this->filterChangedSlotsRef(source);

			auto foundFilterIt = filters.find(filter);
			if (foundFilterIt != filters.end())
			{
				filters.erase(foundFilterIt);
				filterChangedSlots.erase(filter);
			}
		}*/

        return (this);
    }

    public function surfaceLayoutMaskChangedHandler(surface:Surface) {
        // FIXME
        // Use a _toEnable std::unordered_map<Surface::Ptr, bool>
        // to enable or disable a surface once in a frame and perform it after
        // _toCollect is processed.

        if (checkSurfaceLayout(surface)) {
            enableDrawCalls(surface, true);

            if (_surfaceToDrawCallIterator.exists(surface) == false) {
                addToCollect(surface);
            }
        }
        else {
            if ((surface.target.layout & BuiltinLayout.HIDDEN) != 0 || (surface.target.layout & BuiltinLayout.INSIDE_FRUSTUM) == 0) {
                enableDrawCalls(surface, false);
            }
            else {
                if (_surfaceToDrawCallIterator.exists(surface)) {
                    removeSurface(surface);
                }
            }
        }
    }

    public function watchSurface(surface:Surface) {
        var node = surface.target ;

        if (_nodeLayoutChangedSlot.exists(node) == false) {

            _nodeLayoutChangedSlot.set(node, node.layoutChanged.connect(function(n:Node, t:Node) {
                for (surface in t.getComponents(Surface)) {
                    surfaceLayoutMaskChangedHandler(cast surface);
                }
            }));

        }

        if (_surfaceLayoutMaskChangedSlot.exists(surface) == false) {

            _surfaceLayoutMaskChangedSlot.set(surface, surface.layoutMaskChanged.connect(function(surface) {
                surfaceLayoutMaskChangedHandler(cast surface);
            }));
        }
    }

    public function unwatchSurface(surface:Surface, node:Node,remove:Bool) {
        if (_surfaceLayoutMaskChangedSlot.exists(surface)) {
            _surfaceLayoutMaskChangedSlot.get(surface).dispose();
            _surfaceLayoutMaskChangedSlot.remove(surface);
        }
        //todo        if (!node.hasComponent(Surface)) {
        if (!node.hasComponent(Surface) ||remove) {
            _nodeLayoutChangedSlot.get(node).dispose();
            _nodeLayoutChangedSlot.remove(node);
        }
    }

    public function checkSurfaceLayout(surface:Surface) {
        return (surface.target.layout & surface.layoutMask & layoutMask) != 0;
    }

    override function set_layoutMask(value:Layout) {
        super.set_layoutMask(value);

        // completely reset the draw call pool
        if (target != null) {
            _drawCallPool.clear();

            rootDescendantRemovedHandler(null, target.root, null);
        }
        return value;
    }

    public function enableDrawCalls(surface:Surface, enabled:Bool) {

        if (!_surfaceToDrawCallIterator.exists(surface)) {
            return;
        }

        var drawCallId = _surfaceToDrawCallIterator.get(surface);

        inline function _enableDrawCalls(drawCalls:Array<DrawCall>) {
            for (drawCall in drawCalls) {
                // FIXME: we don't enable/disable draw calls for deffered passes (ie draw calls
                // with multiple batch IDs) despite it could lead to useless deferred passes.
                // But it would require an (de)activation counter which is "very unlikely" to
                // be equal to batchIDs.size.
                if (drawCall.batchIDs.length > 1) {
                    continue;
                }

                if (drawCall.batchIDs[0] == drawCallId) {
                    drawCall.enabled = (enabled);
                }
            }
        }
        for (priorityToDrawCalls in _drawCallPool.drawCalls) {
            _enableDrawCalls(priorityToDrawCalls.first);
            _enableDrawCalls(priorityToDrawCalls.second);
        }
    }

    public function changeEffectOrTechnique(effect:Effect, technique:String) {
        if (effect != _effect || technique != _effectTechnique) {
            _effect = effect;
            _effectTechnique = technique;

            reset();

            rootDescendantAddedHandler(target.root, target.root, target.parent);
        }
    }

}
