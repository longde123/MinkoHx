package minko.extension;
import minko.particle.sampler.SamplerVec3;
import minko.serialize.ParticlesTypes.EmitterShapeId;
import minko.serialize.ParticlesTypes.ModifierId;
import glm.Vec3;
import glm.Vec4;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.component.ParticleSystem;
import minko.data.ParticlesProvider;
import minko.deserialize.TypeDeserializer;
import minko.file.AssetLibrary;
import minko.file.Dependency;
import minko.file.SceneParser;
import minko.particle.modifier.ColorBySpeed;
import minko.particle.modifier.ColorOverTime;
import minko.particle.modifier.ForceOverTime;
import minko.particle.modifier.IParticleModifier;
import minko.particle.modifier.SizeBySpeed;
import minko.particle.modifier.SizeOverTime;
import minko.particle.modifier.StartAngularVelocity;
import minko.particle.modifier.StartColor;
import minko.particle.modifier.StartForce;
import minko.particle.modifier.StartRotation;
import minko.particle.modifier.StartSize;
import minko.particle.modifier.StartSprite;
import minko.particle.modifier.StartVelocity;
import minko.particle.modifier.VelocityOverTime;
import minko.particle.sampler.Constant;
import minko.particle.sampler.LinearlyInterpolatedValue;
import minko.particle.sampler.RandomValue;
import minko.particle.sampler.Sampler;
import minko.particle.shape.Box;
import minko.particle.shape.Cone;
import minko.particle.shape.Cylinder;
import minko.particle.shape.EmitterShape;
import minko.particle.shape.Point;
import minko.particle.shape.Sphere;
import minko.particle.StartDirection;
import minko.render.AbstractTexture;
import minko.serialize.ParticlesTypes.SamplerId;
import minko.serialize.Types.ComponentId;
using minko.utils.BytesTool;
class ParticlesExtension extends AbstractExtension {

    public static function initialize() {
        return new ParticlesExtension();
    }

    public function new() {
    }

   override public function bind() {
        SceneParser.registerComponent(ComponentId.PARTICLES, ParticlesExtension.deserializeParticles);
    }

    public function deserializeParticles(serialized:Bytes, assets:AssetLibrary, dependencies:Dependency) {
//msgpack.type.tuple<ushort, string, @uint, bool, bool, bool, @uint, IdAndString, IdAndString, IdAndString, List<IdAndString>>

        var dst = new BytesInput(serialized);


        var matId = dst.readInt16();
        var rate = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var startDirection:StartDirection = ( dst.readInt32());
        var emit:Bool = dst.readInt8();
        var inWorldSpace:Bool = dst.readInt8();
        var zSorted:Bool = dst.readInt8();
        var countLimit = dst.readInt32();
        var lifetime = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var shape = deserializeEmitterShape(dst.readInt8(), dst.readOneBytes());
        var startVelocity = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());

        var particles:ParticleSystem = ParticleSystem.create(assets, rate, lifetime, shape, startDirection, startVelocity);
        particles.emitting = (emit);

        var mlen = dst.readInt32();
        for (modifier in 0...mlen) {
            var mod = deserializeParticleModifier(dst.readInt8(), dst.readOneBytes());

            if (mod) {
                particles.add(mod);
            }
        }

        // retrieve the diffuse color and diffuse texture from associated material if any
        var particleColor:Vec4 = null;
        var particleMap:AbstractTexture = null; // FIXME

        var material:ParticlesProvider = dependencies.getMaterialReference(matId);
        if (material) {
            // FIXME !!
            var PNAME_COLOR = "diffuseColor";
            var PNAME_SPRITESHEET = "diffuseMap";

            for (pname in material.propertyNames) {
                var pos = pname.lastIndexOf('.');
                var suffix = pos != -1 ? pname.substr(pos + 1) : pname;

                if (suffix == PNAME_COLOR) {
                    particleColor = material.getbyValue(pname, true);
                }
                else if (suffix == PNAME_SPRITESHEET) {
                    particleMap = material.getbyValue(pname, true);
                }
            }
        }

        if (particleColor != null) {
            particles.material.diffuseColor = (particleColor);
        }
        if (particleMap != null) {
            particles.material.diffuseMap = (particleMap);
        }

