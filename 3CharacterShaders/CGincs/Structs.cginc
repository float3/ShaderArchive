#ifndef CHARACTERSHADERS_STRUCTS_INCLUDED
#define CHARACTERSHADERS_STRUCTS_INCLUDED

// struct Light
// {
//     float4 colorIntensity; // rgb, pre-exposed intensity
//     float3 l;
//     float attenuation;
//     float NoL;
//     float3 worldPosition;
// };

struct Light
{
    float3 direction;
    float3 color;
    float3 halfVector;
    float NoL;
    float LoH;
    float NoH;
    float attenuation;
    float intensity;
    float3 colorXatten;
    float3 finalLight;
    float3 irradiance;
    float3 specular;
    float3 diffuse;
};


struct PixelParams
{
    float3 diffuseColor;
    float perceptualRoughness;
    float perceptualRoughnessUnclamped;
    float3 f0;
    float roughness;
    float3 dfg;
    float3 energyCompensation;

    #if defined(MATERIAL_HAS_CLEAR_COAT)
    float clearCoat;
    float clearCoatPerceptualRoughness;
    float clearCoatRoughness;
    #endif

    #if defined(MATERIAL_HAS_SHEEN_COLOR)
    float3  sheenColor;
    #if !defined(SHADING_MODEL_CLOTH)
    float sheenRoughness;
    float sheenPerceptualRoughness;
    float sheenScaling;
    float sheenDFG;
    #endif
    #endif

    #if defined(MATERIAL_HAS_ANISOTROPY)
    float3  anisotropicT;
    float3  anisotropicB;
    float anisotropy;
    #endif

    #if defined(SHADING_MODEL_SUBSURFACE) || defined(MATERIAL_HAS_REFRACTION)
    float thickness;
    #endif
    #if defined(SHADING_MODEL_SUBSURFACE)
    float3  subsurfaceColor;
    float subsurfacePower;
    #endif

    #if defined(SHADING_MODEL_CLOTH) && defined(MATERIAL_HAS_SUBSURFACE_COLOR)
    float3  subsurfaceColor;
    #endif

    #if defined(MATERIAL_HAS_REFRACTION)
    float etaRI;
    float etaIR;
    float transmission;
    float uThickness;
    float3  absorption;
    #endif
};
#endif
