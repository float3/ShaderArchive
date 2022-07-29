Shader "3/GPU Particles Debug 1"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _BufferTex("Buffer",2D) = "white" {}
        [ToggleUI] _Start("Start",float) = 0
        _Test("Test",float) = 0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "GPU Particles.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint id  : SV_VertexID;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.id = v.id;  
                return o;
            }

            float _Test;

            float3 frag(v2f i) : SV_Target
            {
                float4 col = _BufferTex[screenToUV(i.uv) * Dimensions()];
                
                col = i.id;

                col /= 1000;

                return col;
            }
            ENDCG
        }
    }
}