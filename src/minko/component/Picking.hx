package minko.component;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import minko.component.Picking;
import minko.data.Provider;
import minko.input.Mouse;
import minko.input.Touch;
import minko.math.Ray;
import minko.render.AbstractContext;
import minko.render.Effect;
import minko.render.Texture;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal4.SignalSlot4;
import minko.signal.Signal;
import minko.utils.MathUtil;
class Picking extends AbstractComponent {
    private var _renderTarget:Texture;
    private var _renderer:Renderer;
    private var _sceneManager:SceneManager;
    private var _mouse:Mouse;
    private var _touch:Touch;
    private var _camera:Node;
    private var _pickingProjection:Mat4;
    private var _surfaceToPickingId:ObjectMap<Surface, Int> ;
    private var _pickingIdToSurface:IntMap<Surface> ;
    private var _pickingId:Int;
    private var _context:AbstractContext;
    private var _pickingProvider:Provider;

    private var _pickingEffect:Effect;
    private var _pickingDepthEffect:Effect;
    private var _depthRenderer:Renderer;
    private var _descendants:Array<Node>;

    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;
    private var _renderingBeginSlot:SignalSlot<Renderer>;
    private var _renderingEndSlot:SignalSlot<Renderer>;
    private var _depthRenderingBeginSlot:SignalSlot<Renderer>;
    private var _depthRenderingEndSlot:SignalSlot<Renderer>;
    private var _frameBeginSlot:SignalSlot3<SceneManager, Float, Float>;
    private var _componentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _componentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;

    private var _mouseOver:Signal<Node>;
    private var _mouseRightDown:Signal<Node>;
    private var _mouseLeftDown:Signal<Node>;
    private var _mouseRightUp:Signal<Node>;
    private var _mouseLeftUp:Signal<Node>;
    private var _mouseRightClick:Signal<Node>;
    private var _mouseLeftClick:Signal<Node>;
    private var _mouseOut:Signal<Node>;
    private var _mouseMove:Signal<Node>;
    private var _mouseWheel:Signal<Node>;

    private var _touchDown:Signal<Node>;
    private var _touchUp:Signal<Node>;
    private var _touchMove:Signal<Node>;
    private var _tap:Signal<Node>;
    private var _doubleTap:Signal<Node>;
    private var _longHold:Signal<Node>;

    private var _lastColor:Bytes;//= new byte[4];
    private var _lastPickedSurface:Surface;
    private var _lastDepth:Bytes;// = new byte[4];
    private var _lastDepthValue:Float;
    private var _lastMergingMask:Int;

    private var _mouseMoveSlot:SignalSlot3<Mouse, Int, Int>;
    private var _mouseRightDownSlot:SignalSlot<Mouse> ;
    private var _mouseLeftDownSlot:SignalSlot<Mouse> ;
    private var _mouseRightUpSlot:SignalSlot<Mouse> ;
    private var _mouseLeftUpSlot:SignalSlot<Mouse> ;
    private var _mouseRightClickSlot:SignalSlot<Mouse> ;
    private var _mouseLeftClickSlot:SignalSlot<Mouse> ;
    private var _mouseWheelSlot:SignalSlot3<Mouse, Float, Float> ;
    private var _touchDownSlot:SignalSlot4<Touch, Int, Float, Float>;
    private var _touchUpSlot:SignalSlot4<Touch, Int, Float, Float>;
    private var _touchMoveSlot:SignalSlot4<Touch, Int, Float, Float>;
    private var _touchTapSlot:SignalSlot3<Touch, Float, Float>;
    private var _touchDoubleTapSlot:SignalSlot3<Touch, Float, Float>;
    private var _touchLongHoldSlot:SignalSlot3<Touch, Float, Float>;

    private var _executeMoveHandler:Bool;
    private var _executeRightClickHandler:Bool;
    private var _executeLeftClickHandler:Bool;
    private var _executeRightDownHandler:Bool;
    private var _executeLeftDownHandler:Bool;
    private var _executeRightUpHandler:Bool;
    private var _executeLeftUpHandler:Bool;
    private var _executeMouseWheel:Bool;
    private var _executeTouchDownHandler:Bool;
    private var _executeTouchUpHandler:Bool;
    private var _executeTouchMoveHandler:Bool;
    private var _executeTapHandler:Bool;
    private var _executeDoubleTapHandler:Bool;
    private var _executeLongHoldHandler:Bool;

