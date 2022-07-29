Shader "3/GPU Particles Buffer"
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
            Tags
            {
                "LightMode"="Vertex"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "GPU Particles.cginc"
            #include "GPU Particles Buffer.cginc"

            ENDCG
        }
//        Pass
//        {
//            Tags
//            {
//                "LightMode" = "ForwardBase"
//            }
//
//            CGPROGRAM
//            #pragma vertex vert
//            #pragma fragment frag
//            #pragma geometry geom
//
//            #include "UnityCG.cginc"
//            #include "GPU Particles.cginc"
//
//            struct appdata
//            {
//                float4 vertex : POSITION;
//                float2 uv : TEXCOORD0;
//            };
//
//            v2f vert(appdata v)
//            {
//                v2f o = (v2f)0;
//
//                o.vertex = v.vertex;
//                o.oPos = v.vertex;
//                o.uv = v.uv;
//                return o;
//            }
//
//            [maxvertexcount(3)]
//            void geom(triangle v2f IN[3], inout TriangleStream<v2f> triStream, uint triID : SV_PrimitiveID)
//            {
//                v2f o;
//
//                for(int i = 0; i < 3; i++)
//                {
//                    o = IN[i];
//                    float4 lastframe = _BufferTex[screenToUV(IN[i].uv) * Dimensions()];
//                    if(lastframe.a < 0.5)
//                    {
//                        triStream.Append(o);
//                        continue;
//                    }
//                    o.vertex = UnityObjectToClipPos(lastframe.a < 0.5 ? IN[i].vertex : lastframe);
//                    triStream.Append(o);
//                }
//            }
//
//            float3 frag(v2f i) : SV_Target
//            {
//                float3 col = tex2D(_MainTex, i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw).rgb;
//                return col;
//            }
//            ENDCG
//        }
    }
}