#ifndef _MATH_FUNCTION_GLSL_
#define _MATH_FUNCTION_GLSL_

#define PI      3.141592653
#define TwoPI (2.0 * PI)
#define INV_PI  0.318309886
#define INV_TWO_PI 	0.15915494309
#define EPSILON 1e-3

float square(float x)
{
    return x * x;
}

int square(int x)
{
    return x * x;
}

vec2 square(vec2 x)
{
    return x * x;
}

vec3 square(vec3 x)
{
    return x * x;
}

vec4 square(vec4 x)
{
    return x * x;
}

float saturate(float x)
{
    return clamp(x, 0.0, 1.0);
}

vec2 saturate(vec2 x)
{
    return clamp(x, 0.0, 1.0);
}

vec3 saturate(vec3 x)
{
    return clamp(x, 0.0, 1.0);
}

vec4 saturate(vec4 x)
{
    return clamp(x, 0.0, 1.0);
}

vec2 mx_latlong_projection(vec3 dir)
{
    float latitude = -asin(dir.y) * INV_PI + 0.5;
    latitude = clamp(latitude, 0.0000000000001, 0.999999999999);
    float longitude = atan(dir.x, -dir.z) * INV_PI * 0.5 + 0.5;
    return vec2(longitude, latitude);
}

vec2 normalToLatLongUV(vec3 p){

    float theta = acos(p.y);
    float phi = atan(p.z, p.x);
    if (phi < 0.0) {
        phi += 2.0 * PI;
    }
    vec2 s;
    s.x = 1.0 - phi * INV_TWO_PI;
    s.y = theta * INV_PI;
    return s;
}
vec2 normalToSphericalUV(const vec3 n)
{
    // acos is defined [ -1: 1 ]
    // atan( x , y ) require to have |y| > 0

    // when n.y is amlost 1.0 it means that the normal is aligned on axis y
    // so instead of fixing numerical issue we can directly return the supposed
    // uv value
    if (n.y > (1.0 - EPSILON))
        return vec2(0.5, 0.0);
    else if (n.y < -(1.0 - EPSILON))
        return vec2(0.5, 1.0 - EPSILON);

    float yaw = acos(n.y) * INV_PI;
    float pitch;
    float y = n.z;

    if (abs(y) < EPSILON)
        y = EPSILON;

    pitch = (atan(n.x, y) + PI) * 0.5  * INV_PI;

    return vec2(pitch, yaw);
}

#endif // _MATH_FUNCTION_GLSL_
