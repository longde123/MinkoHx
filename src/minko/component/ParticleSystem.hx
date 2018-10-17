package minko.component;
import Lambda;
import minko.data.ParticlesProvider;
import minko.file.AssetLibrary;
import minko.geometry.ParticlesGeometry;
import minko.particle.modifier.IParticleInitializer;
import minko.particle.modifier.IParticleModifier;
import minko.particle.modifier.IParticleUpdater;
import minko.particle.ParticleData;
import minko.particle.sampler.Constant;
import minko.particle.sampler.Sampler;
import minko.particle.shape.EmitterShape;
import minko.particle.shape.Sphere;
import minko.particle.StartDirection;
import minko.particle.tools.VertexComponentFlags;
import minko.render.Effect;
import minko.render.ParticleIndexBuffer;
import minko.render.ParticleVertexBuffer;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal3.SignalSlot3;
import minko.Tuple.Tuple3;
class ParticleDistanceToCameraComparison {
    public var particleSystem:ParticleSystem;

    public function functorMethod(p1Index, p2Index) {
        return particleSystem.getParticleSquaredDistanceToCamera(p1Index) > particleSystem.getParticleSquaredDistanceToCamera(p2Index);
    }
}
class ParticleSystem extends AbstractComponent {


    private static var COUNT_LIMIT = 500;

    private var _geometry:ParticlesGeometry;
    private var _material:ParticlesProvider;
    private var _effect:Effect;
    private var _surface:Surface;

    private var _toWorld:Transform;

    private var _countLimit:Int;
    private var _maxCount:Int;
    //unsigned int                                                _liveCount;
    private var _previousLiveCount:Int;
    private var _initializers:Array<IParticleInitializer>;
    private var _updaters:Array<IParticleUpdater> ;
    private var _particles:Array<ParticleData>;
    private var _particleOrder:Array<Int>;
    private var _particleDistanceToCamera:Array<Float>;

    private var _isInWorldSpace:Bool;
    private var _localToWorld:Array<Float>;//[16];
    private var _isZSorted:Bool;
    private var _cameraCoords:Array<Float>;//[3];
    private var _comparisonObject:ParticleDistanceToCameraComparison;
    private var _useOldPosition:Bool;

    private var _rate:Float;
    private var _lifetime:Sampler;
    private var _shape:EmitterShape;
    private var _emissionDirection:StartDirection;
    private var _emissionVelocity:Sampler;

    private var _createTimer:Float;

    private var _format:Int;

    private var _updateStep:Float;
    private var _playing:Bool;
    private var _emitting:Bool;
    private var _time:Float;

    private var _frameBeginSlot:SignalSlot3<SceneManager, Float, Float>;
    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;
    private var _rootDescendantAddedSlot:SignalSlot3<Node, Node, Node>;
    private var _rootDescendantRemovedSlot:SignalSlot3<Node, Node, Node>;
    private var _componentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _componentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;

    public static function create(assets:AssetLibrary, rate:Float, lifetime:Sampler, shape:EmitterShape, emissionDirection:StartDirection, emissionVelocity:Sampler) {
        var ptr = new ParticleSystem(assets, rate, lifetime, shape, emissionDirection, emissionVelocity);

        ptr.initialize();

        return ptr;
    }

    public var material(get, null):ParticlesProvider;

    function get_material() {
        return _material;
    }
    public var rate(get, set):Float;

    function set_rate(value:Float) {
        _rate = 1.0 / value;

        updateMaxParticlesCount();

        return _rate;
    }

    function get_rate() {
        return _rate;
    }

    public var lifetime(get, set):Sampler;

    function set_lifetime(value) {
        _lifetime = value;

        updateMaxParticlesCount();

        return value;
    }

    function get_lifetime() {
        return _lifetime;
    }

    public var shape(get, set):EmitterShape;

    function set_shape(value) {
        _shape = value;

        return value;
    }

    function get_shape() {

        return _shape;
    }
    public var emissionDirection(get, set):StartDirection;

    function set_emissionDirection(value) {
        _emissionDirection = value;

        return value;
    }

    function get_emissionDirection() {

        return _emissionDirection;
    }
    public var emissionVelocity(get, set):Sampler;

