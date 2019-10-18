package assimp.format.gltf2.schema;
typedef TGlTfId = Int;
@:enum abstract TMeshPrimitiveType(Int) {
    var POINTS = 0;
    var LINES = 1;
    var LINE_LOOP = 2;
    var LINE_STRIP = 3;
    var TRIANGLES = 4;
    var TRIANGLE_STRIP = 5;
    var TRIANGLE_FAN = 6;
}
/**
 *  The material's alpha rendering mode enumeration specifying the interpretation of the alpha value of the main factor and texture.
 */
@:enum abstract TAlphaMode (String) from String to String{
    /**
     *  The alpha value is ignored and the rendered output is fully opaque.
     */
    var OPAQUE = "OPAQUE";

    /**
     *  The rendered output is either fully opaque or fully transparent depending on the alpha value and the specified alpha cutoff value.
     */
    var MASK = "MASK";

    /**
     *  The alpha value is used to composite the source and destination areas. The rendered output is combined with the background using the normal painting operation (i.e. the Porter and Duff over operator).
     */
    var BLEND = "BLEND";
}

/**
 *  The image's MIME type.
 */
@:enum abstract TImageMimeType(String) from String to String{
    var JPEG = "image/jpeg";
    var PNG = "image/png";
}

/**
 *  Specifies if the camera uses a perspective or orthographic projection.  Based on this, either the camera's `perspective` or `orthographic` property will be defined.
 */
@:enum abstract TCameraType(String) {
    var PERSPECTIVE = "perspective";
    var ORTHOGRAPHIC = "orthographic";
}
typedef TGLTFProperty = {
    @:optional var extensions:Dynamic;
    @:optional var extras:Dynamic;
}
typedef TGLTFChildOfRootProperty = {
>TGLTFProperty,
    /**
     *  The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name.
     */
    @:optional var name:String;
}

/**
 *  The target that the GPU buffer should be bound to.
 */
@:enum abstract TBufferTarget(Int) {
    var ARRAY_BUFFER = 34962;
    var ELEMENT_ARRAY_BUFFER = 34963;
}

/**
 *  Interpolation algorithm.
 */
@:enum abstract TAnimationInterpolation(String) {
    /**
     *  The animated values are linearly interpolated between keyframes. When targeting a rotation, spherical linear interpolation (slerp) should be used to interpolate quaternions. The number output of elements must equal the number of input elements.
     */
    var LINEAR = "LINEAR";

    /**
     *  The animated values remain constant to the output of the first keyframe, until the next keyframe. The number of output elements must equal the number of input elements.
     */
    var STEP = "STEP";

    /**
     *  The animation's interpolation is computed using a uniform Catmull-Rom spline. The number of output elements must equal two more than the number of input elements. The first and last output elements represent the start and end tangents of the spline. There must be at least four keyframes when using this interpolation.
     */
    var CATMULLROMSPLINE = "CATMULLROMSPLINE";

    /**
     *  The animation's interpolation is computed using a cubic spline with specified tangents. The number of output elements must equal three times the number of input elements. For each input element, the output stores three elements, an in-tangent, a spline vertex, and an out-tangent. There must be at least two keyframes when using this interpolation.
     */
    var CUBICSPLINE = "CUBICSPLINE";
}
@:enum abstract TAttributeType(String) {
    var SCALAR = "SCALAR";
    var VEC2 = "VEC2";
    var VEC3 = "VEC3";
    var VEC4 = "VEC4";
    var MAT2 = "MAT2";
    var MAT3 = "MAT3";
    var MAT4 = "MAT4";
}
@:enum abstract TAnimationChannelTargetPath(String) {
    var TRANSLATION = "translation";
    var ROTATION = "rotation";
    var SCALE = "scale";
    var WEIGHTS = "weights";
}
/**
 *  The datatype of components in the attribute.  All valid values correspond to WebGL enums.  The corresponding typed arrays are `Int8Array`, `Uint8Array`, `Int16Array`, `Uint16Array`, `Uint32Array`, and `Float32Array`, respectively.  5125 (UNSIGNED_INT) is only allowed when the accessor contains indices, i.e., the accessor is only referenced by `primitive.indices`.
 */