    private var _wheelX:Int;
    private var _wheelY:Int;

    private var _addPickingLayout:Bool;
    private var _emulateMouseWithTouch:Bool;

    private var _enabled:Bool;
    private var _renderDepth:Bool;

    private var _debug:Bool;

    public static function create(camera, addPickingLayoutToNodes = true, emulateMouseWithTouch = true, pickingEffect = null, pickingDepthEffect = null) {
        var picking = new Picking();

        picking.initialize(camera, addPickingLayoutToNodes, emulateMouseWithTouch, pickingEffect, pickingDepthEffect);

        return picking;
    }
    public var mouseOver(get, null):Signal<Node>;

    function get_mouseOver() {
        return _mouseOver;
    }
    public var mouseRightDown(get, null):Signal<Node>;

    function get_mouseRightDown() {
        return _mouseRightDown;
    }
    public var mouseRightUp(get, null):Signal<Node>;

    function get_mouseRightUp() {
        return _mouseRightUp;
    }
    public var mouseDown(get, null):Signal<Node>;

    function get_mouseDown() {
        return _mouseLeftDown;
    }
    public var mouseUp(get, null):Signal<Node>;

    function get_mouseUp() {
        return _mouseLeftUp;
    }
    public var mouseRightClick(get, null):Signal<Node>;

    function get_mouseRightClick() {
        return _mouseRightClick;
    }
    public var mouseClick(get, null):Signal<Node>;

    function get_mouseClick() {
        return _mouseLeftClick;
    }
    public var mouseOut(get, null):Signal<Node>;

    function get_mouseOut() {
        return _mouseOut;
    }
    public var mouseMove(get, null):Signal<Node>;

    function get_mouseMove() {
        return _mouseMove;
    }
    public var mouseWheel(get, null):Signal<Node>;

    function get_mouseWheel() {
        return _mouseWheel;
    }
    public var touchDown(get, null):Signal<Node>;

    function get_touchDown() {
        return _touchDown;
    }
    public var touchMove(get, null):Signal<Node>;

    function get_touchMove() {
        return _touchMove;
    }
    public var touchUp(get, null):Signal<Node>;

    function get_touchUp() {
        return _touchUp;
    }
    public var touchTap(get, null):Signal<Node>;

    function get_touchTap() {
        return _tap;
    }
    public var touchDoubleTap(get, null):Signal<Node>;

    function get_touchDoubleTap() {
        return _doubleTap;
    }
    public var touchLongHold(get, null):Signal<Node>;

    function get_touchLongHold() {
        return _longHold;
    }
    public var pickedSurface(get, null):Surface;

    function get_pickedSurface() {
        return _lastPickedSurface;
    }

    public var renderDepth(get, set):Bool;

    function get_renderDepth() {
        return _renderDepth;
    }

    function set_renderDepth(value) {
        _renderDepth = value;
        return value;
    }

    public var pickedDepth(get, null):Float;

    function get_pickedDepth() {
        return _lastDepthValue;
    }

    public var pickedMergingMask(get, null):Int;

    function get_pickedMergingMask() {
        return _lastMergingMask;
    }
    public var debug(null, set):Bool;

    function set_debug(v) {
        _debug = v;
        return v;
    }

    override public function targetRemoved(target:Node) {
        unbindSignals();

        if (target.existsComponent(_renderer)) {
            target.removeComponent(_renderer);
        }
        if (target.existsComponent(_depthRenderer)) {
            target.removeComponent(_depthRenderer);
        }

        _renderer = null;
        _depthRenderer = null;
        _sceneManager = null;
        _enabled = false;

        removedHandler(target.root, target, target.parent);
    }


    public function initialize(camera:Node, addPickingLayout:Bool, emulateMouseWithTouch:Bool, pickingEffect:Effect, pickingDepthEffect:Effect) {
        _camera = camera;
        _addPickingLayout = addPickingLayout;
        _emulateMouseWithTouch = emulateMouseWithTouch;
        _pickingEffect = pickingEffect;
        _pickingDepthEffect = pickingDepthEffect;

        _pickingProvider.set("pickingProjection", _pickingProjection);
        _pickingProvider.set("pickingOrigin", new Vec3());
    }

