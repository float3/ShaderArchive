float4 _Mouse;
float _GammaCorrect;
float _Resolution;

// GLSL Compatability macros
#define iResolution float3(_Resolution, _Resolution, _Resolution)


float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}


float3 palette(float x)
{
    return pal(x, float3(0.8, 0.5, 0.4), float3(0.2, 0.4, 0.2), float3(2., 1., 1.), float3(0., 0.25, 0.25));
}


float4 permute(float4 x)
{
    return glsl_mod((x*34.+1.)*x, 289.);
}

float2 fade(float2 t)
{
    return t * t * t * (t * (t * 6. - 15.) + 10.);
}

float cnoise(float2 P)
{
    float4 Pi = floor(P.xyxy) + float4(0., 0., 1., 1.);
    float4 Pf = frac(P.xyxy) - float4(0., 0., 1., 1.);
    Pi = glsl_mod(Pi, 289.);
    float4 ix = Pi.xzxz;
    float4 iy = Pi.yyww;
    float4 fx = Pf.xzxz;
    float4 fy = Pf.yyww;
    float4 i = permute(permute(ix) + iy);
    float4 gx = 2. * frac(i * 0.024390243) - 1.;
    float4 gy = abs(gx) - 0.5;
    float4 tx = floor(gx + 0.5);
    gx = gx - tx;
    float2 g00 = float2(gx.x, gy.x);
    float2 g10 = float2(gx.y, gy.y);
    float2 g01 = float2(gx.z, gy.z);
    float2 g11 = float2(gx.w, gy.w);
    float4 norm = 1.7928429 - 0.85373473 * float4(dot(g00, g00), dot(g01, g01), dot(g10, g10),
                                                  dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, float2(fx.x, fy.x));
    float n10 = dot(g10, float2(fx.y, fy.y));
    float n01 = dot(g01, float2(fx.z, fy.z));
    float n11 = dot(g11, float2(fx.w, fy.w));
    float2 fade_xy = fade(Pf.xy);
    float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
    float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

float2 cnoise2(float2 p)
{
    return float2(cnoise(p), cnoise(p.yx));
}

float eye(float2 uv, float time)
{
    const float pinch = 0.15;
    const float radius = 0.25;
    const float eyeballRadius = 0.44;
    const float pupilRadius = 0.48;
    const float blinkingSpeed = 2.5;
    const float eyeballRange = 0.08;
    float outsideThickness = 10. / iResolution.x;
    float closed = clamp(cnoise(float2(time * 0.25, 0.)) * 10., 0., 1.);
    closed = 1. - (1. - closed) * clamp(
        1. - smoothstep(0., 1.5, 18. * (sin(time * blinkingSpeed) * 0.5 + 0.5) - 17.), 0., 1.);
    float scale = lerp(1., 50., closed);
    float2 direction = clamp(cnoise2(float2(time * 0.4, 0.)) * 100., -1., 1.);
    direction *= clamp(1. - smoothstep(0., 0.1, 3. * (sin(time + 0.723) * 0.5 + 0.5) - 2.), 0., 1.);
    float ballL = 0.5 - length(uv - direction * eyeballRange);
    float eyeball = smoothstep(eyeballRadius, eyeballRadius + outsideThickness * 0.3, ballL);
    eyeball -= smoothstep(eyeballRadius + outsideThickness * 0.7, eyeballRadius + outsideThickness, ballL);
    eyeball += smoothstep(pupilRadius, pupilRadius + outsideThickness * 0.3, ballL);
    float full = eyeball;
    uv.y *= scale;
    outsideThickness *= scale;
    uv.y -= (step(uv.y, 0.) * 2. - 1.) * pinch;
    float fullL = 0.5 - length(uv);
    full *= smoothstep(radius + outsideThickness * 0.3, radius + outsideThickness * 0.3, fullL);
    full += smoothstep(radius, radius + outsideThickness * 0.3, fullL);
    full -= smoothstep(radius + outsideThickness * 0.7, radius + outsideThickness, fullL);
    return clamp(full, 0., 1.) * smoothstep(0.9, 0.91, 1. - closed);
}

float4 eyes(float2 Inuv)
{
    float4 fragColor = 0;
    float2 fragCoord = Inuv * _Resolution;
    float2 uv = fragCoord / iResolution.xy;
    uv.y = (uv.y - 0.5) / iResolution.x * iResolution.y + 0.5;
    uv += _Time.y * 0.02 * float2(-1., 0.5);
    uv *= 12.;
    uv -= _Mouse.xy * 0.01;
    float tile1 = cnoise(floor(uv) + 0.5) * 97.2;
    float tile2 = 0.726 + cnoise(floor(uv + 0.5) + 0.5) * 76.01;
    float3 eyes = eye((frac(uv) - 0.5) * 0.45, _Time.y * 0.5 + tile1) * palette(
        tile1 + _Time.y * 0.1 + _Mouse.x * 0.006);
    eyes += eye((frac(uv + 0.5) - 0.5) * 0.45, _Time.y * 0.5 + tile2) * palette(
        tile2 + _Time.y * 0.1 + _Mouse.y * 0.006);
    fragColor = float4(eyes, 1.);
    if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
    return fragColor;
}
