//------------------------------------------------------------------------------
// BRDF configuration
//------------------------------------------------------------------------------

// Diffuse BRDFs
#define DIFFUSE_LAMBERT             0
#define DIFFUSE_BURLEY              1

// Specular BRDF
// Normal distribution functions
#define SPECULAR_D_GGX              1

// Anisotropic NDFs
#define SPECULAR_D_GGX_ANISOTROPIC  1

// Cloth NDFs
#define SPECULAR_D_CHARLIE          1

// Visibility functions
#define SPECULAR_V_SMITH_GGX        1
#define SPECULAR_V_GGX_ANISOTROPIC  2
#define SPECULAR_V_KELEMEN          3
#define SPECULAR_V_NEUBELT          4

// Fresnel functions
#define SPECULAR_F_SCHLICK          0

#define BRDF_DIFFUSE                DIFFUSE_BURLEY

#if FILAMENT_QUALITY < FILAMENT_QUALITY_HIGH
#define BRDF_SPECULAR_D             SPECULAR_D_GGX
#define BRDF_SPECULAR_V             SPECULAR_V_SMITH_GGX_FAST
#define BRDF_SPECULAR_F             SPECULAR_F_SCHLICK
#else
#define BRDF_SPECULAR_D             SPECULAR_D_GGX
#define BRDF_SPECULAR_V             SPECULAR_V_SMITH_GGX
#define BRDF_SPECULAR_F             SPECULAR_F_SCHLICK
#endif

#define BRDF_CLEAR_COAT_D           SPECULAR_D_GGX
#define BRDF_CLEAR_COAT_V           SPECULAR_V_KELEMEN

#define BRDF_ANISOTROPIC_D          SPECULAR_D_GGX_ANISOTROPIC
#define BRDF_ANISOTROPIC_V          SPECULAR_V_GGX_ANISOTROPIC

#define BRDF_CLOTH_D                SPECULAR_D_CHARLIE
#define BRDF_CLOTH_V                SPECULAR_V_NEUBELT

#define MIN_PERCEPTUAL_ROUGHNESS 0.045
#define MIN_ROUGHNESS            0

//------------------------------------------------------------------------------
// Specular BRDF implementations
//------------------------------------------------------------------------------

float D_GGX(float roughness, float NoH)
{
	// Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"

	// In mediump, there are two problems computing 1.0 - NoH^2
	// 1) 1.0 - NoH^2 suffers floating point cancellation when NoH^2 is close to 1 (highlights)
	// 2) NoH doesn't have enough precision around 1.0
	// Both problem can be fixed by computing 1-NoH^2 in highp and providing NoH in highp as well

	// However, we can do better using Lagrange's identity:
	//      ||a x b||^2 = ||a||^2 ||b||^2 - (a . b)^2
	// since N and H are unit vectors: ||N x H||^2 = 1.0 - NoH^2
	// This computes 1.0 - NoH^2 directly (which is close to zero in the highlights and has
	// enough precision).
	// Overall this yields better performance, keeping all computations in mediump
	float oneMinusNoHSquared = 1.0 - NoH * NoH;

	float a = NoH * roughness;
	float k = roughness / (oneMinusNoHSquared + a * a);
	float d = k * k * (1.0 / UNITY_PI);
	return d;
}

float D_GGX_Anisotropic(float at, float ab, float ToH, float BoH, float NoH)
{
	// Burley 2012, "Physically-Based Shading at Disney"

	// The values at and ab are perceptualRoughness^2, a2 is therefore perceptualRoughness^4
	// The dot product below computes perceptualRoughness^8. We cannot fit in fp16 without clamping
	// the roughness to too high values so we perform the dot product and the division in fp32
	float a2 = at * ab;
	float3 d = float3(ab * ToH, at * BoH, a2 * NoH);
	float d2 = dot(d, d);
	float b2 = a2 / d2;
	return a2 * b2 * b2 * (1.0 / UNITY_PI);
}

float D_Charlie(float roughness, float NoH)
{
	// Estevez and Kulla 2017, "Production Friendly Microfacet Sheen BRDF"
	float invAlpha = 1.0 / roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	return (2.0 + invAlpha) * pow(sin2h, invAlpha * 0.5) / (2.0 * UNITY_PI);
}

