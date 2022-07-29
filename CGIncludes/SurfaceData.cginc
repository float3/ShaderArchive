float2 GetUVs(float4 st, uint type)
{
    float2 uv;

    switch (type)
    {
    case 0:
        uv = float2(input.uvs.xy * st.xy + st.zw);
        break;
    case 1:
        uv = float2(input.uvs.zw * st.xy + st.zw);
        break;
    default:
        uv = float2(input.uvs.xy * st.xy + st.zw);
        break;
    }

    return uv;
}

float4 SampleTexture(Texture2D tex, float4 st, sampler s, int type)
{
    return tex.Sample(s, GetUVs(st, type));
}

/*void ApplyAudioLinkEmission(inout float3 emissionMap)
{
	const uint note = floor(input.uvs.zw.x);
	UNITY_BRANCH
	if (note >= 1)
	{
		float a[12];


		a[0] = input._0123.x;
		a[1] = input._0123.y;
		a[2] = input._0123.z;
		a[3] = input._0123.w;
		a[4] = input._4567.x;
		a[5] = input._4567.y;
		a[6] = input._4567.z;
		a[7] = input._4567.w;
		a[8] = input._891011.x;
		a[9] = input._891011.y;
		a[10] = input._891011.z;
		a[11] = input._891011.w;


		float alEmissionSample = a[note - 1] - (input.uvs.y / 3 + 0.6) * a[input.highest];

		emissionMap *= alEmissionSample;
	}
	else
	{
		emissionMap = 0;
	}
}*/

void Init()
{
    surf = (SurfaceData)0;
    surf.tangentNormal = float3(0, 0, 1);
    surf.emission = 0;
    surf.metallic = 0;
    surf.perceptualRoughness = 0;
    surf.occlusion = 1;
    surf.reflectance = 0.5;
    surf.anisotropicDirection = 1;
    surf.anisotropy = 0;
    surf.directSpecular = 0;
    surf.indirectSpecular = 0;
    surf.indirectDiffuse = 0;
}

float2 hash2(float2 p)
{
    return frac(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.5453);
}

float2 voronoiT2(float2 x, float angle, out float2 cellPoints)
{
    float2 n = floor(x);
    float2 f = frac(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
    float2 mr;
    float2 cellID = 0;

    float md = 8.0;
    for (int j = -1; j <= 1; j++)
    {
        for (int k = -1; k <= 1; k++)
        {
            float2 g = float2(k, j);
            float2 o = hash2(n + g);
            o = sin(o * angle * UNITY_HALF_PI) * 0.5 + 0.5;
            float2 r = g + o - f;
            float d = dot(r, r);

            // UNITY_BRANCH
            UNITY_FLATTEN
            if (d < md)
            {
                md = d;
                mr = r;
                cellID = n + g;
            }
        }
    }
    cellPoints = mr;
    return cellID;
}

void SHGeomerics()
{
    float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    surf.indirectDiffuse.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, input.normal);
    surf.indirectDiffuse.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, input.normal);
    surf.indirectDiffuse.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, input.normal);
    surf.indirectDiffuse = max(0, surf.indirectDiffuse);
    surf.indirectDiffuse += SHEvalLinearL2(normalize(float4(input.normal, 1)));
}
#ifdef GIMMICK
#include "Gimmick.cginc"
#endif

#ifdef GIMMICK2
#include "Eyes.cginc"
#endif

