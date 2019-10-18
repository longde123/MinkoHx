package ;
import hxbit.NetworkHost;
import hxbit.Serializable;
import hxbit.Serializer;

interface  RpcClientCall   {
    /** Unique identifier for the object, automatically set on new() **/
    public var __uid : Int;
    public var __host : RpcHost;

    public function networkRPC( ctx :  Serializer, rpcID : Int, clientResult : RpcClient ) : Bool;
    public function networkGetName( propId : Int  ) : String;
}
class RpcClient {
    public var host:RpcHost;
    public var resultID : Int;
    public var lastMessage : Float;
    var needAlive : Bool;
    public function new(h) {
        this.host = h;
    }
    public function alive() : Void{

    } // user defined
    public function send(bytes:haxe.io.Bytes) {

    }

    public function error(msg:String) {
        throw msg;
    }

    public function processMessage(bytes:haxe.io.Bytes, pos:Int) {
        var ctx = host.ctx;
        ctx.setInput(bytes, pos);
        var mid = ctx.getByte();
        switch( mid ) {
            case RpcHost.RPC:
                var oid = ctx.getInt();
                var o:RpcClientCall = cast host.calls[oid];
                var size = ctx.getInt32();
                var fid = ctx.getByte();
                if (o == null) {
                    if (size < 0)
                        throw "RPC on unreferenced object cannot be skip on this platform";
                    ctx.skip(size);
                } else {
                    o.networkRPC(ctx, fid, this); // ignore result (client made an RPC on since-then removed object - it has been canceled)
                }
                if (host.logger != null) {
                    host.logger("RPC < " + o + "#" + o.__uid + " " + o.networkGetName(fid));
                }
            case RpcHost.RPC_WITH_RESULT:

                var old = resultID;
                resultID = ctx.getInt();
                var oid = ctx.getInt();
                var o:RpcClientCall = cast  host.calls[oid];
                var size = ctx.getInt32();
                var fid = ctx.getByte();
                if (o == null) {
                    if (size < 0)
                        throw "RPC on unreferenced object cannot be skip on this platform";
                    ctx.skip(size);
                    ctx.addByte(RpcHost.CANCEL_RPC);
                    ctx.addInt(resultID);

                } else {
                    if (!o.networkRPC(ctx, fid, this)) {
                        ctx.addByte(RpcHost.CANCEL_RPC);
                        ctx.addInt(resultID);
                    }
                }

                if (host.checkEOM) ctx.addByte(RpcHost.EOM);

                host.doSend();
                host.targetClient = null;
                resultID = old;

            case RpcHost.RPC_RESULT:

                var resultID = ctx.getInt();
                var callb = host.rpcWaits.get(resultID);
                host.rpcWaits.remove(resultID);
                callb(ctx);

            case RpcHost.CANCEL_RPC:

                var resultID = ctx.getInt();
                host.rpcWaits.remove(resultID);
        }
        return @:privateAccess ctx.inPos;
    }
    public function beginRPCResult() {


        if( host.logger != null )
            host.logger("RPC RESULT #" + resultID);

        var ctx = host.ctx;
        host.targetClient = host.self ;
        ctx.addByte(RpcHost.RPC_RESULT);
        ctx.addInt(resultID);
        // after that RPC will add result value then return
    }


    var pendingBuffer : haxe.io.Bytes;
    var pendingPos : Int;
    var messageLength : Int = -1;

    function readData( input : haxe.io.Input, available : Int ) {
        if( messageLength < 0 ) {
            if( available < 4 )
                return false;
            messageLength = input.readInt32();
            if( pendingBuffer == null || pendingBuffer.length < messageLength )
                pendingBuffer = haxe.io.Bytes.alloc(messageLength);
            pendingPos = 0;
        }
        var len = input.readBytes(pendingBuffer, pendingPos, messageLength - pendingPos);
        pendingPos += len;
        if( pendingPos == messageLength ) {
            processMessagesData(pendingBuffer, 0, messageLength);
            messageLength = -1;
            return true;
        }
        return false;
    }

    function processMessagesData( data : haxe.io.Bytes, pos : Int, length : Int ) {
        if( length > 0 )
            lastMessage = haxe.Timer.stamp();
        var end = pos + length;
        while( pos < end ) {
            var oldPos = pos;
            pos = processMessage(data, pos);
            if( pos < 0 )
                break;
            if( host.checkEOM ) {
                if( data.get(pos) != RpcHost.EOM ) {
                    var len = end - oldPos;
                    if( len > 128 ) len = 128;
                    throw "Message missing EOM @"+(pos - oldPos)+":"+data.sub(oldPos, len).toHex();
                }
                pos++;
            }
        }
        if( needAlive ) {
            needAlive = false;
            host.makeAlive();
        }
    }

