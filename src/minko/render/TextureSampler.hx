package minko.render;
class TextureSampler {
    public var uuid:String;
    public var id:Int;
    public var mipFilter:MipFilter;
    public var textureFilter:TextureFilter;
    public var wrapMode:WrapMode;


    public function copyFrom(rhs:TextureSampler) {
        this.uuid = rhs.uuid;
        this.id = rhs.id;
        this.mipFilter = (rhs.mipFilter);
        this.textureFilter = (rhs.textureFilter);
        this.wrapMode = (rhs.wrapMode);
    }

    public function new(uuid, id) {
        this.uuid = uuid;
        this.id = id;
        this.mipFilter = (SamplerStates.DEFAULT_MIP_FILTER);
        this.textureFilter = (SamplerStates.DEFAULT_TEXTURE_FILTER);
        this.wrapMode = (SamplerStates.DEFAULT_WRAP_MODE);
    }


    public function equals(rhs:TextureSampler) {
        return this.uuid == rhs.uuid && this.id == rhs.id && this.mipFilter == rhs.mipFilter && this.textureFilter == rhs.textureFilter && this.wrapMode == rhs.wrapMode;
    }

}
