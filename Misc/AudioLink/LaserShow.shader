Shader "Unlit/LaserShow"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Assets/AudioLink/Shaders/AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            #define NOTE_QTY 12
            #define RING_LOC 0.9

            uniform float Amplitudes[NOTE_QTY];
            float Locations[NOTE_QTY] = 
            {
                0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0
            };
            uniform float Advance;

            float3 fract(float3 x)
            {
                return x - floor(x);
            }

            float3 HSVToRGB(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            float3 AngleToRGB(float angle, float val)
            {
                float Hue;
                Hue = (1.0 - step(4.0 / 12.0, angle)) * ((1.0 / 3.0) - angle) * 0.5;// Yellow -> Red
                Hue += (step(4.0 / 12.0, angle) - step(8.0 / 12.0, angle)) * (1 - (angle - (1.0 / 3.0)));// Red -> Blue
                Hue += step(8.0 / 12.0, angle) * ((2.0 / 3.0) - (1.5 * (angle - (2.0 / 3.0))));// Blue -> Yellow
                return HSVToRGB(float3(Hue, 1.0, val));
            }

            float4 main(float2 uv)
            {
                // Information about this pixel
                //float Angle = (atan(-TexCoord.x, -TexCoord.y) + 3.1415926535) / 6.2831853071795864;
                //Angle = mod(Angle + Advance, 1.0);
                float Radius = distance(0.0, uv);

                float3 Colour = 0.0;

                for (int i = 0; i < NOTE_QTY; i++)
                {
                    float2 LineStart = float2(sin(Locations[i] * 6.2831853071795864), cos(Locations[i] * 6.2831853071795864)) * RING_LOC;
                    float2 LineEnd = -LineStart;
                    float2 LineDir = normalize(LineStart);
                    float Distance = distance((0.0), LineDir * dot(uv, LineDir));
                    Colour += AngleToRGB(Locations[i], 1.0) * max(0.5 - sqrt(Distance), 0.0) * AudioLinkGetAmplitudeAtNote(i) * 2.5;
                }

                return float4(Colour, 1.0);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = 0;
                col.xyz = main(i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