float D_Ashikhmin(float roughness, float NoH)
{
	// Ashikhmin 2007, "Distribution-based BRDFs"
	float a2 = roughness * roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	float sin4h = sin2h * sin2h;
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (UNITY_PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}

float V_SmithGGXCorrelated(float roughness, float NoV, float NoL)
{
	// Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
	float a2 = roughness * roughness;
	// TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
	float lambdaV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
	float lambdaL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
	float v = 0.5 / (lambdaV + lambdaL);
	// a2=0 => v = 1 / 4*NoL*NoV   => min=1/4, max=+inf
	// a2=1 => v = 1 / 2*(NoL+NoV) => min=1/4, max=+inf
	// clamp to the maximum value representable in mediump
	return v;
}

float V_SmithGGXCorrelated_Anisotropic(float at, float ab, float ToV, float BoV,
                                       float ToL, float BoL, float NoV, float NoL)
{
	// Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
	// TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
	float lambdaV = NoL * length(float3(at * ToV, ab * BoV, NoV));
	float lambdaL = NoV * length(float3(at * ToL, ab * BoL, NoL));
	float v = 0.5 / (lambdaV + lambdaL);
	return v;
}

float V_Kelemen(float LoH)
{
	// Kelemen 2001, "A Microfacet Based Coupled Specular-Matte BRDF Model with Importance Sampling"
	return 0.25 / (LoH * LoH);
}

float V_Neubelt(float NoV, float NoL)
{
	// Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
	return 1.0 / (4.0 * (NoL + NoV - NoL * NoV));
}

float3 F_Schlick(float3 f0, float f90, float VoH)
{
	return f0 + (f90 - f0) * Pow5(1.0 - VoH);
}

/*float3 F_Schlick(float3 f0, float VoH)
{
	return f0 + (1.0 - f0) * pow(1.0 - VoH, 5);
}*/

float F_Schlick(float f0, float f90, float VoH)
{
	return f0 + (f90 - f0) * Pow5(1.0 - VoH);
}

//------------------------------------------------------------------------------
// Specular BRDF dispatch
//------------------------------------------------------------------------------

float distribution(float roughness, float NoH)
{
	return GGXTerm(roughness, NoH);
}

float visibility(float roughness, float NoV, float NoL)
{
	return V_SmithGGXCorrelated(roughness, NoV, NoL);
}

float3 fresnel(float3 f0, float LoH)
{
	float f90 = saturate(dot(f0, float(50.0 * 0.33).xxx));
	return F_Schlick(f0, f90, LoH);
}

float distributionAnisotropic(float at, float ab, float ToH, float BoH, float NoH)
{
	#if BRDF_ANISOTROPIC_D == SPECULAR_D_GGX_ANISOTROPIC
	return D_GGX_Anisotropic(at, ab, ToH, BoH, NoH);
	#endif
}

float visibilityAnisotropic(float at, float ab,
                            float ToV, float BoV, float ToL, float BoL, float NoV, float NoL)
{
	return V_SmithGGXCorrelated_Anisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, NoL);
}

float distributionCloth(float roughness, float NoH)
{
	return D_Charlie(roughness, NoH);
}

float visibilityCloth(float NoV, float NoL)
{
	return V_Neubelt(NoV, NoL);
}

//------------------------------------------------------------------------------
// Diffuse BRDF implementations
//------------------------------------------------------------------------------

float Fd_Lambert()
{
	return 1.0 / UNITY_PI;
}

float Fd_Burley(float NoL, float LoH)
{
	// Burley 2012, "Physically-Based Shading at Disney"
	float f90 = 0.5 + 2.0 * surf.roughness * LoH * LoH;
	float lightScatter = F_Schlick(1.0, f90, NoL);
	float viewScatter = F_Schlick(1.0, f90, NoV);
	return lightScatter * viewScatter;
}

float sq(float x)
{
	return x * x;
}

// Energy conserving wrap diffuse term, does *not* include the divide by pi
float Fd_Wrap(float NoL, float w)
{
	return saturate((NoL + w) / sq(1.0 + w));
}

//------------------------------------------------------------------------------
// Diffuse BRDF dispatch
//------------------------------------------------------------------------------

float Diffuse(float NoL, float LoH)
{
	return Fd_Burley(NoL, LoH);
}

