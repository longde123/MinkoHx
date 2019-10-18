#ifndef _TEXTURELOD_FUNCTION_GLSL_
#define _TEXTURELOD_FUNCTION_GLSL_

#if __VERSION__ >= 110 || defined GL_OES_standard_derivatives

float texturelod_mipmapLevel(sampler2D tex, vec2 uv, vec2 texSize)
{
#if __VERSION__ >= 400
    return textureQueryLod(tex, uv).x;
#else
    vec2 dx = dFdx(uv * texSize.x);
    vec2 dy = dFdy(uv * texSize.y);

    float d = max(dot(dx, dx), dot(dy, dy));

    return max(0.5 * log2(d), 0.0);
#endif
}

#endif
vec2 texturelod_uv(vec2 uv, float lod){

    #if defined RADIANCE_MAP_MAX_LOD
//    float size=1024.0;
    float scale_uv=1.0;
    float offset_x=0.0;
    float offset_y=0.0;
    //for(float i=1.0;i<11.0; i++){
    for(float i=1.0;i<float(RADIANCE_MAP_MAX_LOD); i++){

        if(i<lod){
            scale_uv*=0.5;
            offset_y+=scale_uv;
            offset_x=0.5;
        }
    }
    //        scale_uv=0.5;
    //        offset_y=0.5;
    //
    //    scale_uv=0.25;
    //    offset_y=0.75;
    //
    //        scale_uv=0.125;
    //        offset_y=0.875;
       uv*=scale_uv;

    //
//    if(uv.x<  0.5/size ){
//        uv.x= 0.5/size;
//    }
//    if(uv.x>(1.0- 0.5*scale_uv)){
//        uv.x=(1.0- 0.5*scale_uv);
//    }
//    if(uv.y<   0.5/size ){
//        uv.y = 0.5/size;
//    }

    uv.y*=0.5;
//    if(uv.y>(1.0-  0.25*scale_uv)){
//        uv.y = (1.0- 0.25*scale_uv);
//    }
    uv.x=offset_x+uv.x ;
    uv.y=offset_y+uv.y ;
    #endif
    return uv;
}
vec4 texturelod_texture(sampler2D tex, vec2 uv, float lod)
{
#if __VERSION__ < 130
    #if defined GL_OES_standard_derivatives && (defined GL_ES && defined GL_EXT_shader_texture_lod) || (!defined GL_ES && defined GL_ARB_shader_texture_lod)
        #if defined GL_ES
            return texture2DLodEXT(tex, uv, lod);
        #else
            return texture2DLod(tex, uv, lod);
        #endif
    #else
        #if defined RADIANCE_MAP_MAX_LOD
            float mixmip 		= floor(lod);
            vec2 uv1=texturelod_uv(uv,mixmip);
            vec2 uv2=texturelod_uv(uv,mixmip+1.0);
            vec4 radiance1		= texture2D( tex, uv1);
            vec4 radiance2		= texture2D( tex, uv2);
            return mix(radiance1, radiance2,  fract(lod) );
        #else
            uv.y*=0.5;
            return texture2D(tex, uv, lod);
        #endif
       // return vec4(0.0);
    #endif
#else
    return textureLod(tex, uv, lod);
#endif
}

vec4 texturelod_texture2D(sampler2D tex, vec2 uv, vec2 texSize, float baseLod, float maxLod, vec4 defaultColor)
{
    if (maxLod == baseLod)
        return texture2D(tex, uv);

#if __VERSION__ < 130
    #if defined GL_OES_standard_derivatives && (defined GL_ES && defined GL_EXT_shader_texture_lod) || (!defined GL_ES && defined GL_ARB_shader_texture_lod)
        float requiredLod = texturelod_mipmapLevel(tex, uv, texSize);

        float maxTextureLod = floor(log2(texSize.x));

        if (maxLod >= maxTextureLod)
            return defaultColor;

        #if defined GL_ES
            return texture2DLodEXT(tex, fract(uv), max(maxLod, requiredLod));
        #else
            return texture2DLod(tex, fract(uv), max(maxLod, requiredLod));
        #endif
    #else
        return defaultColor;
    #endif
#else
    float requiredLod = texturelod_mipmapLevel(tex, uv, texSize);

    float maxTextureLod = floor(log2(texSize.x));

    if (maxLod >= maxTextureLod)
        return defaultColor;

    return textureLod(tex, uv, max(maxLod, requiredLod));
#endif
}

#endif