void InitSurfaceData(float4 mainTexture)
{
    surf.albedo = mainTexture.rgb;

    #ifdef GIMMICK
    float3 asd = lerp(0,eyes(input.worldPos.xy * 3),input.pos.z + 0.1);
    surf.albedo += asd;
    #endif

    #ifdef GIMMICK2

    float2 uv = input.uvs.xy;
    uv.x = fmod(uv.x,6);

    if (abs(uv.x) > 3) uv.x = 6 - abs(uv.x);
    if (abs(uv.y) > 3) uv.y = 6 - abs(uv.y);
                
    float d = eyes(uv);
    //d /= fwidth(d);
    d = saturate(d);

    surf.albedo.r += d;

    #endif

    if (_Mode != 0)
    {
        surf.alpha = mainTexture.a;
    }
    else
    {
        surf.alpha = 1;
    }
    int uvfloored = floor(input.uvs.x);

    if (_Skin && uvfloored != 0)
    {
    }
    else
    {
        float4 normalMap = SampleTexture(_BumpMap, _BumpMap_ST, sampler_BumpMap, 0);
        float3 tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);
        input.normal = normalize
        (
            tangentNormal.x * input.tangent.xyz +
            tangentNormal.y * bitangent +
            tangentNormal.z * input.normal
        );
        input.tangent.xyz = normalize(cross(input.normal, bitangent)).xyz;
        bitangent = normalize(cross(input.normal, input.tangent.xyz));

        ViewDir = !isOrtho()
                      ? normalize(_WorldSpaceCameraPos - input.worldPos.xyz)
                      : normalize(UNITY_MATRIX_I_V._m02_m12_m22);
        NoV = abs(dot(input.normal, ViewDir));
    }

    // #ifndef HAIR
    // UNITY_BRANCH
    // if (_Skin)
    // {
    //     float2 maskingUVs = input.uvs.xy % 1;
    //     float ratio = (_FrecklesLocation.y - _FrecklesLocation.x) / (_FrecklesLocation.w - _FrecklesLocation.z);
    //     if (maskingUVs.x > _FrecklesLocation.x && maskingUVs.x < _FrecklesLocation.y && maskingUVs.y >
    //         _FrecklesLocation.z && maskingUVs.y < _FrecklesLocation.w)
    //     {
    //         maskingUVs.x -= _FrecklesLocation.x;
    //         maskingUVs.x *= 1 / (_FrecklesLocation.y - _FrecklesLocation.x);
    //         maskingUVs.y -= _FrecklesLocation.z;
    //         maskingUVs.y *= 1 / (_FrecklesLocation.w - _FrecklesLocation.z);
    //
    //         float2 cellID, cellPoints;
    //         cellID = voronoiT2(input.uvs.xy * (float2(ratio, 1) * _FrecklesScale), 6, cellPoints);
    //
    //         float2 nosemaskUVs = maskingUVs;
    //         nosemaskUVs.x *= 1.6;
    //         nosemaskUVs.x -= 1.6 / 2;
    //         nosemaskUVs.y -= 0.1;
    //
    //         float nosemask = smoothstep(0.47, 0.47 * 0.75, length(nosemaskUVs));
    //         nosemaskUVs = maskingUVs;
    //         nosemaskUVs.x -= 0.34;
    //         nosemaskUVs.x *= 1.9;
    //         nosemaskUVs.x -= 1.9 / 2;
    //         nosemaskUVs.y -= 1.08;
    //         nosemask += smoothstep(0.58, 0.58 * 0.75, length(nosemaskUVs));
    //
    //         nosemaskUVs.x = maskingUVs.x;
    //         nosemaskUVs.x += 0.34;
    //         nosemaskUVs.x *= 1.9;
    //         nosemaskUVs.x -= 1.9 / 2;
    //         nosemask += smoothstep(0.58, 0.58 * 0.75, length(nosemaskUVs));
    //
    //         float2 outermaskUVs = maskingUVs;
    //         outermaskUVs.x = smoothstep(0.32 * 2, 0.75, abs(outermaskUVs.x - 0.5) * 1.5);
    //         outermaskUVs.y = smoothstep(0.25, 0.5, abs(outermaskUVs.y - 0.5));
    //         float outermask = max(outermaskUVs.x, outermaskUVs.y);
    //
    //
    //         float maskmask = 1 - max(nosemask, outermask);
    //         maskmask = lerp(maskmask, 1, _FrecklesLocation.x == 0);
    //         if (!_FreckleMask)
    //         {
    //             maskmask = 1;
    //         }
    //         float2 randomCell = saturate(hash2(cellID.xy + _FrecklesRandomness));
    //
    //         float randomCellXForUse = randomCell.x * (1 / _FrecklesAmount);
    //         float freckleRoundnessScale = (1 - _FrecklesRoundness) + 1.0;
    //         float2 freckleRoundness = lerp(float2(freckleRoundnessScale, 1), float2(1, freckleRoundnessScale),
    //                                        randomCellXForUse);
    //
    //         float cellP = length(cellPoints * freckleRoundness);
    //         cellP = smoothstep(_FrecklesSize * 1.5, _FrecklesSize * 0.6, cellP);
    //
    //         float cellCutoff = randomCell.x >= 1 - _FrecklesAmount;
    //         float asd = cellCutoff.x * cellP * smoothstep(0, 0.1, maskmask);
    //
    //         float3 das = (float3(196, 102, 58) / 255.0);
    //         das = lerp(das, (float3(153, 79, 44) / 255.0), randomCell.x);
    //
    //         das *= lerp(1, surf.albedo.rgb, 0.3333);
    //         surf.albedo.rgb = lerp(surf.albedo.rgb, das, asd * randomCell.y);
    //         _Reflectance = lerp(0.42, 0.5, asd * randomCell.y);
    //         _Metallic = 0;
    //         _Glossiness = lerp(0.45, 0.55, asd * randomCell.y);
    //     }
    //
    //     // case -1:
    //     // 	_Reflectance = 0;
    //     // 	_Metallic = 0;
    //     // 	_Glossiness = 0;
    //     // 	break;
    //     // case 0: //Skin
    //     // 	_Reflectance = 0.42;
    //     // 	_Metallic = 0;
    //     // 	_Glossiness = 0.5;
    //     // 	isSkin = true;
    //     // 	break;
    //     // case 1: //Hair
    //     // 	_Reflectance = 0.54;
    //     // 	_Metallic = 0;
    //     // 	_Glossiness = 0.5;
    //     // 	break;
    //     // case 2: //Eyes
    //     // 	_Reflectance = 0.39;
    //     // 	_Metallic = 0.0;
    //     // 	_Glossiness = 0.5;
    //     // 	isSkin = true;
    //     //
    //     // 	break;
    //     // case 3: //Teeth
    //     // 	_Reflectance = 0.6;
    //     // 	_Metallic = 0;
    //     // 	_Glossiness = 0.5;
    //     // 	break;
    // }
    // #endif

    float4 metallicglossmap = SampleTexture(_MetallicGlossMap, _MetallicGlossMap_ST, sampler_MetallicGlossMap,
                                            _UVSec);
    float occlusion = SampleTexture(_OcclusionMap, _OcclusionMap_ST, sampler_OcclusionMap, _UVSec).g;
    surf.occlusion = lerp(1, occlusion, _Occlusion);
    surf.roughness = 1 - (_Glossiness * metallicglossmap.a);
    surf.perceptualRoughness = pow(surf.roughness, 2);
    surf.metallic = metallicglossmap.r * (_Metallic * _Metallic);
    surf.clampedRoughness = max(MIN_ROUGHNESS, surf.perceptualRoughness);
    surf.reflectance = _Reflectance;
    surf.anisotropy = _Anisotropy;

    float3 sh_conv = SHConvolution(_Wrap);
    surf.indirectDiffuse = ShadeSH9_wrappedCorrect(input.normal, sh_conv);

    surf.f0 = 0.16 * surf.reflectance * surf.reflectance * (1 - surf.metallic) + surf.albedo.rgb * surf.metallic;
    #ifdef SKIN
	surf.f0 = unity_ColorSpaceDielectricSpec.rgb * 0.7;
	surf.oneMinusReflectivity = SpecularStrength(surf.f0);
    #endif

    surf.fresnel = fresnel(surf.f0, NoV);
    float2 dfguv = float2(NoV, surf.perceptualRoughness);
    surf.dfg = _DFG.Sample(sampler_DFG, dfguv).xyz;
    if (!_Cloth)
        surf.energyCompensation = 1.0 + surf.f0 * (1.0 / surf.dfg.y - 1.0);
    else
        surf.energyCompensation = 1.0;
    surf.anisotropicT = input.tangent.xyz;
    surf.anisotropicB = bitangent;
}
