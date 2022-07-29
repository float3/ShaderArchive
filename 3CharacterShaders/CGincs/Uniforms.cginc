#define CUSTOM_DECLARE_TEXTURE2D(tex) Texture2D_float tex##; SamplerState sampler##tex; float4 tex##_TexelSize; float4 tex##_ST; uint tex##_UV;


float _Color;
CUSTOM_DECLARE_TEXTURE2D(_MainTex);

float _Metallic;
float _Glossiness;
float _Occlusion;
float _Reflectance;
CUSTOM_DECLARE_TEXTURE2D(_MetallicGlossMap)

Texture2D_float _DFG;
SamplerState sampler_DFG;