Shader "3/GPU Particles Debug"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _BufferTex("Buffer",2D) = "white" {}
        [ToggleUI] _Start("Start",float) = 0
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
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f) 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float3 frag(v2f i) : SV_Target
            {
                float4 col = _BufferTex[i.uv * Dimensions()];
                return col;
            }
            ENDCG
        }
    }
}