    private function bindSignals() {
        _mouseMoveSlot = _mouse.move.connect(this.mouseMoveHandler);

        _mouseLeftDownSlot = _mouse.leftButtonDown.connect(this.mouseLeftDownHandler);

        _mouseRightDownSlot = _mouse.rightButtonDown.connect(this.mouseRightDownHandler);

        _mouseLeftClickSlot = _mouse.leftButtonClick.connect(this.mouseLeftClickHandler);

        _mouseRightClickSlot = _mouse.rightButtonClick.connect(this.mouseRightClickHandler);

        _mouseLeftUpSlot = _mouse.leftButtonUp.connect(this.mouseLeftUpHandler);

        _mouseRightUpSlot = _mouse.rightButtonUp.connect(this.mouseRightUpHandler);

        _mouseWheelSlot = _mouse.wheel.connect(this.mouseWheelHandler);

        _touchDownSlot = _touch.touchDown.connect(this.touchDownHandler);

        _touchUpSlot = _touch.touchUp.connect(this.touchUpHandler);

        _touchMoveSlot = _touch.touchMove.connect(this.touchMoveHandler);

        _touchTapSlot = _touch.tap.connect(this.touchTapHandler);

        _touchDoubleTapSlot = _touch.doubleTap.connect(this.touchDoubleTapHandler);

        _touchLongHoldSlot = _touch.longHold.connect(this.touchLongHoldHandler);

        _executeMoveHandler = false;
        _executeRightClickHandler = false;
        _executeLeftClickHandler = false;
        _executeRightDownHandler = false;
        _executeLeftDownHandler = false;
        _executeRightUpHandler = false;
        _executeLeftUpHandler = false;
        _executeTouchDownHandler = false;
        _executeTouchUpHandler = false;
        _executeTouchMoveHandler = false;
        _executeTapHandler = false;
        _executeDoubleTapHandler = false;
        _executeLongHoldHandler = false;
    }

    private function unbindSignals() {
        _mouseMoveSlot = null;
        _mouseLeftDownSlot = null;
        _mouseRightDownSlot = null;
        _mouseLeftClickSlot = null;
        _mouseRightClickSlot = null;
        _mouseLeftUpSlot = null;
        _mouseRightUpSlot = null;
        _touchDownSlot = null;
        _touchUpSlot = null;
        _touchMoveSlot = null;
        _touchTapSlot = null;
        _touchDoubleTapSlot = null;
        _touchLongHoldSlot = null;

        _frameBeginSlot = null;
        _renderingBeginSlot = null;
        _renderingEndSlot = null;
        _depthRenderingBeginSlot = null;
        _depthRenderingEndSlot = null;
        _componentAddedSlot = null;
        _componentRemovedSlot = null;

        _addedSlot = null;
        _removedSlot = null;
    }

    override public function targetAdded(target:Node) {
        _sceneManager = cast target.root.getComponent(SceneManager);
        var canvas:AbstractCanvas = _sceneManager.canvas;

        _mouse = canvas.mouse;
        _touch = canvas.touch;
        _context = canvas.context;

        bindSignals();

        if (_pickingEffect == null) {
            _pickingEffect = _sceneManager.assets.effect("effect/Picking.effect");
        }

        var priority = _debug ? -1000.0 : 1000.0;

        _renderer = Renderer.create(0xFFFF00FF, null, _pickingEffect, "default", priority, "Picking Renderer");
        if (!_debug) {
            _renderer.scissorBox(0, 0, 1, 1);
        }
        _renderer.layoutMask = (BuiltinLayout.PICKING);
        if (!_debug) {
            _renderer.enabled = (false);
        }

        if (_pickingDepthEffect == null) {
            _pickingDepthEffect = _sceneManager.assets.effect("effect/PickingDepth.effect");
        }

        _depthRenderer = Renderer.create(0xFFFF00FF, null, _pickingDepthEffect, "default", 999.0, "Depth Picking Renderer");
        _depthRenderer.scissorBox(0, 0, 1, 1);
        _depthRenderer.layoutMask = (BuiltinLayout.PICKING_DEPTH);
        _depthRenderer.enabled = (false);

        updateDescendants(target);

        _addedSlot = target.added.connect(addedHandler);

        _removedSlot = target.removed.connect(removedHandler);

        if (target.parent != null || target.hasComponent(SceneManager)) {
            addedHandler(target, target, target.parent);
        }

        target.addComponent(_renderer);
        target.addComponent(_depthRenderer);

        var perspectiveCamera:PerspectiveCamera = cast _camera.getComponent(PerspectiveCamera);

        target.data.addProvider(_pickingProvider);
        target.data.addProvider(perspectiveCamera.data);

        addSurfacesForNode(target);
    }


