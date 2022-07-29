#include "DEBUG.CGINC"
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"

#include "Commons.cginc"
#include "Inputs.cginc"


struct appdata
{
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    //float4 color : COLOR;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 uvs : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float4 tangent : TEXCOORD2;
    float4 worldPos : TEXCOORD3;
    //centroid float4 color : TEXCOORD4;
    #ifdef HAIR
	float4 screenPos : TEXCOORD4;
    #endif
    //nointerpolation float4 _0123 : TEXCOORD6;
    //nointerpolation float4 _891011 : TEXCOORD7;
    //nointerpolation float4 _4567 : TEXCOORD8;
    //nointerpolation float totalamplitude : TEXCOORD9;
    //nointerpolation float averageamplitude :TEXCOORD10;
    //nointerpolation uint highest :TEXCOORD11;

    UNITY_FOG_COORDS(5)
    UNITY_SHADOW_COORDS(6)

    UNITY_VERTEX_OUTPUT_STEREO
};

static v2f input;
static SurfaceData surf;

#include "brdf.cginc"
#include "Lights.cginc"
#include "AudioLink.cginc"
#include "SurfaceData.cginc"

v2f vert(appdata v)
{
    v2f o = (v2f)0;
    UNITY_BRANCH
    if (_DontRender) return o;
    
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    
    UNITY_TRANSFER_FOG(o, o.pos);
    
    if (o.pos.w < _ProjectionParams.y * 1.01 && o.pos.w > 0)
    {
        o.pos.z = o.pos.z * 0.0001 + o.pos.w * 0.999;
    }
    
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.uvs = float4(v.uv0, v.uv1);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    //o.color = v.color;
    #ifdef HAIR
	o.screenPos = ComputeGrabScreenPos(o.pos);
    #endif
    /*UNITY_BRANCH
    if (_AudioLink)
    {
        float a[12] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

        [unroll]
        for (int i = 0; i < 10; i++)
        {
            [unroll]
            for (int j = 0; j < 12; j++)
            {
                a[j] += AudioLinkGetAmplitudeAtNote(i, j);
            }
        }

        o._0123 = float4(a[0], a[1], a[2], a[3]);
        o._4567 = float4(a[4], a[5], a[6], a[7]);
        o._891011 = float4(a[8], a[9], a[10], a[11]);

        o.totalamplitude = 0;
        uint highest = 0;
        [unroll]
        for (int k = 0; k < 12; k++)
        {
            highest = a[k] > a[highest] ? k : highest;
            o.totalamplitude += a[k];
        }
        o.highest = highest;
        o.averageamplitude = o.totalamplitude / 12;
    }*/
    UNITY_TRANSFER_SHADOW(o, o.shadow.xy);
    return o;
}


float4 frag(v2f i, bool facing : SV_IsFrontFace
            #ifdef COVERAGE_OUT
            ,out uint coverage : SV_Coverage
            #endif
            #ifdef DEPTH_OUT
            ,out float depth : SV_Depth
            #endif
) : SV_TARGET
{
    input = i;


    float4 mainTexture = BgolusSample(sampler_MainTex);
    mainTexture.a = calculateAlpha(mainTexture.a);
    UNITY_BRANCH
    if (!facing)
    {
        input.normal *= -1;
        input.tangent *= -1;
    }
    bitangent = cross(input.tangent.xyz, input.normal) * (input.tangent.w * unity_WorldTransformParams.w);
    //float3x3 tangentToWorld = float3x3(input.tangent.xyz, bitangent, input.normal);


    Init();
    InitSurfaceData(mainTexture);
    #ifdef USING_LIGHT_MULTI_COMPILE
		LightSource MainLight = CalcMainLight();
		doSpecular(MainLight);
    #endif

    #ifdef UNITY_PASS_FORWARDBASE
    #ifdef VERTEXLIGHT_ON
			FourLightSources VertexLights = CalcVertexLight(ViewDir);;
			doVertexSpecular(VertexLights);
    #endif
		LightSource ProbeLight = CalcProbeLight();
		doSpecular(ProbeLight);
		computeIndirectSpecular();
    #endif


    UNITY_BRANCH
    if (_Mode == 3)
    {
        surf.albedo *= surf.alpha;
        surf.alpha = lerp(surf.alpha, 1, surf.metallic);
    }

    float4 finalColor;
    finalColor.a = surf.alpha;
    finalColor.xyz = surf.albedo;
    finalColor.xyz *= (1 - surf.metallic);

    float3 finalColorLightSum = 0;
    float3 finalColorAddSum = 0;


    #ifdef UNITY_PASS_FORWARDBASE
		finalColorLightSum += surf.indirectDiffuse * surf.occlusion;
		finalColorAddSum += ProbeLight.specular + surf.indirectSpecular + surf.emission;
    #endif

    #ifdef USING_LIGHT_MULTI_COMPILE
		finalColorLightSum += MainLight.finalLight;
		finalColorAddSum += MainLight.specular;
    #endif

    #ifdef VERTEXLIGHT_ON
		finalColorLightSum += VertexLights.x.finalLight + VertexLights.y.finalLight + VertexLights.z.finalLight + VertexLights.w.finalLight;
		finalColorAddSum += VertexLights.x.specular + VertexLights.y.specular + VertexLights.z.specular + VertexLights.w.specular;
    #endif

    finalColor.xyz *= finalColorLightSum;
    finalColor.xyz += finalColorAddSum;

    UNITY_BRANCH
    if (_Mode == 2)
    {
        float oneMinusReflectivity = OneMinusReflectivityFromMetallic(_Metallic);
        finalColor.rgb *= finalColor.a;
        finalColor.a = 1 - oneMinusReflectivity + finalColor.a * oneMinusReflectivity;
    }

    UNITY_APPLY_FOG(input.fogCoord, finalColor);

    if (_Mode == 0)
    {
        finalColor.a = 1;
    }

    #ifdef HAIR
	uint samplecount = GetRenderTargetSampleCount();

	finalColor.a = applyDithering(finalColor.a, i.screenPos, samplecount / _DitherGradient);

	// center out the steps
	finalColor.a = finalColor.a * samplecount + 0.5;

	// Shift and subtract to get the needed amount of positive bits
	coverage = (1u << (uint)(finalColor.a)) - 1u;

	// Output 1 as alpha, otherwise result would be a^2
	finalColor.a = 1;
    #endif
    return finalColor;
}