@:enum abstract TComponentType(Int) {
    var BYTE = 5120;
    var UNSIGNED_BYTE = 5121;
    var SHORT = 5122;
    var UNSIGNED_SHORT = 5123;
    var UNSIGNED_INT = 5125;
    var FLOAT = 5126;
}

/**
 * Indices of those attributes that deviate from their initialization value.
 */
typedef TAccessorSparseIndices = {
>TGLTFProperty,
    /**
   * The index of the bufferView with sparse indices. Referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target.
   */
    var bufferView:TGlTfId;
    /**
   * The offset relative to the start of the bufferView in bytes. Must be aligned.
   */
    @:optional var byteOffset:Float;
    /**
   * The indices data type.
   */
    var componentType:TComponentType;// 5121 | 5123 | 5125 | number;

}
/**
 * Array of size `accessor.sparse.count` times number of components storing the displaced accessor attributes pointed by `accessor.sparse.indices`.
 */
typedef TAccessorSparseValues = {
>TGLTFProperty,
    /**
   * The index of the bufferView with sparse values. Referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target.
   */
    var bufferView:TGlTfId;
    /**
   * The offset relative to the start of the bufferView in bytes. Must be aligned.
   */
    @:optional var byteOffset:Float;
}
/**
 * Sparse storage of attributes that deviate from their initialization value.
 */
typedef TAccessorSparse = {
>TGLTFProperty,
    /**
   * Number of entries stored in the sparse array.
   */
    var count:Float;
    /**
   * Index array of size `count` that points to those accessor attributes that deviate from their initialization value. Indices must strictly increase.
   */
    var indices:TAccessorSparseIndices;
    /**
   * Array of size `count` times number of components, storing the displaced accessor attributes pointed by `indices`. Substituted values must have the same `componentType` and number of components as the base accessor.
   */
    var values:TAccessorSparseValues;

}
/**
 * A typed view into a bufferView.  A bufferView contains raw binary data.  An accessor provides a typed view into a bufferView or a subset of a bufferView similar to how WebGL's `vertexAttribPointer()` defines an attribute in a buffer.
 */
typedef TAccessor = {
>TGLTFChildOfRootProperty,
    /**
   * The index of the bufferView.
   */
    @:optional var bufferView:TGlTfId;
    /**
   * The offset relative to the start of the bufferView in bytes.
   */
    @:optional var byteOffset:Int;
    /**
   * The datatype of components in the attribute.
   */
    var componentType:TComponentType;// 5120 | 5121 | 5122 | 5123 | 5125 | 5126 | number;
    /**
   * Specifies whether integer data values should be normalized.
   */
    @:optional var normalized:Bool;
    /**
   * The number of attributes referenced by this accessor.
   */
    var count:Int;
    /**
   * Specifies if the attribute is a scalar, vector, or matrix.
   */
    var type:TAttributeType;
    /**
   * Maximum value of each component in this attribute.
   */
    @:optional var max:Array<Float>;
    /**
   * Minimum value of each component in this attribute.
   */
    @:optional var min:Array<Float>;
    /**
   * Sparse storage of attributes that deviate from their initialization value.
   */
    @:optional var sparse:TAccessorSparse;

}
/**
 *  The name of the node's TRS property to modify, or the \"weights\" of the Morph Targets it instantiates.
 */

/**
 * The index of the node and TRS property that an animation channel targets.
 */
typedef TAnimationChannelTarget = {
>TGLTFProperty,
    /**
   * The index of the node to target.
   */
    @:optional var node:TGlTfId;
    /**
   * The name of the node's TRS property to modify, or the "weights" of the Morph Targets it instantiates. For the "translation" property, the values that are provided by the sampler are the translation along the x, y, and z axes. For the "rotation" property, the values are a quaternion in the order (x, y, z, w), where w is the scalar. For the "scale" property, the values are the scaling factors along the x, y, and z axes.
   */
    var path:TAnimationChannelTargetPath;

}
/**
 * Targets an animation's sampler at a node's property.
 */
