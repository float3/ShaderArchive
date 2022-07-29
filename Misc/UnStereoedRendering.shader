Shader "3/Unstereo"
{
    Properties
    {
        [Enum(Left, 0, Right, 1)] _Eye ("Which Eye do you want to render", Float) = 0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform int _Eye;

            v2f vert(appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                if (UNITY_MATRIX_P._13 == 0)
                {
                    o.vertex = asfloat(-1);
                }
                else
                {
                    o.vertex = float4(float2(1, -1) * (v.uv * 2 - 1), 1, 1); //stretch across screen

                    if (_Eye == 0 && UNITY_MATRIX_P._13 < 0) //Left
                    {
                        o.vertex = asfloat(-1);
                    }

                    if (_Eye == 1 && UNITY_MATRIX_P._13 > 0) //Right
                    {
                        o.vertex = asfloat(-1);
                    }
                }

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return float4(0, 0, 0, 1);
            }
            ENDCG
        }
    }
}