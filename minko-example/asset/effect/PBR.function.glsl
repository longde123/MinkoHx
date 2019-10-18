#ifndef _PBR_FUNCTION_GLSL_
#define _PBR_FUNCTION_GLSL_

#pragma include "BRDF.function.glsl"
#pragma include "TextureLod.function.glsl"

vec3 pbr_diffuse(vec3 diffuseColor, float roughness, float NoV, float NoL, float VoH)
{
    return brdf_diffuse(diffuseColor, roughness, NoV, NoL, VoH) * NoL;
}

vec3 pbr_specular(vec3 specularColor, float roughness, float NoL, float NoV, float NoH, float VoH)
{
    // f = D * F * G / (4 * (N.L) * (N.V));
    return brdf_distribution(roughness, NoH)
    * brdf_fresnel(specularColor, VoH)
    * brdf_geometricVisibility(roughness, NoV, NoL, VoH)//;
    * NoL;
    //  * (4.0 * NoL * NoV);
}

vec3 pbr_envDiffuse(sampler2D irradianceMap, vec3 normal, vec2 uvOffset)
{
    return texture2D(irradianceMap, normalToLatLongUV(normal) + uvOffset).rgb;
}

vec3 pbr_envDiffuse(sampler2D irradianceMap, vec3 normal)
{
    return pbr_envDiffuse(irradianceMap, normal, vec2(0.0));
}

vec3 pbr_fresnelSchlickWithRoughness(vec3 specularColor, vec3 e, vec3 n, float gloss)
{
    return specularColor + (max(vec3(gloss), specularColor) - specularColor) * pow(1.0 - saturate(dot(e, n)), 5.0);
}


vec3 pbr_envSpecular(vec3       specularColor,
sampler2D  radianceMap,
int        numMipmaps,
float      roughness,
vec3       worldSpaceReflectionVector,
float      NoV,
vec3       normal,
vec3       view,
vec2       uvOffset
)
{
    float mipMapIndex = clamp(roughness * float(numMipmaps), 0.0, float(numMipmaps));
    vec3 prefilteredColor = texturelod_texture(
    radianceMap,
    normalToLatLongUV(worldSpaceReflectionVector) + uvOffset,
    mipMapIndex
    ).rgb;
    return pbr_fresnelSchlickWithRoughness(specularColor, normal, view, 1.0 - roughness) * prefilteredColor;
    // vec2 envBRDF = texture2D(integratedBRDF, vec2(roughness, NoV)).xy;

    //  return pbr_fresnelSchlickWithRoughness(specularColor, normal, view, 1.0 - roughness) * prefilteredColor * (specularColor * envBRDF.x + envBRDF.y);
}
vec3 EnvBRDFApprox(vec3 SpecularColor, float Roughness, float NoV)
{
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
    const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
    vec4 r = Roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    vec2 AB = vec2(-1.04, 1.04) * a004 + r.zw;
    AB.y *= saturate(50.0 * SpecularColor.y);
    return SpecularColor * AB.x + AB.y;
}
vec3 pbr_envSpecular(vec3       specularColor,
sampler2D  radianceMap,
int        numMipmaps,
float      roughness,
vec3       worldSpaceReflectionVector,
float      NoV,
vec3       normal,
vec3       view)
{
    float mipMapIndex = roughness * float(numMipmaps);
    vec3 prefilteredColor = texturelod_texture(
    radianceMap,
    normalToLatLongUV(worldSpaceReflectionVector),
    mipMapIndex
    ).rgb;
    return pbr_fresnelSchlickWithRoughness(specularColor, normal, view, 1.0 - roughness) * prefilteredColor;
    //* EnvBRDFApprox(specularColor ,roughness, NoV);
}
float pbr_shininessToRoughness(float shininessCoeff)
{
    // http://computergraphics.stackexchange.com/a/1517

    return saturate(sqrt(2.0 / (2.0 + shininessCoeff)));
}

    #endif// _PBR_FUNCTION_GLSL_