    public function addedHandler(target:Node, child:Node, parent:Node) {
        updateDescendants(target);

        if (Lambda.has(_descendants, child) == false) {
            return;
        }

        if (child == target && _renderingBeginSlot == null) {
            _renderingBeginSlot = _renderer.renderingBegin.connect(renderingBegin);

            _renderingEndSlot = _renderer.beforePresent.connect(renderingEnd);

            _depthRenderingBeginSlot = _depthRenderer.renderingBegin.connect(depthRenderingBegin);

            _depthRenderingEndSlot = _depthRenderer.beforePresent.connect(depthRenderingEnd);

            _componentAddedSlot = child.componentAdded.connect(componentAddedHandler);

            _componentRemovedSlot = child.componentRemoved.connect(componentRemovedHandler);
        }

        if (Lambda.has(_descendants, child)) {
            addSurfacesForNode(child);
        }
    }

    public function componentAddedHandler(target:Node, node:Node, ctrl:AbstractComponent) {
        if (Lambda.has(_descendants, node)) {
            return;
        }


        if (Std.is(ctrl, Surface)) {
            var surfaceCtrl:Surface = cast(ctrl, Surface);
            addSurface(surfaceCtrl);
        }
    }

    public function componentRemovedHandler(target:Node, node:Node, ctrl:AbstractComponent) {
        if (Lambda.has(_descendants, node) == false) {
            return;
        }
        if (Std.is(ctrl, Surface)) {
            var surfaceCtrl:Surface = cast(ctrl, Surface);
            removeSurface(surfaceCtrl, node);
        }

        if (!node.hasComponent(Surface) && _addPickingLayout) {
            node.layout = (node.layout & ~BuiltinLayout.PICKING);
        }
    }

    public function addSurface(surface:Surface) {
        if (_surfaceToPickingId.exists(surface) == false) {
            _pickingId += 2;

            _surfaceToPickingId.set(surface, _pickingId);
            _pickingIdToSurface.set(_pickingId, surface);

            surface.data.set("pickingColor", new Vec4(((_pickingId >> 16) & 0xff) / 255.0, ((_pickingId >> 8) & 0xff) / 255.0, ((_pickingId) & 0xff) / 255.0, 1));

            if (_addPickingLayout) {
                surface.target.layout = (target.layout | BuiltinLayout.PICKING);
            }

            surface.layoutMask = (surface.layoutMask & ~BuiltinLayout.PICKING_DEPTH);
        }
    }

    public function removeSurface(surface:Surface, node:Node) {
        if (_surfaceToPickingId.exists(surface) == false) {
            return;
        }

        surface.data.unset("pickingColor");

        var surfacePickingId = _surfaceToPickingId.get(surface);

        _surfaceToPickingId.remove(surface);
        _pickingIdToSurface.remove(surfacePickingId);
    }

    public function removedHandler(target:Node, child:Node, parent:Node) {

        if (Lambda.has(_descendants, child) == false) {
            return;
        }

        removeSurfacesForNode(child);

        updateDescendants(target);
    }

    public function addSurfacesForNode(node:Node) {
        var surfaces:NodeSet = NodeSet.createbyNode(node).descendants(true).where(function(node:Node) {
            return node.hasComponent(Surface);
        });

        for (surfaceNode in surfaces.nodes) {
            var surfaces:Array<Surface> = cast surfaceNode.getComponents(Surface);
            for (surface in surfaces) {
                addSurface(surface);
            }
        }
    }

    public function removeSurfacesForNode(node:Node) {
        var surfaces:NodeSet = NodeSet.createbyNode(node).descendants(true).where(function(node:Node) {
            return node.hasComponent(Surface);
        });

        for (surfaceNode in surfaces.nodes) {
            surfaceNode.layout = (surfaceNode.layout & ~BuiltinLayout.PICKING);
            var surfaces:Array<Surface> = cast surfaceNode.getComponents(Surface);
            for (surface in surfaces) {
                removeSurface(surface, surfaceNode);
            }
        }
    }

    public function updateDescendants(target:Node) {
        var nodeSet:NodeSet = NodeSet.createbyNode(target).descendants(true);

        _descendants = nodeSet.nodes;
    }

    public var enabled(null, set):Bool;