typedef TAnimationChannel = {
>TGLTFProperty,
    /**
   * The index of a sampler in this animation used to compute the value for the target.
   */
    var sampler:TGlTfId;
    /**
   * The index of the node and TRS property to target.
   */
    var target:TAnimationChannelTarget;
}


/**
 * Combines input and output accessors with an interpolation algorithm to define a keyframe graph (but not its target).
 */
typedef TAnimationSampler = {
>TGLTFProperty,
    /**
   * The index of an accessor containing keyframe input values, e.g., time.
   */
    var input:TGlTfId;
    /**
   * Interpolation algorithm.
   */
    @:optional var interpolation:TAnimationInterpolation;//"LINEAR" | "STEP" | "CUBICSPLINE" | string;
    /**
   * The index of an accessor, containing keyframe output values.
   */
    var output:TGlTfId;
}
/**
 * A keyframe animation.
 */
typedef TAnimation = {
>TGLTFChildOfRootProperty,
    /**
   * An array of channels, each of which targets an animation's sampler at a node's property. Different channels of the same animation can't have equal targets.
   */
    var channels:Array<TAnimationChannel>;
    /**
   * An array of samplers that combines input and output accessors with an interpolation algorithm to define a keyframe graph (but not its target).
   */
    var samplers:Array<TAnimationSampler>;

}
/**
 * Metadata about the glTF asset.
 */
typedef TAsset = {
>TGLTFProperty,
    /**
   * A copyright message suitable for display to credit the content creator.
   */
    @:optional var copyright:String;
    /**
   * Tool that generated this glTF model.  Useful for debugging.
   */
    @:optional var generator:String;
    /**
   * The glTF version that this asset targets.
   */
    var version:String;
    /**
   * The minimum glTF version that this asset targets.
   */
    @:optional var minVersion:String;

}
/**
 * A buffer points to binary geometry, animation, or skins.
 */
typedef TBuffer = {
>TGLTFChildOfRootProperty,
    /**
   * The uri of the buffer.
   */
    @:optional var uri:String;
    /**
   * The length of the buffer in bytes.
   */
    var byteLength:Float;
}
/**
 * A view into a buffer generally representing a subset of the buffer.
 */
typedef TBufferView = {
>TGLTFChildOfRootProperty,
    /**
   * The index of the buffer.
   */
    var buffer:TGlTfId;
    /**
   * The offset into the buffer in bytes.
   */
    @:optional var byteOffset:Int;
    /**
   * The total byte length of the buffer view.
   */
    var byteLength:Int;
    /**
   * The stride, in bytes.
   */
    @:optional var byteStride:Int;
    /**
   * The target that the GPU buffer should be bound to.
   */
    @:optional var target:TBufferTarget;
}
/**
 * An orthographic camera containing properties to create an orthographic projection matrix.
 */
typedef TCameraOrthographic = {
>TGLTFProperty,
    /**
   * The floating-point horizontal magnification of the view. Must not be zero.
   */
    var xmag:Float;
    /**
   * The floating-point vertical magnification of the view. Must not be zero.
   */
    var ymag:Float;
    /**
   * The floating-point distance to the far clipping plane. `zfar` must be greater than `znear`.
   */
    var zfar:Float;
    /**
   * The floating-point distance to the near clipping plane.
   */
    var znear:Float;

}
/**
 * A perspective camera containing properties to create a perspective projection matrix.
 */
typedef TCameraPerspective = {
>TGLTFProperty,
    /**
   * The floating-point aspect ratio of the field of view.
   */
    @:optional var aspectRatio:Float;
    /**
   * The floating-point vertical field of view in radians.
   */
    var yfov:Float;
    /**
   * The floating-point distance to the far clipping plane.
   */
    @:optional var zfar:Float;
    /**
   * The floating-point distance to the near clipping plane.
   */
    var znear:Float;
}
/**
 * A camera's projection.  A node can reference a camera to apply a transform to place the camera in the scene.
 */
