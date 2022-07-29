Texture2D_float<float4> _BufferTex;
sampler2D _MainTex;
float4 _MainTex_ST;
float _Start;

#define X_MOD 0.9   
#define Y_MOD 0.9

#define TEXSIZE 1024
#define PIXELWIDTH 1

uint2 Dimensions()
{
    uint height, width;
    _BufferTex.GetDimensions(width, height);
    return uint2(width, height);
}

float2 uvToScreen(float2 uv)
{
    uv *= 2;
    uv -= 1;
    uv *= float2(X_MOD,-Y_MOD);
    return uv;
}

float2 screenToUV(float2 screen)
{
    screen -= 0.5;
    screen *= float2(X_MOD,Y_MOD);
    screen += 0.5;
    return screen;
}

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 oPos : TEXCOORD1;
    float3 deltaPos : TEXCOORD2;
    uint id : TEXCOORD3;
};


