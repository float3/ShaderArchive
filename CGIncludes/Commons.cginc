#ifndef COMMON_INCLUDED
#define COMMON_INCLUDED

#pragma warning (default : 3206) // implicit truncation

//this needs to match you camera_res_height in the config.json file
#define VRC_CONFIG_CAMERA_RESOLUTION 2160

//from Scruffy
bool isVR()
{
	// USING_STEREO_MATRICES
	#if UNITY_SINGLE_PASS_STEREO
	return true;
	#else
	return false;
	#endif
}

//UNITY_MATRIX_P._13 < 0 left eye, UNITY_MATRIX_P._13 > 0 right eye & UNITY_MATRIX_P._13 == 0 not vr
bool isLeftEye()
{
	return UNITY_MATRIX_P._13 < 0;
}

bool isRightEye()
{
	return UNITY_MATRIX_P._13 > 0;
}

bool isNotVr()
{
	return UNITY_MATRIX_P._13 == 0;
}

bool isOrtho()
{
	return unity_OrthoParams.w == 1 || UNITY_MATRIX_P[3][3] == 1;
}

float verticalFOV()
{
	return 2.0 * atan(1.0 / unity_CameraProjection._m11) * 180.0 / UNITY_PI;
}

// this checks if the shader is being rendered by a reflection probe
// I don't know how check for box projection if that's even possible
bool isReflectionProbe()
{
	return UNITY_MATRIX_P[0][0] == 1 && unity_CameraProjection._m11 == 1;
}

bool isVRHandCamera()
{
	return !isVR() && abs(UNITY_MATRIX_V[0].y) > 0.0000005;
}

bool isDesktop()
{
	return !isVR() && abs(UNITY_MATRIX_V[0].y) < 0.0000005;
}

bool isVRHandCameraPreview()
{
	return isVRHandCamera() && _ScreenParams.y == 720;
}

bool isVRHandCameraPicture()
{
	return isVRHandCamera() && _ScreenParams.y != 720;
}

bool isVRHandCameraPictureAnyResolution()
{
	if (_ScreenParams.y == 1080 || _ScreenParams.y == 2160 || _ScreenParams.y == 1440 || _ScreenParams.y == 720)
	{
		return isVRHandCamera();
	}
	return false;
}

bool isPanorama()
{
	// Crude method
	// FOV=90=camproj=[1][1]
	return unity_CameraProjection[1][1] == 1 && _ScreenParams.x == 1075 && _ScreenParams.y == 1025;
}