float3 diffuseLobe(float NoV, float NoL, float LoH)
{
	return surf.diffuseColor * Diffuse(NoL, LoH);
}

float3 isotropicLobe(LightSource light, float3 h,
                     float NoV, float NoL, float NoH, float LoH)
{
	float D = distribution(surf.roughness, NoH);
	float V = visibility(surf.roughness, NoV, NoL);
	float3 F = fresnel(surf.f0, LoH);

	return (D * V) * F;
}

float3 specularLobe(LightSource light, float3 h,
                    float NoV, float NoL, float NoH, float LoH)
{
	#if defined(MATERIAL_HAS_ANISOTROPY)
	return anisotropicLobe(pixel, light, h, NoV, NoL, NoH, LoH);
	#else
	return isotropicLobe(light, h, NoV, NoL, NoH, LoH);
	#endif
}

float3 sheenLobe(float NoV, float NoL, float NoH)
{
	float D = distributionCloth(surf.sheenRoughness, NoH);
	float V = visibilityCloth(NoV, NoL);

	return (D * V) * surf.sheenColor;
}

float3 anisotropicLobe(SurfaceData surf, LightSource light, float3 h,
                       float NoV, float NoL, float NoH, float LoH)
{
	float3 l = light.Direction;
	float3 t = surf.anisotropicT;
	float3 b = surf.anisotropicB;
	float3 v = ViewDir;

	float ToV = dot(t, v);
	float BoV = dot(b, v);
	float ToL = dot(t, l);
	float BoL = dot(b, l);
	float ToH = dot(t, h);
	float BoH = dot(b, h);

	// Anisotropic parameters: at and ab are the roughness along the tangent and bitangent
	// to simplify materials, we derive them from a single roughness parameter
	// Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
	float at = max(surf.roughness * (1.0 + surf.anisotropy), MIN_ROUGHNESS);
	float ab = max(surf.roughness * (1.0 - surf.anisotropy), MIN_ROUGHNESS);

	// specular anisotropic BRDF
	float D = distributionAnisotropic(at, ab, ToH, BoH, NoH);
	float V = visibilityAnisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, NoL);
	float3 F = fresnel(surf.f0, LoH);

	return (D * V) * F;
}

float FabricD(float NdotH)
{
	return 0.96 * sq(1 - NdotH) + 0.057;
}

float FabricScatterFresnelLerp(float nv, float scale)
{
	float t0 = Pow4(1 - nv).x;
	float t1 = 0.4 * (1 - nv);
	return (t1 - t0) * scale + t0;
}

// w0, w1, w2, and w3 are the four cubic B-spline basis functions
float w0(float a)
{
	//    return (1.0f/6.0f)*(-a*a*a + 3.0f*a*a - 3.0f*a + 1.0f);
	return (1.0f / 6.0f) * (a * (a * (-a + 3.0f) - 3.0f) + 1.0f); // optimized
}

float w1(float a)
{
	//    return (1.0f/6.0f)*(3.0f*a*a*a - 6.0f*a*a + 4.0f);
	return (1.0f / 6.0f) * (a * a * (3.0f * a - 6.0f) + 4.0f);
}

float w2(float a)
{
	//    return (1.0f/6.0f)*(-3.0f*a*a*a + 3.0f*a*a + 3.0f*a + 1.0f);
	return (1.0f / 6.0f) * (a * (a * (-3.0f * a + 3.0f) + 3.0f) + 1.0f);
}

float w3(float a)
{
	return (1.0f / 6.0f) * (a * a * a);
}

// g0 and g1 are the two amplitude functions
float g0(float a)
{
	return w0(a) + w1(a);
}

float g1(float a)
{
	return w2(a) + w3(a);
}

// h0 and h1 are the two offset functions
float h0(float a)
{
	// note +0.5 offset to compensate for CUDA linear filtering convention
	return -1.0f + w1(a) / (w0(a) + w1(a)) + 0.5f;
}

float h1(float a)
{
	return 1.0f + w3(a) / (w2(a) + w3(a)) + 0.5f;
}

float3 Refract(float3 incoming, float3 normal, float eta)
{
	float c = dot(incoming, normal);
	float b = 1.0 + eta * eta * (c * c - 1.0);
	float k = eta * c - sign(c) * sqrt(b);
	float3 R = k * normal - eta * incoming;
	return normalize(R);
}

