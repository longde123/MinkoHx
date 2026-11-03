package minko.render.pipeline;

/**
 * Binds a shader uniform name to a UniformSource.
 */
class PipelineUniform {
    public var name:String;
    public var source:UniformSource;

    public function new(name:String, source:UniformSource) {
        this.name = name;
        this.source = source;
    }

    public static function material(name:String, property:String):PipelineUniform {
        return new PipelineUniform(name, MaterialProperty(property));
    }

    public static function constant(name:String, value:Dynamic):PipelineUniform {
        return new PipelineUniform(name, Constant(value));
    }
}