    function set_enabled(v) {
        if (v && _frameBeginSlot == null) {
            v = true;

            _frameBeginSlot = _sceneManager.frameBegin.connect(frameBeginHandler, 1000.0);
        }
        else if (!v && _frameBeginSlot != null) {
            _frameBeginSlot = null;
        }

        _enabled = v;
        return v;
    }

    public function frameBeginHandler(UnnamedParameter1:SceneManager, UnnamedParameter2:Float, UnnamedParameter3:Float) {
        if (_debug) {
            return;
        }

        _renderer.enabled = (true);
        _renderer.render(_sceneManager.canvas.context);
        _renderer.enabled = (false);
    }

    public function renderingBegin(renderer:Renderer) {
        if (!_enabled) {
            return;
        }

        updatePickingProjection();
    }

    function doRenderDepth(renderer:Renderer, pickedSurface:Surface) {
        if (!_enabled)
            return;

        var pickedSurfaceTarget = pickedSurface.target;

        pickedSurfaceTarget.layout = (pickedSurfaceTarget.layout | BuiltinLayout.PICKING_DEPTH);
        pickedSurface.layoutMask = (pickedSurface.layoutMask | BuiltinLayout.PICKING_DEPTH);

        renderer.enabled = (true);
        renderer.render(_sceneManager.canvas.context);
        renderer.enabled = (false);

        pickedSurfaceTarget.layout = (pickedSurfaceTarget.layout & ~BuiltinLayout.PICKING_DEPTH);
        pickedSurface.layoutMask = (pickedSurface.layoutMask & ~ BuiltinLayout.PICKING_DEPTH);
    }

    public function renderingEnd(renderer:Renderer) {
        if (!_enabled) {
            return;
        }

        _context.readRectPixels(0, 0, 1, 1, _lastColor);

        var pickedSurfaceId = (_lastColor.get(0) << 16) + (_lastColor.get(1) << 8) + _lastColor.get(2);

        var surfaceIt = _pickingIdToSurface.exists(pickedSurfaceId);

        if (surfaceIt != false) {
            var pickedSurface = _pickingIdToSurface.get(pickedSurfaceId);

            if (_renderDepth) {
                doRenderDepth(_depthRenderer, pickedSurface);
            }
            else {
                dispatchEvents(pickedSurface, _lastDepthValue);
            }
        }
        else {
            dispatchEvents(null, _lastDepthValue);
        }
    }


    public function depthRenderingBegin(renderer:Renderer) {
        if (!_enabled) {
            return;
        }

        updatePickingOrigin();
    }

    static inline function unpack(depth:Vec3) {
        return Vec3.dot(depth, new Vec3(1.0, 1.0 / 255.0, 1.0 / 65025.0));
    }


    public function depthRenderingEnd(renderer:Renderer) {
        if (!_enabled) {
            return;
        }

        var pickedSurfaceId = (_lastColor.get(0) << 16) + (_lastColor.get(1) << 8) + _lastColor.get(2);

        var surfaceIt = _pickingIdToSurface.exists(pickedSurfaceId);

        if (surfaceIt != false) {
            var pickedSurface = _pickingIdToSurface.get(pickedSurfaceId);

            _context.readRectPixels(0, 0, 1, 1, _lastDepth);

            var zFar = _camera.data.get("zFar");

            var normalizedDepth = Picking.unpack(MathUtil.Vector3_div(new Vec3(_lastDepth.get(0), _lastDepth.get(1), _lastDepth.get(2)), 255.0)) * zFar;

            _lastDepthValue = normalizedDepth;

            _lastMergingMask = _lastDepth.get(3);

            dispatchEvents(pickedSurface, _lastDepthValue);
        }
    }

    public function updatePickingProjection() {
        var mouseX = _mouse.x;
        var mouseY = _mouse.y;

        var perspectiveCamera:PerspectiveCamera = cast _camera.getComponent(PerspectiveCamera);

        var projection:Mat4 = GLM.perspective(perspectiveCamera.fieldOfView, perspectiveCamera.aspectRatio, perspectiveCamera.zNear, perspectiveCamera.zFar, new Mat4());

        projection.r0c2 = mouseX / _context.viewportWidth * 2.0;
        projection.r1c2 = (_context.viewportHeight - mouseY) / _context.viewportHeight * 2.0;

        _pickingProvider.set("pickingProjection", projection);
    }

