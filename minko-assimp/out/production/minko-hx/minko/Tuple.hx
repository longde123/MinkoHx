package minko;
@:expose("minko.Tuple")
class Tuple<T, K> {
    public var first:T;
    public var second:K;

    public function new(f, s) {
        first = f;
        second = s;
    }
}
@:expose("minko.Tuple3")
class Tuple3<A, B, C> {
    public var first:A;
    public var second:B;
    public var thiree:C;

    public function new(f, s, t) {
        first = f;
        second = s;
        thiree = t;
    }
}
@:expose("minko.Tuple4")
class Tuple4<A, B, C, D> {
    public var first:A;
    public var second:B;
    public var thiree:C;
    public var four:D;

    public function new(a, b, c, d) {
        first = a;
        second = b;
        thiree = c;
        four = d;
    }
}
@:expose("minko.Tuple5")
class Tuple5<A, B, C, D, E> {
    public var first:A;
    public var second:B;
    public var thiree:C;
    public var four:D;
    public var five:E;

    public function new(a, b, c, d, e) {
        first = a;
        second = b;
        thiree = c;
        four = d;
        five = e;
    }
}
@:expose("minko.Tuple6")
class Tuple6<A, B, C, D, E, F> {
    public var first:A;
    public var second:B;
    public var thiree:C;
    public var four:D;
    public var five:E;
    public var six:F;

    public function new(a, b, c, d, e, f) {
        first = a;
        second = b;
        thiree = c;
        four = d;
        five = e;
        six = f;
    }
}