float shEvaluateDiffuseL1Geomerics_local(float L0, float3 L1, float3 n)
{
	n = normalize(n);
	// average energy
	float R0 = L0;

	// avg direction of incoming light
	float3 R1 = 0.5f * L1;

	// directional brightness
	float lenR1 = length(R1);

	// linear angle between normal and direction 0-1
	//float q = 0.5f * (1.0f + dot(R1 / lenR1, n));
	//float q = dot(R1 / lenR1, n) * 0.5 + 0.5;
	float q = dot(normalize(R1), n) * 0.5 + 0.5;
	//q = saturate(q); // Thanks to ScruffyRuffles for the bug identity.

	// power for q
	// lerps from 1 (linear) to 3 (cubic) based on directionality
	float p = 1.0f + 2.0f * lenR1 / R0;

	// dynamic range constant
	// should vary between 4 (highly directional) and 0 (ambient)
	float a = (1.0f - lenR1 / R0) / (1.0f + lenR1 / R0);

	return R0 * (a + (1.0f - a) * (p + 1.0f) * pow(q, p));
}

// SH Convolution Functions
// Code adapted from https://blog.selfshadow.com/2012/01/07/righting-wrap-part-2/
///////////////////////////

float3 GeneralWrapSH(float fA) // original unoptimized
{
	// Normalization factor for our model.
	float norm = 0.5 * (2 + fA) / (1 + fA);
	float4 t = float4(2 * (fA + 1), fA + 2, fA + 3, fA + 4);
	return norm * float3(t.x / t.y, 2 * t.x / (t.y * t.z),
	                     t.x * (fA * fA - t.x + 5) / (t.y * t.z * t.w));
}

float3 GeneralWrapSHOpt(float fA)
{
	const float4 t0 = float4(-0.047771, -0.129310, 0.214438, 0.279310);
	const float4 t1 = float4(1.000000, 0.666667, 0.250000, 0.000000);

	float3 r;
	r.xyz = saturate(t0.xxy * fA + t0.yzw);
	r.xyz = -r * fA + t1.xyz;
	return r;
}

float3 GreenWrapSHOpt(float fW)
{
	const float4 t0 = float4(0.0, 1.0 / 4.0, -1.0 / 3.0, -1.0 / 2.0);
	const float4 t1 = float4(1.0, 2.0 / 3.0, 1.0 / 4.0, 0.0);

	float3 r;
	r.xyz = t0.xxy * fW + t0.xzw;
	r.xyz = r.xyz * fW + t1.xyz;
	return r;
}


float3 SHConvolution(float wrap)
{
	float3 a = GeneralWrapSH(wrap);
	float3 b = GreenWrapSHOpt(wrap);
	return lerp(b, a, _Generalised);
}

float3 ShadeSH9_wrappedCorrect(float3 normal, float3 conv)
{
	const float3 cosconv_inv = float3(1, 1.5, 4); // Inverse of the pre-applied cosine convolution
	float3 x0, x1, x2;
	conv *= cosconv_inv; // Undo pre-applied cosine convolution

	// Constant (L0)
	x0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
	// Remove the constant part from L2 and add it back with correct convolution
	float3 otherband = float3(unity_SHBr.z, unity_SHBg.z, unity_SHBb.z) / 3.0;
	x0 = (x0 + otherband) * conv.x - otherband * conv.z;

	// Linear (L1) polynomial terms
	x1.r = (dot(unity_SHAr.xyz, normal));
	x1.g = (dot(unity_SHAg.xyz, normal));
	x1.b = (dot(unity_SHAb.xyz, normal));

	// 4 of the quadratic (L2) polynomials
	float4 vB = normal.xyzz * normal.yzzx;
	x2.r = dot(unity_SHBr, vB);
	x2.g = dot(unity_SHBg, vB);
	x2.b = dot(unity_SHBb, vB);

	// Final (5th) quadratic (L2) polynomial
	float vC = normal.x * normal.x - normal.y * normal.y;
	x2 += unity_SHC.rgb * vC;

	return x0 + x1 * conv.y + x2 * conv.z;
}

float3 BetterSH9(float3 normal)
{
	float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
	float3 nonLinearSH = float3(0, 0, 0);
	nonLinearSH.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, normal);
	nonLinearSH.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, normal);
	nonLinearSH.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, normal);
	nonLinearSH = max(nonLinearSH, 0);
	return nonLinearSH;
}

