Shader "MeshParticles/ScreenVertPos"
{
    Properties
    {
        [IntRange] _Width ("Texture Size (POT)", Range(0, 13)) = 7
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
            #pragma geometry geom

            #include "UnityCG.cginc"

            bool _Start;
            Texture2D_float<float4> _BufferTex;
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_TexelSize;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float3 color : COLOR;
                float4 originalPos : TEXCOORD1;
            };

            uint _Width;

            v2f vert(float4 vertex : POSITION)
            {
                v2f o;
                o.vertex = vertex;
                o.color = 0;
                o.originalPos = vertex;
                o.screenPos = ComputeGrabScreenPos(UnityObjectToClipPos(vertex));
                return o;
            }

            float4 pixelToClipPos(float2 pixelPos)
            {
                float4 pos = float4((pixelPos + .5) / _ScreenParams.xy, 0.5, 1);
                pos.xy = pos.xy * 2 - 1;
                pos.y = -pos.y;
                return pos;
            }

            [maxvertexcount(12)]
            void geom(triangle v2f input[3], inout TriangleStream<v2f> triStream, uint triID : SV_PrimitiveId)
            {
                float width = 1 << _Width;
                float2 quadSize = float2(2.0 / width, 0);

                for (uint i = 0; i < 3; i++)
                {
                    uint id = triID * 3 + i;
                    uint2 coord = uint2(id % width, id / width);
                    float3 pos = float3(((coord.xy / width) - 0.5) * 2.0, 1);


                    v2f o;


                    o.color = input[i].vertex;
                    o.originalPos = input[i].vertex;

                    if (_Start)
                    {
                        uint2 coords = coord;
                        coords.y = width - coord.y - 1;

                        o.color = _BufferTex[coords];
                    }
                    o.screenPos = input[i].screenPos;


                    o.vertex = float4(pos + quadSize.xxy, 1);
                    triStream.Append(o);

                    o.vertex = float4(pos + quadSize.yxy, 1);
                    triStream.Append(o);

                    o.vertex = float4(pos + quadSize.xyy, 1);
                    triStream.Append(o);

                    o.vertex = float4(pos + quadSize.yyy, 1);
                    triStream.Append(o);
                    triStream.RestartStrip();
                }
            }

            float4 frag(v2f i) : SV_Target
            {
                float rawDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;

                float4 worldPos = mul(unity_ObjectToWorld, i.color);
                float4 viewpos = mul(UNITY_MATRIX_V, worldPos);

                if (abs(LinearEyeDepth(rawDepth) - abs(viewpos.z)) < 0.1)
                {
                    i.color = i.color + i.color * 0.02;
                }
                else
                {
                    i.color = lerp(i.originalPos, i.color, 0.9);
                }

                return float4(i.color, 1.0);
            }
            ENDCG
        }
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            uint _Width;
            Texture2D_float<float4> _BufferTex;
            bool _Start;

            sampler2D_float _CameraDepthTexture;
            float4 _CameraDepthTexture_TexelSize;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.screenPos = 0;
                return o;
            }

            [maxvertexcount(12)]
            void geom(triangle v2f input[3], inout TriangleStream<v2f> triStream, uint triID : SV_PrimitiveId)
            {
                float width = 1 << _Width;
                float2 quadSize = float2(2.0 / width, 0);

                for (uint i = 0; i < 3; i++)
                {
                    uint id = triID * 3 + i;
                    uint2 coord = uint2(id % width, id / width);
                    float3 pos = float3(((coord.xy / width) - 0.5) * 2.0, 0);

                    v2f o;

                    uint2 coords = coord;
                    coords.y = width - coord.y - 1;
                    o.uv = input[i].uv;

                    o.vertex = UnityObjectToClipPos(_BufferTex[coords]);
                    o.screenPos = ComputeGrabScreenPos(o.vertex);

                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            float4 frag(v2f i) : SV_Target
            {
                float rawDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;


+                return abs(LinearEyeDepth(rawDepth));

                return tex2D(_MainTex, i.uv);;
            }
            ENDCG
        }
    }
}