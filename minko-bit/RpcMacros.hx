package ;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;

class RpcMacros {

#if macro
    static function buildService() {
        var pos = Context.currentPos();
        var noComplete:Metadata = [ { name : ":noCompletion", pos : pos } ];
        var cl = Context.getLocalClass().get();
        if (cl.isInterface || Context.defined("display"))
            return null;
        var fields = Context.getBuildFields();
        var toSerialize = [];
        var rpc = [];
        for (f in fields) {
            if (f.meta == null) continue;
            for (meta in f.meta) {
                if (meta.name == ":rpc") {
                    rpc.push(f);
                    break;
                }
            }
        }
        trace(rpc);
        var rpcCases = [];

        var rpcID = 0;
        for (r in rpc) {
            switch( r.kind ) {
                case FFun(f):

                    var name = r.name;
                    var p = r.pos;
                    var cargs = [for (a in f.args) { expr : EConst(CIdent(a.name)), pos : p } ];
                    var fcall = { expr : ECall({ expr : EField({ expr : EConst(CIdent("this")), pos:p }, r.name), pos : p }, cargs), pos : p };

                    var doCall = fcall;
                    var rpcArgs = f.args;

                    var exprs = [ { expr : EVars([for (a in rpcArgs) { name : a.name, type : a.opt ? TPath({ pack : [], name : "Null", params : [TPType(a.type)] }) : a.type, expr : macro cast null } ]), pos : p } ];
                    exprs.push(macro if (false) $fcall); // force typing
                    for (a in rpcArgs) {
                        var e = macro hxbit.Macros.unserializeValue(__ctx, $i{ a.name });
                        e.pos = p;
                        exprs.push(e);
                    }

                    exprs.push({ expr : EVars([ { name : "result", type : f.ret, expr : fcall } ]), pos : p });
                    exprs.push(macro {
                        @:privateAccess __clientResult.beginRPCResult();
                        hxbit.Macros.serializeValue(__ctx, result);
                    });


                    rpcCases.push({ values : [{ expr : EConst(CInt("" + rpcID)), pos : p }], guard : null, expr : { expr : EBlock(exprs), pos : p } });

                    rpcID++;

                default:
            }

        }
        if (rpc.length != 0) {
            var cases = [];

            for (i in 0...rpc.length)
                cases.push({ id : i, name : rpc[i].name.substr(0, -6) });
            var ecases = [for (c in cases) { values : [ { expr : EConst(CInt("" + c.id)), pos : pos } ], expr : { expr : EConst(CString(c.name)), pos : pos }, guard : null } ];
            var swExpr = { expr : EReturn({ expr : ESwitch(macro   id, ecases, macro null), pos : pos }), pos : pos };
            fields.push({
                name : "networkGetName",
                pos : pos,
                access : [APublic],
                meta : noComplete,
                kind : FFun({
                    args : [ { name : "id", type : macro : Int } ],
                    ret : macro : String,
                    expr : swExpr,
                }),
            });
        }

        fields = fields.concat((macro class {

            @:noCompletion public var __host:RpcHost;
            @:noCompletion public var __uid:Int = @:privateAccess hxbit.Serializer.allocUID();


        }).fields);

        var swExpr = { expr : ESwitch({ expr : EConst(CIdent("__id")), pos : pos }, rpcCases, macro throw "Unknown RPC identifier " + __id), pos : pos };
        fields.push({
            name : "networkRPC",
            pos : pos,
            access : [APublic],
            meta : noComplete,
            kind : FFun({
                args : [ { name : "__ctx", type : macro : hxbit.Serializer }, { name : "__id", type : macro : Int }, { name : "__clientResult", type : macro :RpcHost.RpcClient } ],
                ret : macro : Bool,
                expr : macro { $swExpr; return true; }
            }),
        });


        return fields;
    }


    static function buildProxy():ComplexType {
        var type = Context.getLocalType();
        return switch (type) {
            case TInst(t, [params]):

                switch (params )
                {
                    case TInst(p, _):

                        var new_pack = t.get().pack;
                        var new_name = "Proxy" + TypeTools.toString(params) ;
                        var newType = getProxyType(new_pack, new_name, p.get());
                        trace(newType);
                        Context.defineType(newType);
                        TPath({pack: new_pack, name: new_name});
                    default: Context.error("error:", Context.currentPos());
                }

            default: Context.error("error:", Context.currentPos());
        }
    }

    static function getProxyType(new_pack, new_name:String, ret:ClassType):TypeDefinition {
        var pos = Context.currentPos();

        var fields:Array<Field> = [];
        fields = fields.concat((macro class {

            @:noCompletion public var __host:RpcHost;
            @:noCompletion public var __uid:Int = @:privateAccess hxbit.Serializer.allocUID();

            @:noCompletion public function networkRPC( ctx : hxbit.Serializer, rpcID : Int, clientResult : RpcHost.RpcClient ) : Bool{
            return false;
            }
            @:noCompletion public function networkGetName( propId : Int ) : String{
            return "";
            }

        }).fields);


        var rpcID = 0;
        for (f in ret.fields.get()) {

            var rpcArgs:Array<FunctionArg> = [];
            var rpcRet:FunctionArg = null;
            var rpcRetType = cast null;
            switch (f.type){
                case TFun(args, ret):
                    trace(args);
                    for (a in args) {
                        rpcArgs.push({name: a.name, type:a.t.toComplexType()});
                    }
                    rpcRet = { name : "onResult", type: ret == null ? null : TFunction([ret.toComplexType()], macro:Void) };
                    rpcRetType = ret.toComplexType();
                default:
            }

            var resultCall = @:privateAccess hxbit.Macros.withPos(macro function(__ctx:hxbit.Serializer) {
                var v:$rpcRetType = cast null;
                hxbit.Macros.unserializeValue(__ctx, v);
                onResult(v);
            }, f.pos);


            var rpcExpr = macro {
                var __ctx = @:privateAccess __host.beginRPC(this, $v{rpcID}, $resultCall);
                $b{[
                    for (a in rpcArgs)
                        @:privateAccess hxbit.Macros.withPos(macro   hxbit.Macros.serializeValue(__ctx, $i{a.name}), f.pos)
                ] };
                @:privateAccess __host.endRPC();

            };

            rpcArgs.push(rpcRet);

            var rpc:Field = {
                name : f.name,
                access : [APublic],
                kind : FFun({
                    args : rpcArgs,
                    ret : macro : Void,
                    expr : rpcExpr,
                }),
                pos : f.pos,
                meta : [{ name : ":final", pos : f.pos }],
            };
            fields.push(rpc);
            rpcID++;
        }
        var rpcInterface = toTypePath("RpcHost.RpcClientCall");
        return {
            pos: Context.makePosition({min: 0, max: 0, file: new_name}),
            pack: new_pack,
            name:new_name,
            kind: TDClass(null, [rpcInterface], false),
            fields: fields
        };
    }
    /**
		Returns a TypePath for the string [ident], and optional paramaters [params]
	*/
    static public function toTypePath(ident:String, ?params:Array<TypeParam>):TypePath {
        // return id.toTypePath(params);

        if (params == null) params = [];

        var parts:Array<String> = ident.split(".");
        var sub:String = null;
        var name:String = parts.pop();

        if (parts.length > 0) {
            var char = parts[parts.length - 1].split("").shift();

            if (char == char.toUpperCase()) {
                sub = name;
                name = parts.pop();
            }
        }

        if (sub == name)
            sub = null;

        return {
            sub:sub,
            pack:parts,
            name:name,
            params:params
        }
    }
    #end
}