bool IsInMirror()
{
	return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

bool IsNan_float(float In)
{
	return In < 0.0 || In > 0.0 || In == 0.0 ? 0 : 1;
}

bool IsNan_float(float2 In)
{
	return any(In < 0.0) || any(In > 0.0) || any(In == 0.0) ? 0 : 1;
}

bool IsNan_float(float3 In)
{
	return any(In < 0.0) || any(In > 0.0) || any(In == 0.0) ? 0 : 1;
}

bool IsNan_float(float4 In)
{
	return any(In < 0.0) || any(In > 0.0) || any(In == 0.0) ? 0 : 1;
}

#ifdef USING_STEREO_MATRICES
#define _WorldSpaceStereoCameraCenterPos lerp(unity_StereoWorldSpaceCameraPos[0], unity_StereoWorldSpaceCameraPos[1], 0.5)
#else
#define _WorldSpaceStereoCameraCenterPos _WorldSpaceCameraPos
#endif

//from kaj https://github.com/DarthShader/Kaj-Unity-Shaders/blob/master/Shaders/Kaj/KajCore.cginc#L1039-L1101
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

//invert matrix
float4x4 inverse(float4x4 input)
{
	#define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
	//determinant(float3x3(input._22_23_23, input._32_33_34, input._42_43_44))

	const float4x4 cofactors = float4x4(
		minor(_22_23_24, _32_33_34, _42_43_44),
		-minor(_21_23_24, _31_33_34, _41_43_44),
		minor(_21_22_24, _31_32_34, _41_42_44),
		-minor(_21_22_23, _31_32_33, _41_42_43),

		-minor(_12_13_14, _32_33_34, _42_43_44),
		minor(_11_13_14, _31_33_34, _41_43_44),
		-minor(_11_12_14, _31_32_34, _41_42_44),
		minor(_11_12_13, _31_32_33, _41_42_43),

		minor(_12_13_14, _22_23_24, _42_43_44),
		-minor(_11_13_14, _21_23_24, _41_43_44),
		minor(_11_12_14, _21_22_24, _41_42_44),
		-minor(_11_12_13, _21_22_23, _41_42_43),

		-minor(_12_13_14, _22_23_24, _32_33_34),
		minor(_11_13_14, _21_23_24, _31_33_34),
		-minor(_11_12_14, _21_22_24, _31_32_34),
		minor(_11_12_13, _21_22_23, _31_32_33)
	);
	#undef minor
	return transpose(cofactors) / determinant(input);
}

float3 clampLength(float3 v, float l)
{
	return v * min(rsqrt(dot(v, v)) * l, 1);
}

float3 setLength(float3 v, float l)
{
	return v * (rsqrt(dot(v, v)) * l);
}

float3 setLength(float3 v)
{
	return v * (rsqrt(dot(v, v)) * 1);
}

float4 setLength(float4 v)
{
	return v * (rsqrt(dot(v, v)) * 1);
}

float3 setLengthFastSafe(float3 v, float l)
{
	return v * min(1e30, rsqrt(dot(v, v)) * l);
}

float3 fastPosMatMul(float4x4 m, float3 pos)
{
	return m._14_24_34 + m._11_12_13 * pos.x + m._21_22_23 * pos.y + m._31_32_33 * pos.z;
}

//from me
float4x4 worldToViewMatrix()
{
	return UNITY_MATRIX_V;
}

float4x4 viewToWorldMatrix()
{
	return UNITY_MATRIX_I_V;
}

float4x4 viewToClipMatrix()
{
	return UNITY_MATRIX_P;
}

float4x4 clipToViewMatrix()
{
	return inverse(UNITY_MATRIX_P);
}

float4x4 worldToClipMatrix()
{
	return UNITY_MATRIX_VP;
}

float4x4 clipToWorldMatrix()
{
	return inverse(UNITY_MATRIX_VP);
}

float4x4 lookAt(float3 Eye, float3 Center, float3 Up)
{
	float4x4 Matrix;

	float3 X, Y, Z;

	Z = Eye - Center;
	Z = normalize(Z);
	Y = Up;
	X = cross(Y, Z);
	Y = cross(Z, X);

	X = normalize(X);
	Y = normalize(Y);

	Matrix[0][0] = X.x;
	Matrix[1][0] = X.y;
	Matrix[2][0] = X.z;
	Matrix[3][0] = dot(-X, Eye);
	Matrix[0][1] = Y.x;
	Matrix[1][1] = Y.y;
	Matrix[2][1] = Y.z;
	Matrix[3][1] = dot(-Y, Eye);
	Matrix[0][2] = Z.x;
	Matrix[1][2] = Z.y;
	Matrix[2][2] = Z.z;
	Matrix[3][2] = dot(-Z, Eye);
	Matrix[0][3] = 0;
	Matrix[1][3] = 0;
	Matrix[2][3] = 0;
	Matrix[3][3] = 1.0f;

	return Matrix;
}

// clips vec so that it can't be at a angle greater than 90 facing away from the view plane
float3 clipVec(float3 v, float3 r )
{
	float k = dot(v,r);
	return (k>0.0) ? v : (v-r*k)* rsqrt(1.0-k*k/dot(v,v));
}

float4 GetWorldPositionFromDepthValue(float2 uv, float linearDepth)
//Getting the World Coordinate Position by Depth
{
	float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;

	float height = 2 * camPosZ / unity_CameraProjection._m11;
	float width = _ScreenParams.x / _ScreenParams.y * height;

	float camPosX = width * uv.x - width / 2;
	float camPosY = height * uv.y - height / 2;
	float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
	return mul(unity_CameraToWorld, camPos);
}

float3 point_quat_rotate( float3 v, float4 quaternion)
{ 
	return v + 2.0 * cross(quaternion.xyz, cross(quaternion.xyz, v) + quaternion.w * v);
}

float2x2 rot(float angle)
{
	return float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float GetClipDepthFromDepthValue(float2 uv, float linearDepth)
//Getting the World Coordinate Position by Depth
{
	float4 world = GetWorldPositionFromDepthValue(uv,linearDepth);
	return UnityWorldToClipPos(world.xyz).z;
}

//I don't know how to reverse the density if Fog is linear
float getFogDensity()
{
	#ifdef FOG_EXP2
	return unity_FogParams.x * sqrt(log(2));
	#endif

	#ifdef FOG_EXP
	return unity_FogParams.y * log(2);
	#endif
	return 0;
};


// blend between two directions by %
// https://www.shadertoy.com/view/4sV3zt
// https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/
float3 slerp(float3 start, float3 end, float percent)
{
	float d     = dot(start, end);
	d           = clamp(d, -1.0, 1.0);
	float theta = acos(d)*percent;
	float3 RelativeVec  = normalize(end - start*d);
	return      ((start*cos(theta)) + (RelativeVec*sin(theta)));
}

/*
float3 LightOrCameraRayToObject(float3 objectPos)
{
	if (UNITY_MATRIX_P[3][3] == 1.0)
	{
		return WorldToObjectNormal(-UNITY_MATRIX_V[2].xyz);
	}
	else
	{
		return objectPos - WorldToObjectPos(UNITY_MATRIX_I_V._m03_m13_m23);
	}
}
*/


// https://github.com/Xiexe/Xiexes-Unity-Shaders/blob/2bade4beb87e96d73811ac2509588f27ae2e989f/Main/CGIncludes/XSHelperFunctions.cginc#L120
half2 calcScreenUVs(float4 screenPos)
{
	half2 uv = screenPos.xy / (screenPos.w + 0.0000000001);
	#if UNITY_SINGLE_PASS_STEREO
	uv.xy *= half2(_ScreenParams.x * 2, _ScreenParams.y);
	#else
	uv.xy *= _ScreenParams.xy;
	#endif
    
	return uv;
}

inline half Dither8x8Bayer(int x, int y)
{
	const half dither[64] = {
		1, 49, 13, 61, 4, 52, 16, 64,
		33, 17, 45, 29, 36, 20, 48, 32,
		9, 57, 5, 53, 12, 60, 8, 56,
		41, 25, 37, 21, 44, 28, 40, 24,
		3, 51, 15, 63, 2, 50, 14, 62,
		35, 19, 47, 31, 34, 18, 46, 30,
		11, 59, 7, 55, 10, 58, 6, 54,
		43, 27, 39, 23, 42, 26, 38, 22
	};
	int r = y * 8 + x;
	return dither[r] / 65; // Use 65 instead of 64 to get better centering
}

half applyDithering(half alpha, float4 screenPos, half spacing)
{
	half2 screenuv = calcScreenUVs(screenPos).xy;
	half dither = Dither8x8Bayer(fmod(screenuv.x, 8), fmod(screenuv.y, 8));
	return alpha + (0.5 - dither)/spacing;
}

#endif