    public function updatePickingOrigin() {
        var perspectiveCamera:PerspectiveCamera = cast _camera.getComponent(PerspectiveCamera);

        var normalizedMouseX = _mouse.normalizedX;
        var normalizedMouseY = _mouse.normalizedY;

        var pickingRay:Ray = perspectiveCamera.unproject(normalizedMouseX, normalizedMouseY);

        _pickingProvider.set("pickingOrigin", pickingRay.origin);
    }

    public function dispatchEvents(pickedSurface:Surface, depth:Float) {
        if (_lastPickedSurface != pickedSurface) {
            if (_lastPickedSurface != null && _mouseOut.numCallbacks > 0) {
                _mouseOut.execute(_lastPickedSurface.target);
            }

            _lastPickedSurface = pickedSurface;

            if (_lastPickedSurface != null && _mouseOver.numCallbacks > 0) {
                _mouseOver.execute(_lastPickedSurface.target);
            }
        }

        if (_executeMoveHandler && _lastPickedSurface != null) {
            _mouseMove.execute(_lastPickedSurface.target);
        }

        if (_executeRightDownHandler && _lastPickedSurface != null) {
            _mouseRightDown.execute(_lastPickedSurface.target);
        }

        if (_executeLeftDownHandler && _lastPickedSurface != null) {
            _mouseLeftDown.execute(_lastPickedSurface.target);
        }

        if (_executeRightClickHandler && _lastPickedSurface != null) {
            _mouseRightClick.execute(_lastPickedSurface.target);
        }

        if (_executeLeftClickHandler && _lastPickedSurface != null) {
            _mouseLeftClick.execute(_lastPickedSurface.target);
        }

        if (_executeRightUpHandler && _lastPickedSurface != null) {
            _mouseRightUp.execute(_lastPickedSurface.target);
        }

        if (_executeLeftUpHandler && _lastPickedSurface != null) {
            _mouseLeftUp.execute(_lastPickedSurface.target);
        }

        if (_executeMouseWheel && _lastPickedSurface != null) {
            _mouseWheel.execute(_lastPickedSurface.target);
        }

        if (_executeTouchDownHandler && _lastPickedSurface != null) {
            _touchDown.execute(_lastPickedSurface.target);
        }

        if (_executeTouchUpHandler && _lastPickedSurface != null) {
            _touchUp.execute(_lastPickedSurface.target);
        }

        if (_executeTouchMoveHandler && _lastPickedSurface != null) {
            _touchMove.execute(_lastPickedSurface.target);
        }

        if (_executeTapHandler && _lastPickedSurface != null) {
            _tap.execute(_lastPickedSurface.target);
        }

        if (_executeDoubleTapHandler && _lastPickedSurface != null) {
            _doubleTap.execute(_lastPickedSurface.target);
        }

        if (_executeLongHoldHandler && _lastPickedSurface != null) {
            _longHold.execute(_lastPickedSurface.target);
        }

        if (!(_mouseOver.numCallbacks > 0 || _mouseOut.numCallbacks > 0)) {
            enabled = (false);
        }

        _executeMoveHandler = false;
        _executeRightDownHandler = false;
        _executeLeftDownHandler = false;
        _executeRightClickHandler = false;
        _executeLeftClickHandler = false;
        _executeRightUpHandler = false;
        _executeLeftUpHandler = false;
    }

    public function mouseMoveHandler(mouse:Mouse, dx:Int, dy:Int) {
        if (_mouseOver.numCallbacks > 0 || _mouseOut.numCallbacks > 0) {
            _executeMoveHandler = true;
            enabled = (true);
        }
    }

    public function mouseRightUpHandler(mouse:Mouse) {
        if (_mouseRightUp.numCallbacks > 0) {
            _executeRightUpHandler = true;
            enabled = (true);
        }
    }

    public function mouseLeftUpHandler(mouse:Mouse) {
        if (_mouseLeftUp.numCallbacks > 0) {
            _executeLeftUpHandler = true;
            enabled = (true);
        }
    }

    public function mouseRightClickHandler(mouse:Mouse) {
        if (_mouseRightClick.numCallbacks > 0) {
            _executeRightClickHandler = true;
            enabled = (true);
        }
    }

    public function mouseLeftClickHandler(mouse:Mouse) {
        if (_mouseLeftClick.numCallbacks > 0) {
            _executeLeftClickHandler = true;
            enabled = (true);
        }
    }

    public function mouseRightDownHandler(mouse:Mouse) {
        if (_mouseRightDown.numCallbacks > 0) {
            _executeRightDownHandler = true;
            enabled = (true);
        }
    }

