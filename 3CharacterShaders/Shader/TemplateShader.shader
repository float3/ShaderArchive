Shader "CharacterShaders/TemplateShader"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

        _Glossiness("Smoothness", Range(0, 1)) = 0
        _Reflectance("Reflectance", Range(0, 1)) = 0
        [Gamma] _Metallic("Metallic", Range(0, 1)) = 0
        _Occlusion("Occlusion", Range(0, 1)) = 1

        _MetallicGlossMap("Metallic", 2D) = "white" {}

        [ToggleUI] _SpecularHighlights("Specular Highlights", Float) = 1
        [ToggleUI] _GlossyReflections("Glossy Reflections", Float) = 1

        [ToggleUI] _Aniso ("Anisotropy", Int) = 0
        _Anisotropy ("Anisotropy", Range(-1,1)) = 0



        [ToggleUI] _Debug("Debug", float) = 0

		
        
        [HideInInspector] [NonModifiableTextureData] [NoScaleOffset] _DFG ("DFG Lut", 2D) = "black" {}



        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Blend Op Alpha", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha ("Alpha Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendAlpha ("Alpha Destination Blend", Int) = 0

        [Enum(Off, 0, On, 1)] _ZWrite ("Zwrite", Float) = 1
        // [Enum(True, 0, False, 1)] _ZClip ("ZClip", Float) = 1 // ZClip is broken don't use it
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4

        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
        [Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage", Int) = 0

        _OffsetFactor("Offset Factor", Float) = 0
        _OffsetUnits("Offset Units", Float) = 0

        [Enum(_3CharacterShaders.Editor.ColorMask)] _ColorMask("Color Mask", Int) = 15

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
    //#pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING DIRLIGHTMAP_COMBINED SHADOWS_SHADOWMASK
    ENDCG

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "PerformanceChecks"="False" "Queue"="Geometry"
        }
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
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            AlphaToMask [_AlphaToMask]
            Blend [_SrcBlend] [_DstBlend], [_SrcBlendAlpha] [_DstBlendAlpha]
            BlendOp [_BlendOp], [_BlendOpAlpha]
            ColorMask [_ColorMask]
            Cull [_Cull]
            Offset [_OffsetFactor], [_OffsetUnits]
            // ZClip [_ZClip]
            ZTest [_ZTest]
            ZWrite [_ZWrite]


            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag
            #include "../CGincs/Core.cginc"
            ENDCG
        }
        // ------------------------------------------------------------------
        //	
        Pass
        {
            Name "FORWARD_DELTA"
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            AlphaToMask [_AlphaToMask]
            Blend [_SrcBlend] One, [_SrcBlend] One
            BlendOp [_BlendOp], [_BlendOpAlpha]
            ColorMask [_ColorMask]
            Cull [_Cull]
            Fog
            {
                Color (0,0,0,0)
            }
            Offset [_OffsetFactor], [_OffsetUnits]
            // ZClip [_ZClip]
            ZTest [_ZTest]
            ZWrite Off


            CGPROGRAM
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag
            #include "../CGincs/Core.cginc"
            ENDCG
        }
        // ------------------------------------------------------------------
        //
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            AlphaToMask Off
            Cull [_Cull]
            Offset [_OffsetFactor], [_OffsetUnits]
            // ZClip [_ZClip]
            ZTest LEqual
            ZWrite On

            CGPROGRAM
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #pragma vertex vert
            #pragma fragment frag

            #include "../CGincs/Core.cginc"
            ENDCG
        }

    }
    CustomEditor "_3CharacterShaders.Editor.CharacterShadersGUI"
}