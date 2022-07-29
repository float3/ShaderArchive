LightSource CalcMainLight()
{
	LightSource MainLight;
	MainLight.Direction = normalize(UnityWorldSpaceLightDir(input.worldPos.xyz));
	MainLight.HalfVector = normalize(MainLight.Direction + ViewDir);
	MainLight.NoL = saturate(dot(input.normal, MainLight.Direction));
	MainLight.LoH = saturate(dot(MainLight.Direction, MainLight.HalfVector));
	MainLight.NoH = saturate(dot(input.normal, MainLight.HalfVector));
	MainLight.LightColor = _LightColor0.rgb;
	MainLight.Intensity = dot(MainLight.LightColor, unity_ColorSpaceLuminance.rgb);
	LIGHT_ATTENUATION_NO_SHADOW_MUL(lightAttenNoShadows, input, input.worldPos.xyz);
	MainLight.Attenuation = lightAttenNoShadows * shadow;
	#if defined(SHADOWS_SCREEN) && defined(UNITY_PASS_FORWARDBASE) // fix screen space shadow arficats from msaa
	MainLight.Attenuation = SSDirectionalShadowAA(input._ShadowCoord, MainLight.Attenuation);
	#endif
	#if defined(SHADOWS_SCREEN) || defined(SHADOWS_DEPTH) || defined(SHADOWS_CUBE)
	if (MainLight.NoL > 0.0) MainLight.Attenuation *= computeMicroShadowing(MainLight.NoL, surf.occlusion);
	#endif
	MainLight.colorXatten = MainLight.LightColor * MainLight.Attenuation;
	MainLight.irradiance = MainLight.colorXatten * MainLight.NoL;
	MainLight.diffuse = Diffuse(MainLight.NoL, MainLight.LoH);
	MainLight.finalLight = (MainLight.NoL * MainLight.Attenuation * MainLight.LightColor) * MainLight.diffuse;
	MainLight.specular = 0;
	return MainLight;
};