typedef TCamera = {
>TGLTFChildOfRootProperty,
    /**
   * An orthographic camera containing properties to create an orthographic projection matrix.
   */
    @:optional var orthographic:TCameraOrthographic;
    /**
   * A perspective camera containing properties to create a perspective projection matrix.
   */
    @:optional var perspective:TCameraPerspective;
    /**
   * Specifies if the camera uses a perspective or orthographic projection.
   */
    var type:TCameraType;
}
/**
 * Image data used to create a texture. Image can be referenced by URI or `bufferView` index. `mimeType` is required in the latter case.
 */
typedef TImage = {
>TGLTFChildOfRootProperty,
    /**
   * The uri of the image.
   */
    @:optional var uri:String;
    /**
   * The image's MIME type. Required if `bufferView` is defined.
   */
    @:optional var mimeType:TImageMimeType;
    /**
   * The index of the bufferView that contains the image. Use this instead of the image's uri property.
   */
    @:optional var bufferView:TGlTfId;

}
/**
 * Reference to a texture.
 */
typedef TTextureInfo = {
>TGLTFProperty,
    /**
   * The index of the texture.
   */
    var index:TGlTfId;
    /**
   * The set index of texture's TEXCOORD attribute used for texture coordinate mapping.
   */
    @:optional var texCoord:Int;

}
/**
 * A set of parameter values that are used to define the metallic-roughness material model from Physically-Based Rendering (PBR) methodology.
 */
typedef TMaterialPbrMetallicRoughness = {
>TGLTFProperty,
    /**
   * The material's base color factor.
   */
    @:optional var baseColorFactor:Array<Float>;
    /**
   * The base color texture.
   */
    @:optional var baseColorTexture:TTextureInfo;
    /**
   * The metalness of the material.
   */
    @:optional var metallicFactor:Float;
    /**
   * The roughness of the material.
   */
    @:optional var roughnessFactor:Float;
    /**
   * The metallic-roughness texture.
   */
    @:optional var metallicRoughnessTexture:TTextureInfo;

}

typedef TMaterialNormalTextureInfo = {
>TGLTFProperty,
    @:optional var index:Dynamic;
    @:optional var texCoord:Dynamic;
    /**
   * The scalar multiplier applied to each normal vector of the normal texture.
   */
    @:optional var scale:Float;

}
typedef TMaterialOcclusionTextureInfo = {
>TGLTFProperty,
    @:optional var index:Dynamic;
    @:optional var texCoord:Dynamic;
    /**
   * A scalar multiplier controlling the amount of occlusion applied.
   */
    @:optional var strength:Float;

}
/**
 * The material appearance of a primitive.
 */
typedef TMaterial = {
>TGLTFChildOfRootProperty,
    /**
   * A set of parameter values that are used to define the metallic-roughness material model from Physically-Based Rendering (PBR) methodology. When not specified, all the default values of `pbrMetallicRoughness` apply.
   */
    @:optional var pbrMetallicRoughness:TMaterialPbrMetallicRoughness;
    /**
   * The normal map texture.
   */
    @:optional var normalTexture:TMaterialNormalTextureInfo;
    /**
   * The occlusion map texture.
   */
    @:optional var occlusionTexture:TMaterialOcclusionTextureInfo;
    /**
   * The emissive map texture.
   */
    @:optional var emissiveTexture:TTextureInfo;
    /**
   * The emissive color of the material.
   */
    @:optional var emissiveFactor:Array<Float>;
    /**
   * The alpha rendering mode of the material.
   */
    @:optional var alphaMode:TAlphaMode;
    /**
   * The alpha cutoff value of the material.
   */
    @:optional var alphaCutoff:Float;
    /**
   * Specifies whether the material is double sided.
   */
    @:optional var doubleSided:Bool;
}
/**
 * Geometry to be rendered with the given material.
 */
