package minko;
@:enum abstract CloneOption(Int) from Int to Int {
    var SHALLOW = 0;
    var DEEP = 1;
}
