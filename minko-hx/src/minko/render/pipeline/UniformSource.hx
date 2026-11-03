package minko.render.pipeline;

/**
 * Where a PipelineUniform gets its value.
 *
 * MaterialProperty reads item.material, the matrix/camera/light sources read
 * the RenderItem and FrameContext, and Constant uploads a fixed value.
 */
enum UniformSource {
    MaterialProperty(property:String);
    Constant(value:Dynamic);

    ModelMatrix;
    NormalMatrix;
    ViewMatrix;
    ProjectionMatrix;
    CameraPosition;
    Time;

    LightDirection;
    LightColor;
    LightIntensity;
    LightViewProjection;
    ShadowMap;
    HasShadowMap;
}
