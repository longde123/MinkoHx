package minko.material;
import glm.Vec2;
@:expose("minko.material.WaterMaterial")
class WaterMaterial extends PhongMaterial {
    private var _numWaves:Int;
    private var _amplitudes:Array<Float> ;
    private var _waveLength:Array<Float>;
    private var _origins:Array<Vec2>;
    private var _speeds:Array<Float>;
    private var _sharpness:Array<Float>;
    private var _waveType:Array<Int>;

    public static function createWaves(numWaves, name = "WaterMaterial") {
        return new WaterMaterial(numWaves, name);
    }

    private function setWaveProperty(propertyName:String, waveId:Int, value:Any) {
        var values:Array<Any> = data.get(propertyName);

        values[waveId] = value;
    }

    public function new(numWaves, name) {
        super(name) ;
        this._numWaves = numWaves;
        this._amplitudes = [for (i in 0...numWaves) 0.0];
        this._origins = [for (i in 0...numWaves * 2) new Vec2(1, 1)];
        this._waveLength = [for (i in 0...numWaves) 0.0];
        this._speeds = [for (i in 0...numWaves) 0.0];
        this._sharpness = [for (i in 0...numWaves) 0.0];
        this._waveType = [for (i in 0...numWaves) 0];
        data.set("numWaves", _numWaves)
        .set("waveOrigin", _origins)
        .set("waveLength", _waveLength)
        .set("waveAmplitude", _amplitudes)
        .set("waveSharpness", _sharpness)
        .set("waveSpeed", _speeds)
        .set("waveType", _waveType);
    }

    public function setDirection(waveId:Int, direction:Vec2) {
        setWaveProperty("waveOrigin", waveId, direction);
        setWaveProperty("waveType", waveId, 0);

        return (this);
    }

    public function setCenter(waveId:Int, origin:Vec2) {
        setWaveProperty("waveOrigin", waveId, origin);
        setWaveProperty("waveType", waveId, 1);

        return (this);
    }

    public function setAmplitude(waveId:Int, amplitude:Float) {
        setWaveProperty("waveAmplitude", waveId, amplitude);

        return (this);
    }

    public function setWaveLength(waveId:Int, waveLength:Float) {
        setWaveProperty("waveLength", waveId, waveLength);

        return (this);
    }

    public function setSharpness(waveId:Int, sharpness:Float) {
        setWaveProperty("waveSharpness", waveId, sharpness);

        return (this);
    }

    public function setSpeed(waveId:Int, speed:Float) {
        setWaveProperty("waveSpeed", waveId, speed);

        return (this);
    }

}