    public function mouseLeftDownHandler(mouse:Mouse) {
        if (_mouseLeftDown.numCallbacks > 0) {
            _executeLeftDownHandler = true;
            enabled = (true);
        }
    }

    public function mouseWheelHandler(mouse:Mouse, x:Float, y:Float) {
        if (_mouseWheel.numCallbacks > 0) {
            _executeMouseWheel = true;
            enabled = (true);
        }
    }

    public function touchDownHandler(touch:Touch, identifier:Int, x:Float, y:Float) {
        if (_touchDown.numCallbacks > 0) {
            _executeTouchDownHandler = true;
            enabled = (true);
        }
        if (_emulateMouseWithTouch && _touch.numTouches == 1 && _mouseLeftDown.numCallbacks > 0) {
            _executeLeftDownHandler = true;
            enabled = (true);
        }
    }

    public function touchUpHandler(touch:Touch, identifier:Int, x:Float, y:Float) {
        if (_touchUp.numCallbacks > 0) {
            _executeTouchUpHandler = true;
            enabled = (true);
        }
        if (_emulateMouseWithTouch && _touch.numTouches == 1 && _mouseLeftUp.numCallbacks > 0) {
            _executeLeftUpHandler = true;
            enabled = (true);
        }
    }

    public function touchMoveHandler(touch:Touch, identifier:Int, x:Float, y:Float) {
        if (_touchMove.numCallbacks > 0) {
            _executeTouchMoveHandler = true;
            enabled = (true);
        }
        if (_emulateMouseWithTouch && _touch.numTouches == 1 && _mouseMove.numCallbacks > 0) {
            _executeMoveHandler = true;
            enabled = (true);
        }
    }

    public function touchTapHandler(touch:Touch, x:Float, y:Float) {
        if (_tap.numCallbacks > 0) {
            _executeTapHandler = true;
            enabled = (true);
        }
        if (_emulateMouseWithTouch && _mouseLeftClick.numCallbacks > 0) {
            _executeLeftClickHandler = true;
            enabled = (true);
        }
    }

    public function touchDoubleTapHandler(touch:Touch, x:Float, y:Float) {
        if (_doubleTap.numCallbacks > 0) {
            _executeDoubleTapHandler = true;
            enabled = (true);
        }
    }

    public function touchLongHoldHandler(touch:Touch, x:Float, y:Float) {
        if (_doubleTap.numCallbacks > 0) {
            _executeDoubleTapHandler = true;
            enabled = (true);
        }
        if (_emulateMouseWithTouch && _mouseRightClick.numCallbacks > 0) {
            _executeRightClickHandler = true;
            enabled = (true);
        }
    }

    public function new() {
        super();
        this._sceneManager = null;
        this._context = null;
        this._mouse = null;
        this._touch = null;
        this._camera = null;
        this._pickingId = 0;
        this._pickingProjection = Mat4.identity(new Mat4());
        this._pickingProvider = Provider.create();
        this._pickingEffect = null;
        this._pickingDepthEffect = null;
        this._mouseMove = new Signal<Node>();
        this._mouseLeftClick = new Signal<Node>();
        this._mouseRightClick = new Signal<Node>();
        this._mouseLeftDown = new Signal<Node>();
        this._mouseRightDown = new Signal<Node>();
        this._mouseLeftUp = new Signal<Node>();
        this._mouseRightUp = new Signal<Node>();
        this._mouseOut = new Signal<Node>();
        this._mouseOver = new Signal<Node>();
        this._mouseWheel = new Signal<Node>();
        this._touchDown = new Signal<Node>();
        this._touchMove = new Signal<Node>();
        this._touchUp = new Signal<Node>();
        this._tap = new Signal<Node>();
        this._doubleTap = new Signal<Node>();
        this._longHold = new Signal<Node>();
        this._lastDepthValue = 0.0;
        this._lastMergingMask = 0;
        this._addPickingLayout = true;
        this._emulateMouseWithTouch = true;
        this._frameBeginSlot = null;
        this._enabled = false;
        this._renderDepth = true;
        this._debug = false;
        this._lastColor = Bytes.alloc(4);//= new byte[4];
        this._lastDepth = Bytes.alloc(4);// = new byte[4];
        this._surfaceToPickingId = new ObjectMap<Surface, Int>() ;
        this._pickingIdToSurface = new IntMap<Surface>() ;
    }
}
