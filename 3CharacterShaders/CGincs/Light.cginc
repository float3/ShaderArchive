#ifndef CHARACTERSHADERS_LIGHT_INCLUDED
#define CHARACTERSHADERS_LIGHT_INCLUDED

#ifdef POINT
	#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
	unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
	float shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
	float destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
#endif
#ifdef SPOT
	#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
	DECLARE_LIGHT_COORD(input, worldPos); \
	float shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
	float destName = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#endif
#ifdef DIRECTIONAL
#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
	float shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
	float destName = 1;
#endif
#ifdef POINT_COOKIE
	#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
	DECLARE_LIGHT_COORD(input, worldPos); \
	float shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
	float destName = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r * texCUBE(_LightTexture0, lightCoord).w;
#endif
#ifdef DIRECTIONAL_COOKIE
	#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
	DECLARE_LIGHT_COORD(input, worldPos); \
	float shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
	float destName = tex2D(_LightTexture0, lightCoord).w;
#endif

//from bgolus https://forum.unity.com/threads/fixing-screen-space-directional-shadows-and-anti-aliasing.379902/
#if defined(SHADOWS_SCREEN) && defined(UNITY_PASS_FORWARDBASE) // fix screen space shadow arficats from msaa

#ifndef HAS_DEPTH_TEXTURE
#define HAS_DEPTH_TEXTURE
sampler2D_float _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;
#endif

float SSDirectionalShadowAA(float4 _ShadowCoord, float atten)
{
	float a = atten;
	float2 screenUV = _ShadowCoord.xy / _ShadowCoord.w;
	float shadow = tex2D(_ShadowMapTexture, screenUV).r;

	if (frac(_Time.x) > 0.5)
		a = shadow;

	float fragDepth = _ShadowCoord.z / _ShadowCoord.w;
	float depth_raw = tex2D(_CameraDepthTexture, screenUV).r;

	float depthDiff = abs(fragDepth - depth_raw);
	float diffTest = 1.0 / 100000.0;

	if (depthDiff > diffTest)
	{
		float2 texelSize = _CameraDepthTexture_TexelSize.xy;
		float4 offsetDepths = 0;

		float2 uvOffsets[5] = {
			float2(1.0, 0.0) * texelSize,
			float2(-1.0, 0.0) * texelSize,
			float2(0.0, 1.0) * texelSize,
			float2(0.0, -1.0) * texelSize,
			float2(0.0, 0.0)
		};

		offsetDepths.x = tex2D(_CameraDepthTexture, screenUV + uvOffsets[0]).r;
		offsetDepths.y = tex2D(_CameraDepthTexture, screenUV + uvOffsets[1]).r;
		offsetDepths.z = tex2D(_CameraDepthTexture, screenUV + uvOffsets[2]).r;
		offsetDepths.w = tex2D(_CameraDepthTexture, screenUV + uvOffsets[3]).r;

		float4 offsetDiffs = abs(fragDepth - offsetDepths);

		float diffs[4] = {offsetDiffs.x, offsetDiffs.y, offsetDiffs.z, offsetDiffs.w};

		int lowest = 4;
		float tempDiff = depthDiff;
		for (int i = 0; i < 4; i++)
		{
			if (diffs[i] < tempDiff)
			{
				tempDiff = diffs[i];
				lowest = i;
			}
		}

		a = tex2D(_ShadowMapTexture, screenUV + uvOffsets[lowest]).r;
	}
	return a;
}
#endif

float computeMicroShadowing(float NoL, float visibility)
{
    // Chan 2018, "Material Advances in Call of Duty: WWII"
    float aperture = rsqrt(1.0 - visibility);
    float microShadow = saturate(NoL * aperture);
    return microShadow * microShadow;
}


Light CalcMainLight(Surface surf, v2f input, Camera cameraData, Mesh meshData)
{
    Light MainLight;
    MainLight.direction = normalize(UnityWorldSpaceLightDir(input.worldPos.xyz));
    MainLight.halfVector = normalize(MainLight.direction + cameraData.viewDir);
    MainLight.NoL = saturate(dot(meshData.normal, MainLight.direction));
    MainLight.LoH = saturate(dot(MainLight.direction, MainLight.halfVector));
    MainLight.NoH = saturate(dot(meshData.normal, MainLight.halfVector));
    MainLight.color = _LightColor0.rgb;
    MainLight.intensity = dot(MainLight.color, unity_ColorSpaceLuminance.rgb);
	UNITY_LIGHT_ATTENUATION(lightAttenuation, input, input.worldPos.xyz);
	MainLight.attenuation = lightAttenuation;
    #if defined(SHADOWS_SCREEN) && defined(UNITY_PASS_FORWARDBASE) // fix screen space shadow arficats from msaa
		MainLight.attenuation = SSDirectionalShadowAA(input._ShadowCoord, MainLight.attenuation);
    #endif
    #if defined(SHADOWS_SCREEN) || defined(SHADOWS_DEPTH) || defined(SHADOWS_CUBE)
        if (MainLight.NoL > 0.0) MainLight.attenuation *= computeMicroShadowing(MainLight.NoL, surf.occlusion);
    #endif

    MainLight.colorXatten = MainLight.color * MainLight.attenuation;
    MainLight.irradiance = MainLight.colorXatten * MainLight.NoL;
    MainLight.diffuse = diffuse(surf.roughness, cameraData.NoV, MainLight.NoL, MainLight.LoH);
    MainLight.finalLight = MainLight.NoL * MainLight.attenuation * MainLight.color * MainLight.diffuse;


    MainLight.specular = 0;

    return MainLight;
}

#endif
