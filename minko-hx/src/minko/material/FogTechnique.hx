package minko.material;
@:expose("minko.material.FogTechnique")
@:enum abstract FogTechnique(Int) from Int to Int {
    var LIN = 1;
    var EXP = 2;
    var EXP2 = 3;
}