    public function stop() {
        if( host == null ) return;
        host.clients.remove(this);
        host.pendingClients.remove(this);
        host = null;
    }
}
class RpcHost {
    public static inline var RPC = 0;
    public static inline var RPC_WITH_RESULT = 1;
    public static inline var RPC_RESULT = 2;
    public static inline var CANCEL_RPC = 3;
    public static inline var EOM = 0xFF;

    public static var CLIENT_TIMEOUT = 60. * 60.; // 1 hour timeout
    public var sendRate : Float = 0.;
    public var totalSentBytes : Int = 0;
    var lastSentTime : Float = 0.;
    var lastSentBytes = 0;
    public var calls:Array<RpcClientCall>;
    public var rpcPosition:Int;
    public var ctx:Serializer;
    public var rpcUID = Std.random(0x1000000);
    public var rpcWaits = new Map<Int, Serializer -> Void>();
    public var logger : String -> Void;
    public var targetClient : RpcClient;
    public var pendingClients : Array<RpcClient>;
    public var clients:Array<RpcClient>;
    public var self:RpcClient;
    public var checkEOM(get, never):Bool;

    var perPacketBytes = 20; // IP + UDP headers
    inline function get_checkEOM() return true;

    public function new() {
        calls=[];
        clients = [];
        pendingClients=[];
        resetState();
    }
    public function makeAlive() {
    }
    public function resetState() {
        hxbit.Serializer.resetCounters();
        ctx = new Serializer();
        @:privateAccess ctx.newObjects = [];
        ctx.begin();
    }

    public function beginRPC(o:RpcClientCall, id:Int, onResult:Serializer -> Void) {

        if (ctx.refs[ o.__uid] == null)
            throw "Can't call RPC on an object not previously transferred";
        if (onResult != null) {
            var id = rpcUID++;
            ctx.addByte(RPC_WITH_RESULT);
            ctx.addInt(id);
            rpcWaits.set(id, onResult);
        } else
            ctx.addByte(RPC);
        ctx.addInt(o.__uid);
        #if hl
		rpcPosition = @:privateAccess ctx.out.pos;
		#end
        ctx.addInt32(-1);
        ctx.addByte(id);

        return ctx;
    }

    public function endRPC() {
        #if hl
		@:privateAccess ctx.out.b.setI32(rpcPosition, ctx.out.pos - (rpcPosition + 5));
		#end
        if (checkEOM) ctx.addByte(EOM);
    }
    public function doSend() {
        var bytes;
        @:privateAccess {
            bytes = ctx.out.getBytes();
            ctx.out = new haxe.io.BytesBuffer();
        }
        send(bytes);
    }

    public function send( bytes : haxe.io.Bytes ) {
        if( targetClient != null ) {
            totalSentBytes += (bytes.length + perPacketBytes);
            targetClient.send(bytes);
        }
        else {
            totalSentBytes += (bytes.length + perPacketBytes) * clients.length;
            if( clients.length == 0 ) totalSentBytes += bytes.length + perPacketBytes; // still count for statistics
            for( c in clients )
                c.send(bytes);
        }
    }

    public dynamic function logError( msg : String, ?objectId : Int ) {
        throw msg + (objectId == null ? "":  "(" + objectId + ")");
    }
    function fullSync( c : RpcClient ) {
        if( !pendingClients.remove(c) )
            return;
        flush();
    }
    public function flush() {
        if( @:privateAccess ctx.out.length > 0 ) doSend();
        // update sendRate
        var now = haxe.Timer.stamp();
        var dt = now - lastSentTime;
        if( dt < 1 )
            return;
        var db = totalSentBytes - lastSentBytes;
        var rate = db / dt;
        if( sendRate == 0 || rate == 0 || rate / sendRate > 3 || sendRate / rate > 3 )
            sendRate = rate;
        else
            sendRate = sendRate * 0.8 + rate * 0.2; // smooth
        lastSentTime = now;
        lastSentBytes = totalSentBytes;

        // check for unresponsive clients (nothing received from them)
        for( c in clients )
            if( now - c.lastMessage > CLIENT_TIMEOUT )
                c.stop();
    }
}