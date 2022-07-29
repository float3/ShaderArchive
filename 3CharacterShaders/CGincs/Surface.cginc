#ifndef CHARACTERSHADERS_SURFACE_INCLUDED
#define CHARACTERSHADERS_SURFACE_INCLUDED

struct Surface
{
    float3 albedo;
    float alpha;

    float metallic;
    float roughness;
    float reflectance;
    float f0;
    float perceptualRoughness;
    float occlusion;
};

Surface GetSurface(v2f input)
{
    Surface surfaceData;


    float4 mainTex = UNITY_SAMPLE_TEX2D(_MainTex, input.uvs.xy);

    float4 metallicGlossMap = UNITY_SAMPLE_TEX2D(_MetallicGlossMap, input.uvs.xy);

    surfaceData.albedo = mainTex.rgb;
    surfaceData.alpha = mainTex.a;

    surfaceData.metallic = metallicGlossMap.r * (_Metallic * _Metallic);
    surfaceData.roughness = 1 - (_Glossiness * metallicGlossMap.a);
    surfaceData.perceptualRoughness = pow(surfaceData.roughness, 2);

    surfaceData.reflectance = _Reflectance;
    surfaceData.occlusion = lerp(1, metallicGlossMap.g, _Occlusion);

    surfaceData.f0 = 0.16 * surfaceData.reflectance * surfaceData.reflectance * (1 - surfaceData.metallic) + surfaceData
        .albedo.rgb * surfaceData.metallic;

    #ifdef SKIN
    surf.f0 = unity_ColorSpaceDielectricSpec.rgb * 0.7;
    surf.oneMinusReflectivity = SpecularStrength(surf.f0);
    #endif

    


    return surfaceData;
}


#endif
