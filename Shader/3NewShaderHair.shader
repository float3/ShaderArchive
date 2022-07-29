Shader "3/NewShader Hair"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}

		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0
		_MipScale("Mip Scale", Range(0, 1)) = 0
		_MipBias("Mip Bias", Range(0, 1)) = 0
		_DitherGradient ("Dither Gradient", Range(0, 1)) = 0

		_Glossiness("Smoothness", Range(0, 1)) = 0
		_Reflectance("Reflectance", Range(0.35, 1)) = 0

		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

		[ToggleUI] _SpecularHighlights("Specular Highlights", Float) = 1
		[ToggleUI] _GlossyReflections("Glossy Reflections", Float) = 1

		[ToggleUI] _Aniso ("Anisotropy", Int) = 0
		_Anisotropy ("Anisotropy", Range(-1,1)) = 0

		_BumpScale("Scale", Float) = 1
		[Normal] _BumpMap("Normal Map", 2D) = "bump" {}

		_Occlusion("Strength", Range(0, 1)) = 1
		_OcclusionMap("Occlusion", 2D) = "white" {}

		[ToggleUI] _Emission("Emission", Float) = 0
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		[ToggleUI] _AudioLink("AudioLink", Float) = 0

		[Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0

		[ToggleUI] _DontRender ("Don't Render", Float) = 0
		[ToggleUI] _NotInMirror ("In Mirror", Float) = 0
		[ToggleUI] _NotOutMirror ("Out Mirror", Float) = 0

		[ToggleUI] _Skin ("Skin", Float) = 0
		
        [ToggleUI]_FreckleMask("Freckle Mask", Int) = 0
        _FrecklesLocation("Freckle Location", Vector) = (0,1,0,1)
		_FrecklesScale("Freckle Scale", Float) = 400
		_FrecklesSize("Freckle Size", Range(0,1)) = 0.3
		_FrecklesRandomness("Freckle Randomness Seed", Range(-10,10)) = 1
		_FrecklesAmount("Freckle Amount", Range(0,1)) = 0.1
        _FrecklesRoundness("Freckle Roundness", Range(0,2)) = 1

		[ToggleUI] _Cloth ("Cloth", Float) = 0
		_Wrap("Wrap", Range(0, 2)) = 0
		_Generalised("Valve Generalised", Range(0, 1)) = 0

		[ToggleUI] _hasLoaded ("Loaded", Float) = 0
		[ToggleUI] _isFriend ("isFriend", Float) = 0
		[ToggleUI] _isLocal ("Local", Float) = 0

		[HideInInspector] [NonModifiableTextureData] [NoScaleOffset] _DFG ("DFG Lut", 2D) = "black" {}

		
		// Blending state
		[Enum(Opaque,0,Cutout,1,Fade,2,Transparent,3)] _Mode ("Mode", Float) = 0.0

		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Op", Int) = 0
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Blend Op Alpha", Int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha ("Alpha Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendAlpha ("Alpha Destination Blend", Int) = 0

		[Enum(Off, 0, On, 1)] _ZWrite ("Zwrite", Float) = 1
		[Enum(True, 0, False, 1)] _ZClip ("ZClip", Float) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4

		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
		[Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage", Int) = 0
		_OffsetFactor("Offset Factor", Float) = 0
		_OffsetUnits("Offset Units", Float) = 0

		[Enum(_3.ColorMask)] _ColorMask("Color Mask", Int) = 15

		[IntRange] _Stencil ("Reference Value", Range(0, 255)) = 0
		[IntRange] _StencilWriteMask ("ReadMask", Range(0, 255)) = 255
		[IntRange] _StencilReadMask ("WriteMask", Range(0, 255)) = 255

		[Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Pass Op", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Fail Op", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("ZFail Op", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Compare Function", Int) = 8
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilPassFront ("Front Pass Op", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFailFront ("Front Fail Op", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailFront ("Front ZFail Op", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompFront ("Front Compare Function", Int) = 8
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilPassBack ("Back Pass Op", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFailBack ("Back Fail Op", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailBack ("Back ZFail Op", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompBack ("Back Compare Function", Int) = 8
	}

	CGINCLUDE
	#pragma target 5.0
	#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING DIRLIGHTMAP_COMBINED SHADOWS_SHADOWMASK
	#define HAIR
	//#pragma enable_d3d11_debug_symbols
	ENDCG


	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" "Queue"="Geometry" "VRCFallback" = "Hidden" }
		AlphaToMask Off
		ColorMask [_ColorMask]
		Cull [_Cull]
		Offset [_OffsetFactor], [_OffsetUnits]
		ZTest [_ZTest]
		//ZClip [_ZClip]
		// ------------------------------------------------------------------
		//
		Stencil
		{
			Ref [_Stencil]
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
			Comp [_StencilComp]
			Pass [_StencilPass]
			Fail [_StencilFail]
			ZFail [_StencilZFail]
			CompBack [_StencilCompBack]
		    PassBack [_StencilPassBack]
		    FailBack [_StencilFailBack]
		    ZFailBack [_StencilZFailBack]
		    CompFront [_StencilCompFront]
		    PassFront [_StencilPassFront]
		    FailFront [_StencilFailFront]
		    ZFailFront [_StencilZFailFront]
		}
		// ------------------------------------------------------------------
		//
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Blend [_SrcBlend] [_DstBlend], [_SrcBlendAlpha] [_DstBlendAlpha]
			BlendOp [_BlendOp], [_BlendOpAlpha]
			ZWrite [_ZWrite]

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile _ VERTEXLIGHT_ON
			//#pragma multi_compile_instancing

			#pragma vertex vert
			#pragma fragment frag
			#include "../CGIncludes/Pass.cginc"
			ENDCG
		}
		// ------------------------------------------------------------------
		//
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One, [_SrcBlend] One
			BlendOp [_BlendOp], [_BlendOpAlpha]
			Fog { Color (0,0,0,0) }
			ZWrite Off


			CGPROGRAM
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			//#pragma multi_compile_instancing

			#pragma vertex vert
			#pragma fragment frag
			#include "../CGIncludes/Pass.cginc"
			ENDCG
		}
		// ------------------------------------------------------------------
		//
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			AlphaToMask Off
			ZTest LEqual
			ZWrite On

			CGPROGRAM
			#pragma multi_compile_shadowcaster
			//#pragma multi_compile_instancing
			
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

			#pragma vertex vert
			#pragma fragment frag

			#include "../CGIncludes/shadow.cginc"
			ENDCG
		}
	}
}