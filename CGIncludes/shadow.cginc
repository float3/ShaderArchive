#include "DEBUG.CGINC"
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"

#include "Commons.cginc"
#include "Inputs.cginc"


sampler3D _DitherMaskLOD;

struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 uvs : TEXCOORD0;
    float4 screenPos : TEXCOORD1;

    UNITY_VERTEX_OUTPUT_STEREO
};

v2f input;
static SurfaceData surf;
float4 debug;

#include "AudioLink.cginc"

v2f vert(appdata v)
{
    UNITY_BRANCH
    if (_DontRender || (!IsInMirror() && _NotInMirror) || (IsInMirror() && _NotOutMirror))
    {
        return (v2f)0;
    }
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(os);
    o.uvs = float4(v.uv0, v.uv1);
    o.pos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
    o.pos = UnityApplyLinearShadowBias(o.pos);
    if (o.pos.w < _ProjectionParams.y * 1.01 && o.pos.w > 0)
    {
        o.pos.z = o.pos.z * 0.0001 + o.pos.w * 0.999;
    }
    o.screenPos = ComputeScreenPos(o.pos);
    return o;
}

float3 PreMultiplyAlpha3(float3 diffColor, float alpha, float oneMinusReflectivity, out float outModifiedAlpha)
{
    if (_Mode == 2)
    {
        diffColor *= alpha;
        outModifiedAlpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
    }
    else
    {
        outModifiedAlpha = alpha;
    }
    return diffColor;
}

float4 BgolusSample(SamplerState s)
{
    float2 dx = ddx(input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw);
    float2 dy = ddy(input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw);

    dx *= saturate(0.5 * log2(dot(dx * _MainTex_TexelSize.zw, dx * _MainTex_TexelSize.zw)));
    dy *= saturate(0.5 * log2(dot(dy * _MainTex_TexelSize.zw, dy * _MainTex_TexelSize.zw)));

    float2 uvOffsets = float2(0.125, 0.375);
    float4 offsetUV = float4(0.0, 0.0, 0, _MipBias);;

    offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) + uvOffsets.x * dx + uvOffsets.y * dy;
    float4 mainTexture = _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
    offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) - uvOffsets.x * dx - uvOffsets.y * dy;
    mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
    offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) + uvOffsets.y * dx - uvOffsets.x * dy;
    mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
    offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) - uvOffsets.y * dx + uvOffsets.x * dy;
    mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
    mainTexture *= 0.25;

    float delta_max_sqr = max(dot(dx, dx), dot(dy, dy));
    float mips = max(0.0, 0.5 * log2(delta_max_sqr)) * _MipScale;

    mainTexture.a *= 1 + mips;
    mainTexture.a = saturate(mainTexture.a);
    mainTexture *= _Color;
    return mainTexture;
}

float calculateAlpha(float alpha)
{
    if (_AlphaToMask)
    {
        alpha = (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5;
    }
    else if (_Mode == 1)
    {
        clip(alpha - _Cutoff);
    }
    return alpha;
};

float4 frag(v2f i
#ifdef COVERAGE_OUT
    ,out uint coverage : SV_Coverage
#endif
#ifdef DEPTH_OUT
    ,out float depth : SV_Depth
#endif
) : SV_Target
{
    if (_Mode != 0)
    {
        input = i;

        float4 mainTexture = BgolusSample(sampler_MainTex);

        float alpha = mainTexture.a;

        if (_Mode == 1)
        {
            clip(alpha - _Cutoff);
        }
        else
        {
            if (_Mode == 3)
            {
                alpha = lerp(saturate(alpha), 1, _Metallic);
            }

            float alphaRef = tex3D(_DitherMaskLOD, float3(i.pos.xy * 0.25, alpha * 0.9375)).a;
            clip(alphaRef - 0.01);
        }

        #ifdef HAIR
        uint samplecount = GetRenderTargetSampleCount();

        alpha = applyDithering(alpha, i.screenPos, samplecount / _DitherGradient);

        // center out the steps
        alpha = alpha * samplecount + 0.5;

        // Shift and subtract to get the needed amount of positive bits
        coverage = (1u << (uint)(alpha)) - 1u;

        // Output 1 as alpha, otherwise result would be a^2
        alpha = 1;
        #endif
    }


    #if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
		return UnityEncodeCubeShadowDepth ((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
    #else
    return 0;
    #endif
}
