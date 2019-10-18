package minko.file;
import minko.component.Surface;
typedef ForwardingFunction = Surface -> Void;
typedef SubstitutionFunction = Array<Surface> -> Array<Surface> -> Void;

class SurfaceOperator {

    public var forwardingFunction:ForwardingFunction;
    public var substitutionFunction:SubstitutionFunction;
}