        return particles.play();
    }

    public function deserializeParticleModifier(id:ModifierId, serialized:Bytes):IParticleModifier {
        switch (id)
        {
            case ModifierId.START_COLOR:
                return deserializeStartColorInitializer(serialized);
            case ModifierId.START_FORCE:
                return deserializeStartForceInitializer(serialized);
            case ModifierId.START_ROTATION:
                return deserializeStartRotationInitializer(serialized);
            case ModifierId.START_SIZE:
                return deserializeStartSizeInitializer(serialized);
            case ModifierId.START_SPRITE:
                return deserializeStartSpriteInitializer(serialized);
            case ModifierId.START_VELOCITY:
                return deserializeStartVelocityInitializer(serialized);
            case ModifierId.START_ANGULAR_VELOCITY:
                return deserializeStartAngularVelocityInitializer(serialized);
            case ModifierId.COLOR_BY_SPEED:
                return deserializeColorBySpeedUpdater(serialized);
            case ModifierId.COLOR_OVER_TIME:
                return deserializeColorOverTimeUpdater(serialized);
            case ModifierId.FORCE_OVER_TIME:
                return deserializeForceOverTimeUpdater(serialized);
            case ModifierId.SIZE_BY_SPEED:
                return deserializeSizeBySpeedUpdater(serialized);
            case ModifierId.SIZE_OVER_TIME:
                return deserializeSizeOverTimeUpdater(serialized);
            case ModifierId.VELOCITY_OVER_TIME:
                return deserializeVelocityOverTimeUpdater(serialized);
            default:
                throw ("Failed to deserialized particle modifier.");
        }
        return null;
    }

    public function deserializeStartColorInitializer(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);
        var color = deserializeColorSampler(dst.readInt8(), dst.readOneBytes());
        return StartColor.create(color);
    }

    public function deserializeStartForceInitializer(serialized:Bytes):StartForce {
        var dst = new BytesInput(serialized);

        var fx = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var fy = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var fz = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return StartForce.create(fx, fy, fz);

    }

    public function deserializeStartRotationInitializer(serialized:Bytes):StartRotation {
        var dst = new BytesInput(serialized);
        var rotation = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return StartRotation.create(rotation);
    }

    public function deserializeStartSizeInitializer(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);
        var size = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return StartSize.create(size);
    }

    public function deserializeStartSpriteInitializer(serialized:Bytes):IParticleModifier {
//msgpack.type.tuple<@uint, @uint, IdAndString>
        var dst = new BytesInput(serialized);
        var startSpriteTuple = new Tuple<Int, Int>(dst.readInt32(), dst.readInt32());
        var sprite = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return StartSprite.create(sprite, startSpriteTuple.first, startSpriteTuple.second);
    }

    public function deserializeStartVelocityInitializer(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);

        var vx = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var vy = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var vz = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return StartVelocity.create(vx, vy, vz);
    }

    public function deserializeStartAngularVelocityInitializer(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);
        var angVelocity = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return StartAngularVelocity.create(angVelocity);
    }

    public function deserializeColorBySpeedUpdater(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);

        var color = deserializeColorSampler(dst.readInt8(), dst.readOneBytes());
        var linearColor:LinearlyInterpolatedValue<Vec3> = cast (color);
        if (linearColor == null) {
            throw ("Failed to initialize color-by-speed modifier.");
        }

        return ColorBySpeed.create(linearColor);
    }

    public function deserializeColorOverTimeUpdater(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);

        var color = deserializeColorSampler(dst.readInt8(), dst.readOneBytes());
        var linearColor:LinearlyInterpolatedValue < Vec3> = cast (color);
        if (linearColor == null) {
            throw ("Failed to initialize color-over-time modifier.");
        }

        return ColorOverTime.create(linearColor);
    }

    public function deserializeForceOverTimeUpdater(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);

        var fx = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var fy = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var fz = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return ForceOverTime.create(fx, fy, fz);
    }

    public function deserializeSizeBySpeedUpdater(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);
        var size = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var linearSize:LinearlyInterpolatedValue < Float > = cast (size);
        if (linearSize == null) {
            throw ("Failed to initialize size-by-speed modifier.");
        }

        return SizeBySpeed.create(linearSize);
    }

    public function deserializeSizeOverTimeUpdater(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);

        var size = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var linearSize:LinearlyInterpolatedValue < Float > = cast(size);
        if (linearSize == null) {
            throw ("Failed to initialize size-over-time modifier.");
        }

        return SizeOverTime.create(linearSize);
    }

    public function deserializeVelocityOverTimeUpdater(serialized:Bytes):IParticleModifier {
        var dst = new BytesInput(serialized);

        var vx = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var vy = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        var vz = deserializeFloatSampler(dst.readInt8(), dst.readOneBytes());
        return VelocityOverTime.create(vx, vy, vz);
    }

    public function deserializeEmitterShape(id:EmitterShapeId, serialized:String):EmitterShape {
        switch (id)
        {
            case EmitterShapeId.CYLINDER:
                return deserializeCylinderShape(serialized);
            case EmitterShapeId.CONE:
                return deserializeConeShape(serialized);
            case EmitterShapeId.SPHERE:
                return deserializeSphereShape(serialized);
            case EmitterShapeId.POINT:
                return deserializePointShape(serialized);
            case EmitterShapeId.BOX:
                return deserializeBoxShape(serialized);
            case EmitterShapeId.UNKNOWN:
            default:
                throw ("Failed to deserialized emitter shape.");
        }
        return null;
    }

    public function deserializeConeShape(serialized:Bytes):EmitterShape {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a2 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a3 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        return Cone.create(a0, a1, a2, a3);
    }

    public function deserializeCylinderShape(serialized:Bytes):EmitterShape {
        var dst = new BytesInput(serialized);
        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a2 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        return Cylinder.create(a0, a1, a2);
    }

    public function deserializePointShape(serialized:Bytes) {
        return Point.create();
    }

    public function deserializeSphereShape(serialized:Bytes):EmitterShape {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        return Sphere.create(a0, a1);
    }

    public function deserializeBoxShape(serialized:Bytes):EmitterShape {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a2 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        return Box.create(a0, a1, a2, dst.readInt32() != 0);
    }

    public function deserializeFloatSampler(id:SamplerId, serialized:Bytes):Sampler {
        switch (id)
        {
            case SamplerId.CONSTANT_NUMBER:
                return deserializeConstantNumberSampler(serialized);
            case SamplerId.LINEAR_NUMBER:
                return deserializeLinearNumberSampler(serialized);
            case SamplerId.RANDOM_NUMBER:
                return deserializeRandomNumberSampler(serialized);
            case SamplerId.UNKNOWN:
                return null;
            default:
                throw ("Failed to deserialized float sampler.");
        }
    }

    public function deserializeColorSampler(id:SamplerId, serialized:Bytes):SamplerVec3 {
        switch (id)
        {
            case SamplerId.CONSTANT_COLOR:
                return deserializeConstantColorSampler(serialized);
            case SamplerId.LINEAR_COLOR:
                return deserializeLinearColorSampler(serialized);
            case SamplerId.RANDOM_COLOR:
                return deserializeRandomColorSampler(serialized);
            case SamplerId.UNKNOWN:
                return null;
            default:
                throw ("Failed to deserialized color sampler.");
        }
    }

    public function deserializeConstantNumberSampler(serialized:Bytes):Sampler  {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        return Constant.create(a0);
    }

    public function deserializeLinearNumberSampler(serialized:Bytes):Sampler  {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a2 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a3 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        return LinearlyInterpolatedValue.create(a0, a1, a2, a3);
    }

    public function deserializeRandomNumberSampler(serialized:Bytes):Sampler {
        var dst = new BytesInput(serialized);


        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        return RandomValue.create(a0, a1);
    }

    public function deserializeConstantColorSampler(serialized:Bytes):SamplerVec3 {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a2 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        var color = new Vec3(a0, a1, a2);
        return Constant.create(color);
    }

    public function deserializeLinearColorSampler(serialized:Bytes):SamplerVec3 {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a2 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a3 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a4 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a5 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a6 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a7 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        var startColor = new Vec3(a0, a1, a2);
        var endColor = new Vec3(a3, a4, a5);
        return LinearlyInterpolatedValue.create(startColor, endColor, a6, a7);
    }

    public function deserializeRandomColorSampler(serialized:Bytes):SamplerVec3 {
        var dst = new BytesInput(serialized);

        var a0 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a1 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a2 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a3 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a4 = TypeDeserializer.deserializeFloat(dst.readOneBytes());
        var a5 = TypeDeserializer.deserializeFloat(dst.readOneBytes());

        var minColor = new Vec3(a0, a1, a2);
        var maxColor = new Vec3(a3, a4, a5);
        return RandomValue.create(minColor, maxColor);
    }

}