FourLightSources CalcVertexLight(float3 ViewDir)
{
	FourLightSources VertexLights;
	float4 toLightX = unity_4LightPosX0 - input.worldPos.x;
	float4 toLightY = unity_4LightPosY0 - input.worldPos.y;
	float4 toLightZ = unity_4LightPosZ0 - input.worldPos.z;
	
	float4 lengthSq = 0;
	lengthSq += toLightX * toLightX;
	lengthSq += toLightY * toLightY;
	lengthSq += toLightZ * toLightZ;

	float4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
	float4 atten2 = saturate(1 - (lengthSq * unity_4LightAtten0 / 25));
	atten = min(atten, atten2 * atten2);

	VertexLights.x.Attenuation = atten.x;
	VertexLights.y.Attenuation = atten.y;
	VertexLights.z.Attenuation = atten.z;
	VertexLights.w.Attenuation = atten.w;

	float3 toLightXDir = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
	float3 toLightYDir = float3(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y);
	float3 toLightZDir = float3(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z);
	float3 toLightWDir = float3(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w);

	float3 dirX = toLightXDir - input.worldPos.xyz;
	float3 dirY = toLightYDir - input.worldPos.xyz;
	float3 dirZ = toLightZDir - input.worldPos.xyz;
	float3 dirW = toLightWDir - input.worldPos.xyz;

	dirX *= length(toLightXDir) * atten.x;
	dirY *= length(toLightYDir) * atten.y;
	dirZ *= length(toLightZDir) * atten.z;
	dirW *= length(toLightWDir) * atten.w;

	VertexLights.x.Direction = normalize(dirX);
	VertexLights.y.Direction = normalize(dirY);
	VertexLights.z.Direction = normalize(dirZ);
	VertexLights.w.Direction = normalize(dirW);
	
	VertexLights.x.HalfVector = normalize(VertexLights.x.Direction + ViewDir);
	VertexLights.y.HalfVector = normalize(VertexLights.y.Direction + ViewDir);
	VertexLights.z.HalfVector = normalize(VertexLights.z.Direction + ViewDir);
	VertexLights.w.HalfVector = normalize(VertexLights.w.Direction + ViewDir);

	VertexLights.x.NoL = saturate(dot(input.normal, VertexLights.x.Direction));
	VertexLights.y.NoL = saturate(dot(input.normal, VertexLights.y.Direction));
	VertexLights.z.NoL = saturate(dot(input.normal, VertexLights.z.Direction));
	VertexLights.w.NoL = saturate(dot(input.normal, VertexLights.w.Direction));

	VertexLights.x.NoH = saturate(dot(input.normal, VertexLights.x.HalfVector));
	VertexLights.y.NoH = saturate(dot(input.normal, VertexLights.y.HalfVector));
	VertexLights.z.NoH = saturate(dot(input.normal, VertexLights.z.HalfVector));
	VertexLights.w.NoH = saturate(dot(input.normal, VertexLights.w.HalfVector));
	
	VertexLights.x.LoH = saturate(dot(VertexLights.x.Direction, VertexLights.x.HalfVector));
	VertexLights.y.LoH = saturate(dot(VertexLights.y.Direction, VertexLights.y.HalfVector));
	VertexLights.z.LoH = saturate(dot(VertexLights.z.Direction, VertexLights.z.HalfVector));
	VertexLights.w.LoH = saturate(dot(VertexLights.w.Direction, VertexLights.w.HalfVector));

	VertexLights.x.LightColor = unity_LightColor[0].rgb;
	VertexLights.y.LightColor = unity_LightColor[1].rgb;
	VertexLights.z.LightColor = unity_LightColor[2].rgb;
	VertexLights.w.LightColor = unity_LightColor[3].rgb;

	VertexLights.x.Intensity = Luminance(VertexLights.x.LightColor);
	VertexLights.y.Intensity = Luminance(VertexLights.y.LightColor);
	VertexLights.z.Intensity = Luminance(VertexLights.z.LightColor);
	VertexLights.w.Intensity = Luminance(VertexLights.w.LightColor);

	VertexLights.x.colorXatten = unity_LightColor[0].rgb * VertexLights.x.Attenuation;
	VertexLights.y.colorXatten = unity_LightColor[1].rgb * VertexLights.y.Attenuation;
	VertexLights.z.colorXatten = unity_LightColor[2].rgb * VertexLights.z.Attenuation;
	VertexLights.w.colorXatten = unity_LightColor[3].rgb * VertexLights.w.Attenuation;

	VertexLights.x.irradiance = VertexLights.x.colorXatten * VertexLights.x.NoL;
	VertexLights.y.irradiance = VertexLights.y.colorXatten * VertexLights.y.NoL;
	VertexLights.z.irradiance = VertexLights.z.colorXatten * VertexLights.z.NoL;
	VertexLights.w.irradiance = VertexLights.w.colorXatten * VertexLights.w.NoL;

	VertexLights.x.diffuse = Diffuse(VertexLights.x.NoL, VertexLights.x.LoH);
	VertexLights.y.diffuse = Diffuse(VertexLights.y.NoL, VertexLights.y.LoH);
	VertexLights.z.diffuse = Diffuse(VertexLights.z.NoL, VertexLights.z.LoH);
	VertexLights.w.diffuse = Diffuse(VertexLights.w.NoL, VertexLights.w.LoH);
	
	VertexLights.x.finalLight = (VertexLights.x.NoL * VertexLights.x.Attenuation * VertexLights.x.LightColor) *Diffuse(VertexLights.x.NoL, VertexLights.x.LoH);
	VertexLights.y.finalLight = (VertexLights.y.NoL * VertexLights.y.Attenuation * VertexLights.y.LightColor) *Diffuse(VertexLights.y.NoL, VertexLights.y.LoH);
	VertexLights.z.finalLight = (VertexLights.z.NoL * VertexLights.z.Attenuation * VertexLights.z.LightColor) *Diffuse(VertexLights.z.NoL, VertexLights.z.LoH);
	VertexLights.w.finalLight = (VertexLights.w.NoL * VertexLights.w.Attenuation * VertexLights.w.LightColor) *Diffuse(VertexLights.w.NoL, VertexLights.w.LoH);

	VertexLights.x.specular = 0;
	VertexLights.y.specular = 0;
	VertexLights.z.specular = 0;
	VertexLights.w.specular = 0;
	
	return VertexLights;
}

LightSource CalcProbeLight()
{
	LightSource ProbeLight;
	ProbeLight.Direction = normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz);
	ProbeLight.HalfVector = normalize(ProbeLight.Direction + ViewDir);
	ProbeLight.NoH = saturate(dot(input.normal, ProbeLight.HalfVector));
	ProbeLight.NoL = saturate(dot(input.normal, ProbeLight.Direction));
	ProbeLight.LoH = saturate(dot(ProbeLight.Direction, ProbeLight.HalfVector));
	ProbeLight.LightColor = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) + float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / 3.0;;
	ProbeLight.Intensity = Luminance(ProbeLight.LightColor);
	ProbeLight.Attenuation = 1;
	ProbeLight.colorXatten = ProbeLight.LightColor;
	ProbeLight.irradiance = ProbeLight.colorXatten * ProbeLight.NoL;
	ProbeLight.diffuse = Diffuse(ProbeLight.NoL, ProbeLight.LoH);
	ProbeLight.finalLight = (ProbeLight.NoL * ProbeLight.Attenuation * ProbeLight.LightColor) * Diffuse(ProbeLight.NoL, ProbeLight.LoH);
	ProbeLight.specular = 0;
	return ProbeLight;
};