float3 getAnisotropicReflectionVector(float3 viewDir, float3 btg, float3 tg, float3 normal, float roughness,
                                      float anisotropy)
{
	float3 anisotropicDirection = (anisotropy >= 0.0 ? btg : tg);
	float3 anisotropicTangent = cross(anisotropicDirection, viewDir);
	float3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
	float bendFactor = abs(anisotropy) * saturate(5.0 * roughness);
	float3 bentNormal = normalize(lerp(normal, anisotropicNormal, bendFactor));
	return reflect(-viewDir, bentNormal);
}

float3 getBoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
{
	#if UNITY_SPECCUBE_BOX_PROJECTION
	if (cubemapPosition.w > 0)
	{
		float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
		float scalar = min(min(factors.x, factors.y), factors.z);
		direction = direction * scalar + (position - cubemapPosition.xyz);
	}
	#endif

	return direction;
}

float computeSpecularAO(float NoV, float ao, float roughness)
{
	return clamp(pow(NoV + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

void computeIndirectSpecular()
{
	UNITY_BRANCH
	if (_GlossyReflections)
	{
		float3 reflDir;
		UNITY_BRANCH
		if (!_Aniso)
		{
			reflDir = reflect(-ViewDir, input.normal);
		}
		else
		{
			reflDir = getAnisotropicReflectionVector(ViewDir, surf.anisotropicB, surf.anisotropicT, input.normal,
			                                         surf.roughness, surf.anisotropy);
		}

		Unity_GlossyEnvironmentData envData;
		envData.roughness = surf.roughness;
		envData.reflUVW = getBoxProjection(reflDir, input.worldPos.xyz, unity_SpecCube0_ProbePosition,
		                                   unity_SpecCube0_BoxMin.xyz, unity_SpecCube0_BoxMax.xyz);

		float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
		surf.indirectSpecular = probe0;

		#if UNITY_SPECCUBE_BLENDING
		UNITY_BRANCH
		if (unity_SpecCube0_BoxMin.w < 0.99999)
		{
			envData.reflUVW = getBoxProjection(reflDir, input.worldPos.xyz, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin.xyz, unity_SpecCube1_BoxMax.xyz);
			float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
			surf.indirectSpecular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
		}
		#endif

		float horizon = min(1 + dot(reflDir, input.normal), 1);
		surf.dfg.x *= saturate(pow(length(surf.indirectDiffuse), _SpecularOcclusion));
		float3 dfgmul;
		if (!_Cloth)
			dfgmul = lerp(surf.dfg.xxx, surf.dfg.yyy, surf.f0);
		else
			dfgmul = surf.f0 * surf.dfg.z;
		surf.indirectSpecular = surf.indirectSpecular * dfgmul * horizon * horizon * surf.energyCompensation;
	}
	surf.indirectSpecular *= computeSpecularAO(NoV, surf.occlusion, surf.roughness);
};

void doSpecular(inout LightSource light)
{
	UNITY_BRANCH
	if (any(light.LightColor != 0))
	{
		UNITY_BRANCH
		if (_SpecularHighlights)
		{
			float3 F = fresnel(surf.f0, light.LoH);
			float D, V;
			UNITY_BRANCH
			if (!_Aniso)
			{
				if (!_Cloth)
				{
					D = GGXTerm(light.NoH, surf.clampedRoughness);
					V = V_SmithGGXCorrelated(surf.clampedRoughness, NoV, light.NoL);
				}
				else
				{
					D = distributionCloth(surf.clampedRoughness, light.NoH);
					V = visibilityCloth(NoV, light.NoL);
				}
			}
			else
			{
				float anisotropy = surf.anisotropy;
				float3 l = light.Direction;
				float3 t = surf.anisotropicT;
				float3 b = surf.anisotropicB;
				float3 v = ViewDir;
				float3 h = light.HalfVector;

				float ToV = dot(t, v);
				float BoV = dot(b, v);
				float ToL = dot(t, l);
				float BoL = dot(b, l);
				float ToH = dot(t, h);
				float BoH = dot(b, h);

				float at = surf.clampedRoughness * (1.0 + anisotropy);
				float ab = surf.clampedRoughness * (1.0 - anisotropy);
				D = D_GGX_Anisotropic(at, ab, ToH, BoH, light.NoH);
				V = V_SmithGGXCorrelated_Anisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, light.NoL);
			}
			light.specular = max(0, D * V * F * surf.energyCompensation * light.finalLight * UNITY_PI);
		}
	}
}

void doVertexSpecular(inout FourLightSources VertexLights)
{
	doSpecular(VertexLights.x);
	doSpecular(VertexLights.y);
	doSpecular(VertexLights.z);
	doSpecular(VertexLights.w);
}

float computeMicroShadowing(float NoL, float visibility)
{
	// Chan 2018, "Material Advances in Call of Duty: WWII"
	float aperture = rsqrt(1.0 - visibility);
	float microShadow = saturate(NoL * aperture);
	return microShadow * microShadow;
}

// float Shift = 0.035;
// float Alpha[] =
// {
// 	-Shift * 2,
// 	Shift,
// 	Shift * 4,
// };
//
// float B[] =
// {
// 	Area + pow(surf.clampedRoughness,2),
// 	Area + pow(surf.clampedRoughness,2) / 2,
// 	Area + pow(surf.clampedRoughness,2) * 2,
// };
//
// float Hair_g(float B, float Theta)
// {
// 	return exp(-0.5 * Pow2(Theta) / (B * B)) / (sqrt(2 * PI) * B);
// }
//
// void Hair()
// {
// 	//R
// 	float Mp = Hair_g(B[0] * BScale, SinThetaL + SinThetaV - Shift);
// 	// TT
// 	float Mp = Hair_g(B[1], SinThetaL + SinThetaV - Alpha[1]);
// 	//TRT
// 	float Mp = Hair_g(B[2], SinThetaL + SinThetaV - Alpha[2]);
//
// 	const float sa = sin(Alpha[0]);
// 	const float ca = cos(Alpha[0]);
// 	float Shift = 2 * sa * (ca * CosHalfPhi * sqrt(1 - SinThetaV * SinThetaV) + sa * SinThetaV);
// 	float BScale = HairTransmittance.bUseSeparableR ? sqrt(2.0) * CosHalfPhi : 1;
// 	float Mp = Hair_g(B[0] * BScale, SinThetaL + SinThetaV - Shift);
// 	float Np = 0.25 * CosHalfPhi;
// 	float Fp = Hair_F(sqrt(saturate(0.5 + 0.5 * VoL)));
// 	S += Mp * Np * Fp * (GBuffer.Specular * 2) * lerp(1, Backlit,saturate(-VoL));
// }

float4 BgolusSample(SamplerState s)
{
	float2 dx = ddx(input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw);
	float2 dy = ddy(input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw);

	dx *= saturate(0.5 * log2(dot(dx * _MainTex_TexelSize.zw, dx * _MainTex_TexelSize.zw)));
	dy *= saturate(0.5 * log2(dot(dy * _MainTex_TexelSize.zw, dy * _MainTex_TexelSize.zw)));

	float2 uvOffsets = float2(0.125, 0.375);
	float4 offsetUV = float4(0.0, 0.0, 0, _MipBias);;

	offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) + uvOffsets.x * dx + uvOffsets.y * dy;
	float4 mainTexture = _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
	offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) - uvOffsets.x * dx - uvOffsets.y * dy;
	mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
	offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) + uvOffsets.y * dx - uvOffsets.x * dy;
	mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
	offsetUV.xy = (input.uvs.xy * _MainTex_ST.xy + _MainTex_ST.zw) - uvOffsets.y * dx + uvOffsets.x * dy;
	mainTexture += _MainTex.SampleBias(s, offsetUV.xy, offsetUV.w);
	mainTexture *= 0.25;

	float delta_max_sqr = max(dot(dx, dx), dot(dy, dy));
	float mips = max(0.0, 0.5 * log2(delta_max_sqr)) * _MipScale;

	mainTexture.a *= 1 + mips;
	mainTexture.a = saturate(mainTexture.a);
	mainTexture *= _Color;
	return mainTexture;
}

float calculateAlpha(float alpha)
{
	if (_AlphaToMask)
	{
		alpha = (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5;
	}
	else if (_Mode == 1)
	{
		clip(alpha - _Cutoff);
	}
	return alpha;
};