typedef TMeshPrimitive = {
>TGLTFProperty,
    /**
   * A dictionary object, where each key corresponds to mesh attribute semantic and each value is the index of the accessor containing attribute's data.
   */
    var attributes:Dynamic;
//  {
//    [k: string]: GlTfId;
//  };
    /**
   * The index of the accessor that contains the indices.
   */
    @:optional var indices:TGlTfId;
    /**
   * The index of the material to apply to this primitive when rendering.
   */
    @:optional var material:TGlTfId;
    /**
   * The type of primitives to render.
   */
    @:optional var mode:TMeshPrimitiveType;
    /**
   * An array of Morph Targets, each  Morph Target is a dictionary mapping attributes (only `POSITION`, `NORMAL`, and `TANGENT` supported) to their deviations in the Morph Target.
   */
    @:optional var targets:Array<Dynamic>;
//  {
//    [k: string]: GlTfId;
//  }[];

}
/**
 * A set of primitives to be rendered.  A node can contain one mesh.  A node's transform places the mesh in the scene.
 */
typedef TMesh = {
>TGLTFChildOfRootProperty,
    /**
   * An array of primitives, each defining geometry to be rendered with a material.
   */
    var primitives:Array<TMeshPrimitive>;
    /**
   * Array of weights to be applied to the Morph Targets.
   */
    @:optional var weights:Array<Float>;

}
/**
 * A node in the node hierarchy.  When the node contains `skin`, all `mesh.primitives` must contain `JOINTS_0` and `WEIGHTS_0` attributes.  A node can have either a `matrix` or any combination of `translation`/`rotation`/`scale` (TRS) properties. TRS properties are converted to matrices and postmultiplied in the `T * R * S` order to compose the transformation matrix; first the scale is applied to the vertices, then the rotation, and then the translation. If none are provided, the transform is the identity. When a node is targeted for animation (referenced by an animation.channel.target), only TRS properties may be present; `matrix` will not be present.
 */
typedef TNode = {
>TGLTFChildOfRootProperty,
    /**
   * The index of the camera referenced by this node.
   */
    @:optional var camera:TGlTfId;
    /**
   * The indices of this node's children.
   */
    @:optional var children:Array<TGlTfId>;
    /**
   * The index of the skin referenced by this node.
   */
    @:optional var skin:TGlTfId;
    /**
   * A floating-point 4x4 transformation matrix stored in column-major order.
   */
    @:optional var matrix:Array<Float>;
    /**
   * The index of the mesh in this node.
   */
    @:optional var mesh:TGlTfId;
    /**
   * The node's unit quaternion rotation in the order (x, y, z, w), where w is the scalar.
   */
    @:optional var rotation:Array<Float>;
    /**
   * The node's non-uniform scale, given as the scaling factors along the x, y, and z axes.
   */
    @:optional var scale:Array<Float>;
    /**
   * The node's translation along the x, y, and z axes.
   */
    @:optional var translation:Array<Float>;
    /**
   * The weights of the instantiated Morph Target. Number of elements must match number of Morph Targets of used mesh.
   */
    @:optional var weights:Array<Float>;

}
/**
 *  s-t wrapping mode.  All valid values correspond to WebGL enums.
 */
@:enum abstract TWrapMode(Int) {
    var UNSET = 0;
    var CLAMP_TO_EDGE = 33071;
    var MIRROR_REPEAT = 33648;
    var REPEAT = 10497;
}

/**
 *  Magnification filter.  Valid values correspond to WebGL enums: `9728` (NEAREST) and `9729` (LINEAR).
 */
@:enum abstract TMagFilter(Int) from Int to Int{
    var NEAREST = 9728;
    var LINEAR = 9729;
    var UNSET = 0;
}

/**
 *  Minification filter.  All valid values correspond to WebGL enums.
 */
@:enum abstract TMinFilter(Int) from Int to Int{
    var NEAREST = 9728;
    var LINEAR = 9729;
    var NEAREST_MIPMAP_NEAREST = 9984;
    var LINEAR_MIPMAP_NEAREST = 9985;
    var NEAREST_MIPMAP_LINEAR = 9986;
    var LINEAR_MIPMAP_LINEAR = 9987;
    var UNSET = 0;
}