    function set_emissionVelocity(value) {

        _emissionVelocity = value;

        return value;
    }

    function get_emissionVelocity() {

        return _emissionVelocity ;
    }


    public function updateRate(updatesPerSecond) {
        _updateStep = 1.0 / updatesPerSecond;
    }

    public var playing(get, set):Bool;

    function set_playing(value) {
        _playing = value;

        return value;
    }

    function get_playing() {
        return _playing;
    }
    public var emitting(get, set):Bool;

    function set_emitting(value) {
        _emitting = value;

        return value;
    }

    function get_emitting() {
        return _emitting;
    }

    public function play() {
        if (_playing) {
            return (this);
        }

        reset();

        playing = (true);
        return (this);
    }

    public function stop() {
        if (!_playing) {
            return (this);
        }

        reset();
        playing = (false);
        updateVertexBuffer();

        return (this);
    }

    public function pause() {
        playing = (false);
        return (this);
    }

    public function resume() {
        playing = (true);
        return (this);
    }
    public var isInWorldSpace(get, set):Bool;

    function get_isInWorldSpace() {
        return _isInWorldSpace;
    }
    public var localToWorld(get, null):Array<Float>;

    function get_localToWorld() {
        return _localToWorld;
    }

    public var cameraPos(get, null):Array<Float>;

    function get_cameraPos() {
        return _cameraCoords;
    }


    public function getParticleSquaredDistanceToCamera(particleIndex) {
        return _particleDistanceToCamera[particleIndex];
    }
    public var maxParticlesCount(get, null):Int;

    function get_maxParticlesCount() {
        return _maxCount;
    }
    public var countLimit(get, set):Int;

    function get_countLimit() {
        return _countLimit;
    }

    function set_countLimit(value) {
        if (value > COUNT_LIMIT) {
            throw ("A particle system can have a maximum of " + (COUNT_LIMIT) + " particles.");
        }

        _countLimit = value;

        updateMaxParticlesCount();
        return value;
    }
    public var getParticles(get, null):Array<ParticleData>;

    function get_getParticles() {
        return _particles;
    }
    public var formatFlags(get, null):Int;

    function get_formatFlags() {
        return _format;
    }

    private function setInVertexBuffer(ptr:Array<Float>, vertexIterator:Int, offset:Int, value:Float) {
        var idx = offset;
        for (i in 0... 4) {
            ptr[idx] = value;
            idx += _geometry.vertexSize;
        }
    }

    public function new(assets:AssetLibrary, rate:Float, lifetime:Sampler, shape:EmitterShape,
                        emissionDirection:StartDirection, emissionVelocity:Sampler) {
        super();
        this._geometry = ParticlesGeometry.create(assets.context);
        this._material = ParticlesProvider.create();
        this._effect = assets.effect("particles");
        this._surface = null;
        this._toWorld = null;
        this._countLimit = COUNT_LIMIT;
        this._maxCount = 0;
        this._previousLiveCount = 0;
        this._particles = [];
        this._isInWorldSpace = false;
        this._isZSorted = false;
        this._useOldPosition = false;
        this._rate = 1.0 / rate;
        this._lifetime = lifetime != null ? lifetime : cast Constant.create(1.0);
        this._shape = shape != null ? shape : Sphere.create(10);
        this._emissionDirection = emissionDirection;
        this._emissionVelocity = emissionVelocity != null ? emissionVelocity : cast Constant.create(1.0);
        this._createTimer = 0.0;
        this._format = VertexComponentFlags.DEFAULT;
        this._updateStep = 0;
        this._playing = false;
        this._emitting = true;
        this._time = 0.0 ;
        this._frameBeginSlot = null;
        if (_effect == null) {
            throw ("Effect 'particles' is not available in the asset library.");
        }

        _surface = Surface.create(_geometry, _material, _effect);

        _comparisonObject.particleSystem = (this);

        updateMaxParticlesCount();
    }


    public function initialize() {

    }

    override public function targetAdded(node:Node) {
        targetAddedHandler(this, node);
    }

    override public function targetRemoved(node:Node) {
        targetRemovedHandler(this, node);
    }

