package ;

class Test {
    static function main() {
        trace("Haxe is great!"); 
        var a:Proxy<A>;
//        var b:Proxy<B>;

        var a:AA=new AA(); 
    }
}
//typedef AA=Proxy<A>;

 interface B  {
     public function requestResponse ( a:Int,b:Float) :Int;
     public function response ( a:Int ) :Int;

}
class  AA implements Service   implements A {
    public function new(){}
    @:rpc
    public function requestResponse (  a:Int) :{b:Float}{
        return {b:1};
    }
}
interface A  {
    public function requestResponse (  a:Int) :{b:Float};
}

@:genericBuild(RpcMacros.buildProxy())
class Proxy<T>    {
   
}
@:autoBuild(RpcMacros.buildService())
interface Service    {
 
}