/**
 * Texture sampler properties for filtering and wrapping modes.
 */
typedef TSampler = {
>TGLTFChildOfRootProperty,
    /**
   * Magnification filter.
   */
    @:optional var magFilter:TMagFilter;// 9728 | 9729 | number;
    /**
   * Minification filter.
   */
    @:optional var minFilter:TMinFilter;//9728 | 9729 | 9984 | 9985 | 9986 | 9987 | number;
    /**
   * s wrapping mode.
   */
    @:optional var wrapS:TWrapMode;// 33071 | 33648 | 10497 | number;
    /**
   * t wrapping mode.
   */
    @:optional var wrapT:TWrapMode;// 33071 | 33648 | 10497 | number;
}
/**
 * The root nodes of a scene.
 */
typedef TScene = {
>TGLTFChildOfRootProperty,
    /**
   * The indices of each root node.
   */
    @:optional var nodes:Array<TGlTfId>;

}
/**
 * Joints and matrices defining a skin.
 */
typedef TSkin = {
>TGLTFChildOfRootProperty,
    /**
   * The index of the accessor containing the floating-point 4x4 inverse-bind matrices.  The default is that each matrix is a 4x4 identity matrix, which implies that inverse-bind matrices were pre-applied.
   */
    @:optional var inverseBindMatrices:TGlTfId;
    /**
   * The index of the node used as a skeleton root.
   */
    @:optional var skeleton:TGlTfId;
    /**
   * Indices of skeleton nodes, used as joints in this skin.
   */
    var joints:Array<TGlTfId>;
}
/**
 * A texture and its sampler.
 */
typedef TTexture = {
>TGLTFChildOfRootProperty,
    /**
   * The index of the sampler used by this texture. When undefined, a sampler with repeat wrapping and auto filtering should be used.
   */
    @:optional var sampler:TGlTfId;
    /**
   * The index of the image used by this texture. When undefined, it is expected that an extension or other mechanism will supply an alternate texture source, otherwise behavior is undefined.
   */
    @:optional var source:TGlTfId;

}
/**
 * The root object for a glTF asset.
 */
typedef TGlTf = {
>TGLTFProperty,
    /**
   * Names of glTF extensions used somewhere in this asset.
   */
    @:optional var extensionsUsed:Array<String>;
    /**
   * Names of glTF extensions required to properly load this asset.
   */
    @:optional var extensionsRequired:Array<String>;
    /**
   * An array of accessors.
   */
    @:optional var accessors:Array<TAccessor>;
    /**
   * An array of keyframe animations.
   */
    @:optional var animations:Array<TAnimation>;
    /**
   * Metadata about the glTF asset.
   */
    @:optional var asset:TAsset;
    /**
   * An array of buffers.
   */
    @:optional var buffers:Array<TBuffer>;
    /**
   * An array of bufferViews.
   */
    @:optional var bufferViews:Array<TBufferView>;
    /**
   * An array of cameras.
   */
    @:optional var cameras:Array<TCamera>;
    /**
   * An array of images.
   */
    @:optional var images:Array<TImage>;
    /**
   * An array of materials.
   */
    @:optional var materials:Array<TMaterial>;
    /**
   * An array of meshes.
   */
    @:optional var meshes:Array<TMesh>;
    /**
   * An array of nodes.
   */
    @:optional var nodes:Array<TNode>;
    /**
   * An array of samplers.
   */
    @:optional var samplers:Array<TSampler>;
    /**
   * The index of the default scene.
   */
    @:optional var scene:TGlTfId;
    /**
   * An array of scenes.
   */
    @:optional var scenes:Array<TScene>;
    /**
   * An array of skins.
   */
    @:optional var skins:Array<TSkin>;
    /**
   * An array of textures.
   */
    @:optional var textures:Array<TTexture>;

}