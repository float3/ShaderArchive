#include "DEBUG.CGINC"
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"

#include "Commons.cginc"
#include "Inputs.cginc"

#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityStandardUtils.cginc"


sampler3D _DitherMaskLOD;
bool _Shadow;

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float4 color : COLOR;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float4 uvs : TEXCOORD0;
	float3 debug : TEXCOORD1;
	UNITY_VERTEX_OUTPUT_STEREO
};

v2f input;
static SurfaceData surf;

#include "AudioLink.cginc"

#ifndef HAS_DEPTH_TEXTURE
#define HAS_DEPTH_TEXTURE
sampler2D_float _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;
#endif

v2f vert(appdata v)
{
	UNITY_BRANCH
	if (_DontRender || (!IsInMirror() && _NotInMirror) || (IsInMirror() && _NotOutMirror) || !_Shadow)
	{
		return (v2f)0;
	}
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(os);
	o.uvs = float4(v.uv0, v.uv1);

	//convert to world space for calculation
	float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
	float3 probeLightDir = normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz);
	bool hasDirectionalLight = any(_WorldSpaceLightPos0.xyz);
	float3 lightDirWorld = -normalize(UnityWorldSpaceLightDir(worldPos.xyz));
	if (!hasDirectionalLight)
	{
		lightDirWorld = probeLightDir;
	}
	float3 lightDirObj = UnityWorldToObjectDir(lightDirWorld);
	if (AudioLinkIsAvailable())
	{
		float3 vp = v.vertex.xyz;


		float phi = atan2(vp.x + 0.001, vp.z) / 3.14159;

		// We want to mirror the -1..1 so that it's actually 0..1 but
		// mirrored.
		float placeinautocorrelator = abs(phi);

		// Note: We don't need lerp multiline because the autocorrelator
		// is only a single line.
		float autocorrvalue = AudioLinkLerp(ALPASS_AUTOCORRELATOR +
			float2(placeinautocorrelator * AUDIOLINK_WIDTH, 0.)).x;

		// Squish in the sides, and make it so it only perterbs
		// the surface.
		autocorrvalue = autocorrvalue * (.5 - abs(vp.y)) * 0.4 + .6;

		// Perform same operation to find max.  The 0th bin on the 
		// autocorrelator will almost always be the max
		//o.corrmax = AudioLinkLerp( ALPASS_AUTOCORRELATOR ) * 0.2 + .6; 

		// Modify the original vertices by this amount.
		vp = lerp(autocorrvalue * vp, vp, 0.8);


		v.vertex.xyz = vp;
	}


	//project the world space vertex to the y=0 ground
	v.vertex.x -= v.vertex.y / lightDirObj.y * lightDirObj.x;
	v.vertex.z -= v.vertex.y / lightDirObj.y * lightDirObj.z;

	v.vertex.y = 0; //force the vertex's world space Y = 0 (on the ground)

	//float4 result = mul (UNITY_MATRIX_VP, positionInWorldSpace); //complete to MVP matrix transform (we already change from local->world before, so this line only do VP)

	if ((floor(v.uv0.x) == 2 && v.uv0.y < 1)) //EYE
	{
		v.vertex.y += 0.003;
	}
	else
	{
		v.vertex.y += 0.002;
	}



	v.vertex.z += 0.001; //add a small offset to avoid z-fighting
	v.vertex = UnityObjectToClipPos(v.vertex);
	o.pos = v.vertex;

	return o;
}

float4 frag(v2f i) : SV_Target
{
	float4 col = float4(0, 0, 0, 1);
	if (i.uvs.x > 1 && i.uvs.x < 2 && _Shadow)
	{
		input = i;

		SamplerState s = Trilinear_Repeat_Aniso16_sampler;
		float2 dx;
		float2 dy;

		float2 uvOffsets = float2(0.125, 0.375);
		float4 offsetUV = float4(0.0, 0.0, 0, _MipBias);;
		dx = ddx(input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw);
		dy = ddy(input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw);


		float2 dx2 = ddx(input.uvs.xy * _MainTex_TexelSize.zw);
		float2 dy2 = ddy(input.uvs.xy * _MainTex_TexelSize.zw);
		float delta_max_sqr = max(dot(dx2, dx2), dot(dy2, dy2));

		float mips = max(0.0, 0.5 * log2(delta_max_sqr)) * _MipScale;

		dx *= saturate(0.5 * log2(dot(dx * _MainTex_TexelSize.zw, dx * _MainTex_TexelSize.zw)));
		dy *= saturate(0.5 * log2(dot(dy * _MainTex_TexelSize.zw, dy * _MainTex_TexelSize.zw)));


		offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) + uvOffsets.x * dx + uvOffsets.y * dy;
		float4 mainTexture = _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
		offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) - uvOffsets.x * dx - uvOffsets.y * dy;
		mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
		offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) + uvOffsets.y * dx - uvOffsets.x * dy;
		mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
		offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) - uvOffsets.y * dx + uvOffsets.x * dy;
		mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
		mainTexture *= 0.25;


		mainTexture.a *= 1 + mips;
		mainTexture.a = saturate(mainTexture.a);
		mainTexture *= _Color;
		UNITY_BRANCH
		if (_AlphaToMask)
		{
			mainTexture.a = (mainTexture.a - _Cutoff) / max(fwidth(mainTexture.a), 0.0001) + 0.5;
		}
		else if (_Mode == 1)
		{
			clip(mainTexture.a - _Cutoff);
		}
		col = mainTexture * 1.5;
	}
	return col;
}