    public function targetAddedHandler(ctrl:AbstractComponent, target:Node) {
        findSceneManager();

        target.addComponent(_surface);

        var nodeCallback = function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
            findSceneManager();
        };

        _addedSlot = target.added.connect(nodeCallback);
        _removedSlot = target.removed.connect(nodeCallback);

        var componentCallback = function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
            findSceneManager();
        };

        _componentAddedSlot = target.root.componentAdded.connect(componentCallback);
        _componentRemovedSlot = target.root.componentRemoved.connect(componentCallback);
    }

    public function targetRemovedHandler(ctrl:AbstractComponent, target:Node) {
        findSceneManager();

        target.removeComponent(_surface);

        _addedSlot = null;
        _removedSlot = null;
        _componentAddedSlot = null;
        _componentRemovedSlot = null;
    }

    public function findSceneManager() {
        var roots:NodeSet = NodeSet.createbyNode(target).roots().where(function(node:Node) {
            return node.hasComponent(SceneManager);
        });

        if (roots.nodes.length > 1) {
            throw ("ParticleSystem cannot be in two separate scenes.");
        }
        else if (roots.nodes.length == 1) {
            var sceneManager:SceneManager = cast roots.nodes[0].getComponent(SceneManager);
            _frameBeginSlot = sceneManager.frameEnd.connect(frameBeginHandler);
        }
        else {
            _frameBeginSlot = null;
        }
    }

    public function frameBeginHandler(sceneManager:SceneManager, time:Float, deltaTime:Float) {
        if (!_playing) {
            return;
        }

        if (_isInWorldSpace) {
            _toWorld = cast target.getComponents(Transform)[0];
        }

        var deltaT = 1e-3 * deltaTime; // expects seconds

        if (_updateStep == 0) {
            updateSystem(deltaT, _emitting);
            updateVertexBuffer();
        }
        else {
            var changed = false;

            _time += deltaT;

            while (_time > _updateStep) {
                updateSystem(_updateStep, _emitting);
                changed = true;
                _time -= _updateStep;
            }
            if (changed) {
                updateVertexBuffer();
            }
        }
    }

    public function add(modifier:IParticleModifier) {
        addComponents(modifier.getNeededComponents());

        modifier.setProperties(_material);


        if (Std.is(modifier, IParticleInitializer)) {
            var i:IParticleInitializer = cast(modifier);
            _initializers.push(i);

            return (this);
        }


        if (Std.is(modifier, IParticleUpdater)) {
            var u:IParticleUpdater = cast(modifier);
            _updaters.push(u);
        }

        return (this);
    }

    public function remove(modifier:IParticleModifier) {


        if (Std.is(modifier, IParticleInitializer)) {
            var i:IParticleInitializer = cast(modifier);
            if (Lambda.has(_initializers, i)) {
                _initializers.remove(i);
                modifier.unsetProperties(_material);
                updateVertexFormat();

                return (this);

            }

            return (this);
        }


        if (Std.is(modifier, IParticleUpdater)) {
            var u:IParticleUpdater = cast(modifier);
            if (Lambda.has(_updaters, u)) {

                _updaters.remove(u);
                modifier.unsetProperties(_material);
                updateVertexFormat();

                return (this);

            }
        }

        return (this);
    }

    public function has(modifier:IParticleModifier) {
        if (Std.is(modifier, IParticleInitializer)) {
            var i:IParticleInitializer = cast(modifier);

            if (Lambda.has(_initializers, i)) {
                return true;
            }

            return false;
        }

        if (Std.is(modifier, IParticleUpdater)) {
            var u:IParticleUpdater = cast(modifier);
            if (Lambda.has(_updaters, u)) {
                return true;
            }

            return false;
        }

        return false;
    }

    public function fastForward(time:Float, updatesPerSecond:Int) {
        var updateStep = _updateStep;

        if (updatesPerSecond != 0) {
            updateStep = 1.0 / updatesPerSecond;
        }

        while (time > updateStep) {
            updateSystem(updateStep, _emitting);
            time -= updateStep;
        }
    }

    public function updateSystem(timeStep:Float, emit:Bool) {
        _material.set("particles.timeStep", timeStep);

        if (emit && _createTimer < _rate) {
            _createTimer += timeStep;
        }

        for (particleIndex in 0..._particles.length) {
            var particle:ParticleData = _particles[particleIndex];

            if (particle.alive) {
                particle.timeLived += timeStep;

                particle.oldx = particle.x;
                particle.oldy = particle.y;
                particle.oldz = particle.z;

                //if (part)
                //if (!(particle.timeLived < particle.lifetime))
                //    killParticle(particleIndex);
            }
        }

        for (updater in _updaters) {
            updater.update(_particles, timeStep);
        }

        for (particleIndex in 0... _particles.length) {
            var particle:ParticleData = _particles[particleIndex];

            if (!particle.alive && emit && !(_createTimer < _rate)) {
                _createTimer -= _rate;

                createParticle(particleIndex, _shape, _createTimer);

                particle.lifetime = _lifetime.value();
            }

            particle.rotation += particle.startAngularVelocity * timeStep;

            particle.startvx += particle.startfx * timeStep;
            particle.startvy += particle.startfy * timeStep;
            particle.startvz += particle.startfz * timeStep;

            particle.x += particle.startvx * timeStep;
            particle.y += particle.startvy * timeStep;
            particle.z += particle.startvz * timeStep;
        }
    }

    public function createParticle(particleIndex:Int, shape:EmitterShape, timeLived:Float) {
        var particle:ParticleData = _particles[particleIndex];

        if (_emissionDirection == StartDirection.NONE) {
            shape.initPosition(particle);

            particle.startvx = 0.0;
            particle.startvy = 0.0;
            particle.startvz = 0.0;
        }
        else if (_emissionDirection == StartDirection.SHAPE) {
            shape.initPositionAndDirection(particle);
        }
        else if (_emissionDirection == StartDirection.RANDOM) {
            shape.initPosition(particle);
        }
        else if (_emissionDirection == StartDirection.UP) {
            shape.initPosition(particle);

            particle.startvx = 0.0;
            particle.startvy = 1.0;
            particle.startvz = 0.0;
        }
        else if (_emissionDirection == StartDirection.OUTWARD) {
            shape.initPosition(particle);

            particle.startvx = particle.x;
            particle.startvy = particle.y;
            particle.startvz = particle.z;
        }

        particle.oldx = particle.x;
        particle.oldy = particle.y;
        particle.oldz = particle.z;

        if (_isInWorldSpace) {
            var transform = _toWorld.matrix.toFloatArray();

            var x = particle.x;
            var y = particle.y;
            var z = particle.z;

            particle.x = transform[0] * x + transform[1] * y + transform[2] * z + transform[3];
            particle.y = transform[4] * x + transform[5] * y + transform[6] * z + transform[7];
            particle.z = transform[8] * x + transform[9] * y + transform[10] * z + transform[11];

            if (_emissionDirection != StartDirection.NONE) {
                var vx = particle.startvx;
                var vy = particle.startvy;
                var vz = particle.startvz;

                particle.startvx = transform[0] * vx + transform[1] * vy + transform[2] * vz;
                particle.startvy = transform[4] * vx + transform[5] * vy + transform[6] * vz;
                particle.startvz = transform[8] * vx + transform[9] * vy + transform[10] * vz;
            }
        }

        if (_emissionDirection != StartDirection.NONE) {
            var norm = Math.max(1e-4, Math.sqrt(particle.startvx * particle.startvx + particle.startvy * particle.startvy + particle.startvz * particle.startvz));

            var k = _emissionVelocity.value() / norm;

            particle.startvx = particle.startvx * k;
            particle.startvy = particle.startvy * k;
            particle.startvz = particle.startvz * k;
        }

        particle.rotation = 0.0;
        particle.startAngularVelocity = 0.0;

        particle.timeLived = timeLived;

        //    particle.alive                     = true;

        //    ++_liveCount;

        for (initializer in _initializers) {
            initializer.initialize(particle, timeLived);
        }
    }

    public function updateMaxParticlesCount() {
        var value = Math.floor(Math.min(_countLimit, ( Math.ceil(_lifetime.max / _rate - 1e-3))));

        if (_maxCount == value) {
            return;
        }

        _maxCount = value;

        var liveCount = 0;
        for (particle in _particles) {
            if (particle.alive) {
                if (liveCount == _maxCount || !(particle.timeLived < _lifetime.max)) {
                    particle.kill();
                }
                else {
                    if (particle.lifetime < _lifetime.min || particle.lifetime > _lifetime.max) {
                        particle.lifetime = _lifetime.value();
                    }

                    if (particle.alive) {
                        ++liveCount;
                    }
                }
            }
        }


        //   //std::cout << "lifetime in [" << _lifetime->min() << " " << _lifetime->max() << "]" << std::endl;

        //for (unsigned int i = 0; i < _particles.size(); ++i)
        //{
        //    if (_particles[i].alive())
        //    {
        //        if (liveCount == _maxCount ||
        //            !(_particles[i].timeLived < _lifetime->max()))
        //            _particles[i].kill();
        //            //!(_particles[i].timeLived < _lifetime->max()))
        //            //;//                _particles[i].alive = false;
        //        else
        //        {
        //            //++_liveCount;
        //            if (_particles[i].lifetime > _lifetime->max() || _particles[i].lifetime < _lifetime->min())
        //                _particles[i].lifetime = _lifetime->value();

        //            liveCount += _particles[i].alive() ? 1 : 0;
        //            //if (!(_particles[i].timeLived < _particles[i].lifetime))
        //                //;// _particles[i].alive = false;
        //               //else
        //                   //++_liveCount;
        //        }
        //    }
        //}
        resizeParticlesVector();
        _geometry.initStreams(_maxCount);
    }

    public function resizeParticlesVector() {
        _particles = [];//.resize(_maxCount);
        if (_isZSorted) {
            _particleDistanceToCamera = [];//.resize(_maxCount);
            _particleOrder = [];//.resize(_maxCount);
            for (i in 0..._maxCount) {
                _particleOrder[i] = i;
            }
        }
        else {
            _particleDistanceToCamera = [];//.resize(0);
            _particleOrder = [];//.resize(0);
        }
    }

    public function updateParticleDistancesToCamera() {
        for (i in 0... _particleDistanceToCamera.length) {
            var particle:ParticleData = _particles[i];

            var x = particle.x;
            var y = particle.y;
            var z = particle.z;

            if (!_isInWorldSpace) {
                x = _localToWorld[0] * x + _localToWorld[4] * y + _localToWorld[8] * z + _localToWorld[12];
                y = _localToWorld[1] * x + _localToWorld[5] * y + _localToWorld[9] * z + _localToWorld[13];
                z = _localToWorld[2] * x + _localToWorld[6] * y + _localToWorld[10] * z + _localToWorld[14];
            }

            var deltaX = _cameraCoords[0] - x;
            var deltaY = _cameraCoords[1] - y;
            var deltaZ = _cameraCoords[2] - z;

            _particleDistanceToCamera[i] = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ;
        }
    }

    public function reset() {
        for (particle in _particles) {
            particle.kill();
        }

        //if (_liveCount == 0)
        //    return;

        //_liveCount = 0;

        //    for (auto& particle : _particles)
        //        particle.alive = false;
    }

    public function addComponents(components:Int, blockVSInit:Bool = false) {
        var OPTIONAL_COMPONENTS:Array<Tuple3<String, VertexComponentFlags, Int>> = [new Tuple3("size", VertexComponentFlags.SIZE, 1),
        new Tuple3("color", VertexComponentFlags.COLOR, 3),
        new Tuple3("time", VertexComponentFlags.TIME, 1),
        new Tuple3("oldPosition", VertexComponentFlags.OLD_POSITION, 3),
        new Tuple3("rotation", VertexComponentFlags.ROTATION, 1),
        new Tuple3("spriteIndex", VertexComponentFlags.SPRITE_INDEX, 1)];

        if (_format == components) {
            return;
        }

        _format |= components;

        // FIXME: should be made fully dynamic
        var vertexBuffer:ParticleVertexBuffer = _geometry.particleVertices;

        _geometry.removeVertexBuffer(vertexBuffer);
        for (component in OPTIONAL_COMPONENTS) {
            var attrName = component.first;

            if (vertexBuffer.hasAttribute(attrName)) {
                vertexBuffer.removeAttribute(attrName); // attribute offset must be updated
            }
        }

        // mandatory vertex attributes: offset and position
//Debug.Assert(vertexBuffer.hasAttribute("offset") && vertexBuffer.hasAttribute("position"));
        var attrOffset = 5;

        for (component in OPTIONAL_COMPONENTS) {
            var attrName = component.first;
            var attrFlag = component.second;
            var attrSize = component.thiree;

            if (((_format & attrFlag)) != 0) {
                vertexBuffer.addAttribute(attrName, attrSize, attrOffset);
                attrOffset += attrSize;
            }
        }

        _geometry.addVertexBuffer(vertexBuffer);

        if (!blockVSInit) {
            _geometry.initStreams(_maxCount);
        }
    }

    public function updateVertexFormat() {
        _format = VertexComponentFlags.DEFAULT;

        /*
		auto vb = _geometry->vertices();
		if (!vb->hasAttribute("offset"))
		    vb->addAttribute("offset", 2, 0);
		if (!vb->hasAttribute("position"))
		    vb->addAttribute("position", 3, 2);
		*/

        for (it in _initializers) {
            addComponents(it.getNeededComponents(), true);
        }

        for (it in _updaters) {
            addComponents(it.getNeededComponents(), true);
        }

        if (_useOldPosition) {
            addComponents(VertexComponentFlags.OLD_POSITION, true);
        }

        _geometry.initStreams(_maxCount);

        return _format;
    }

    public function updateVertexBuffer() {
        //if (_liveCount == 0)
        //    return;

        if (_isZSorted) {
            updateParticleDistancesToCamera();
            //todo
//std::sort(_particleOrder.begin(), _particleOrder.end(), _comparisonObject);
        }

        var vsData = _geometry.particleVertices.data;
        var vertexIterator = 0;

        var liveCount = 0;

        for (particleIndex in 0..._maxCount) {
            var particle:ParticleData = null ;

            if (_isZSorted) {
                particle = _particles[_particleOrder[particleIndex]];
            }
            else {
                particle = _particles[particleIndex];
            }

            var i = 5;

            if (particle.alive) {
                setInVertexBuffer(vsData, vertexIterator, 2, particle.x);
                setInVertexBuffer(vsData, vertexIterator, 3, particle.y);
                setInVertexBuffer(vsData, vertexIterator, 4, particle.z);

                if ((_format & VertexComponentFlags.SIZE) != 0) {
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.size);
                }

                if ((_format & VertexComponentFlags.COLOR) != 0) {
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.r);
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.g);
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.b);
                }

                if ((_format & VertexComponentFlags.TIME) != 0) {
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.timeLived / particle.lifetime);
                }

                if ((_format & VertexComponentFlags.OLD_POSITION) != 0) {
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.oldx);
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.oldy);
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.oldz);
                }

                if ((_format & VertexComponentFlags.ROTATION) != 0) {
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.rotation);
                }

                if ((_format & VertexComponentFlags.SPRITE_INDEX) != 0) {
                    setInVertexBuffer(vsData, vertexIterator, i++, particle.spriteIndex);
                }

                vertexIterator += 4 * _geometry.vertexSize;
                ++liveCount;
            }
        }

        //    std::cout << "liveCount = " << _liveCount << " " << liveCount << std::endl;
        _geometry.particleVertices.uploadOffset(0, liveCount << 2);

        if (liveCount != _previousLiveCount) {
            var particleIndices:ParticleIndexBuffer = cast(_geometry.indices);
            particleIndices.uploadOffset(0, liveCount * 6);
            _previousLiveCount = liveCount;
        }
    }

    function set_isInWorldSpace(value) {
        _isInWorldSpace = value;

        _material.isInWorldSpace = (value);

        return value;
    }
    public var isZSorted(null, set):Bool;

    function set_isZSorted(value) {
        _isZSorted = value;

        resizeParticlesVector();

        return value;
    }
    public var useOldPosition(null, set):Bool;

    function set_useOldPosition(value) {
        if (value != _useOldPosition) {
            _useOldPosition = value;
            updateVertexFormat();
        }

        return value;
    }
}
