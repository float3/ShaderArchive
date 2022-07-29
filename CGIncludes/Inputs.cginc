#define CUSTOM_DECLARE_TEXTURE2D(tex) Texture2D_float tex##; SamplerState sampler##tex; float4 tex##_TexelSize; float4 tex##_ST; uint tex##_UV;

CUSTOM_DECLARE_TEXTURE2D(_MainTex)
//CUSTOM_DECLARE_TEXTURE2D(_SecondaryTex)

bool _Skin;
bool _SSS;
float _Cloth;
bool _Refraction;

bool _NotInMirror;
bool _NotOutMirror;
bool _DontRender;
bool _SpecularHighlights;
bool _GlossyReflections;
bool _Aniso;
bool _Emission;
bool _AudioLink;


float _Mode;
float _Anisotropy;
float _Reflectance;
float _UVSec;
float _FresnelIntensity;
float _SpecularOcclusion;

float4 _Color;
float _Cutoff;
float _MipScale;
float _MipBias;
bool _AlphaToMask;

Texture2D_float _DFG;
SamplerState sampler_DFG;

float _Generalised;
float _Wrap;

CUSTOM_DECLARE_TEXTURE2D(_BumpMap)
float _BumpScale;


CUSTOM_DECLARE_TEXTURE2D(_MetallicGlossMap)
float _Metallic;
float _Glossiness;
CUSTOM_DECLARE_TEXTURE2D(_OcclusionMap)
float _Occlusion;


CUSTOM_DECLARE_TEXTURE2D(_EmissionMap)
float4 _EmissionColor;

bool _isLocal;
bool _isFriend;
bool _hasLoaded;

// float4 _FrecklesLocation;
// bool _FreckleMask;
// float _FrecklesScale;
// float _FrecklesSize;
// float _FrecklesRandomness;
// float _FrecklesAmount;
// float _FrecklesRoundness;

float _DitherGradient;

struct SurfaceData
{
	float3 albedo;
	float3 tangentNormal;
	float3 emission;
	float metallic;
	float perceptualRoughness;
	float occlusion;
	float reflectance;
	float alpha;
	float oneMinusReflectivity;

	float3 diffuseColor;
	float perceptualRoughnessUnclamped;
	float3 f0;
	float roughness;
	float3 dfg;
	float3 energyCompensation;

	float clearCoat;
	float clearCoatPerceptualRoughness;
	float clearCoatRoughness;

	float3 sheenColor;
	float sheenRoughness;
	float sheenPerceptualRoughness;
	float sheenScaling;
	float sheenDFG;

	float3 anisotropicDirection;
	float anisotropy;
	float3 anisotropicT;
	float3 anisotropicB;

	float thickness;
	float3 subsurfaceColor;
	float subsurfacePower;
	float Curvature;
	float etaRI;
	float etaIR;
	float transmission;
	float uThickness;
	float3 absorption;
	float3 fresnel;
	float3 indirectDiffuse;
	float3 indirectSpecular;
	float3 directSpecular;
	float clampedRoughness;
};

struct LightSource
{
	float3 Direction;
	float3 LightColor;
	float3 HalfVector;
	float NoL;
	float LoH;
	float NoH;
	float Attenuation;
	float Intensity;
	float3 colorXatten;
	float3 finalLight;
	float3 irradiance;
	float3 specular;
	float3 diffuse;
};

struct FourLightSources
{
	LightSource x;
	LightSource y;
	LightSource z;
	LightSource w;
};

static float NoV;
static float3 ViewDir;
static float3 bitangent;
static bool isSkin;

// #if defined(HAIR_CUTOUT)
// int mode = 1;
// float cutoff = _Cutoff;
// bool alphatomask = true;
// float2 uv = input.uvs.xy;
// Texture2D_float mainTex = _MainTex;
// #elif defined(HAIR_TRANS)
// int mode = 3;
// float cutoff = _Cutoff;
// bool alphatomask = false;
// Texture2D_float mainTex = _SecondaryTex;
// float2 uv = input.uvs.zw;
// #else
// int mode = _Mode;
// float cutoff = _Cutoff;
// bool alphatomask = _AlphaToMask;
// Texture2D_float mainTex = _MainTex;
// float2 uv = input.uvs.xy;
// #endif
#ifdef HAIR
	#define COVERAGE_OUT
#endif