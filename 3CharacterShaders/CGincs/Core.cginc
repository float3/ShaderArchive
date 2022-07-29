#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"


#ifdef HAIR
    #define SCREENPOS_IN
#endif

struct appdata
{
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 VertexColor : COLOR;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 uvs : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float4 tangent : TEXCOORD2;
    float4 worldPos : TEXCOORD3;
    centroid float4 color : TEXCOORD4;
    #ifdef SCREENPOS_IN
    float4 screenPos : TEXCOORD4;
    #endif

    #if !defined(UNITY_PASS_SHADOWCASTER)
    UNITY_FOG_COORDS(5)
    UNITY_LIGHTING_COORDS(6, 7)
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

v2f vert(appdata v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.uvs = float4(v.uv0, v.uv1);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

    #ifdef SCREENPOS_IN
    o.screenPos = ComputeGrabScreenPos(o.pos);
    #endif

    #ifdef UNITY_PASS_SHADOWCASTER
    o.pos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
    o.pos = UnityApplyLinearShadowBias(o.pos);
    TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #else
    UNITY_TRANSFER_FOG(o, o.pos);
    UNITY_TRANSFER_LIGHTING(o, v.uv1);
    #endif

    return o;
}

#define DOUBLESIDED

#include "Uniforms.cginc"
#include "filament_brdf.cginc"
#include "Structs.cginc"

#include "Mesh.cginc"
#include "Camera.cginc"
#include "Surface.cginc"
#include "Light.cginc"


void frag(in v2f i, out float4 color : SV_Target
          #ifdef DOUBLESIDED
          , in bool facing : SV_IsFrontFace
          #endif
          #ifdef COVERAGE_OUT
          , out float coverage : SV_DEPTH
          #endif
          #ifdef DEPTH_OUT
          , out float depth : SV_Depth
          #endif
)
{
    i.normal = normalize(i.normal);

    #ifndef DOUBLESIDED
        bool facing = true;
    #endif

    Mesh meshdata = CalculateMeshData(i.normal, i.tangent, facing);
    Camera cameraData = GetCamera(i.worldPos, meshdata.normal);
    Surface surfaceData = GetSurface(i);
    Light mainLight = CalcMainLight(surfaceData, i, cameraData, meshdata);

    color.rgb = surfaceData.albedo;
    color.a = surfaceData.alpha;

    float3 finalColorLightSum = 0;
    float3 finalColorAddSum = 0;

    #ifdef USING_LIGHT_MULTI_COMPILE
    finalColorLightSum += mainLight.finalLight;
    finalColorAddSum += mainLight.specular;
    #endif

    color.xyz *= finalColorLightSum;
    color.xyz += finalColorAddSum;

    UNITY_APPLY_FOG(i.fogCoord, color);
}
