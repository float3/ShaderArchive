Shader "3/GPU Particles Render"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_BufferTex("Buffer",2D) = "white" {}
	}
	SubShader
	{
		Tags
		{
			"RenderType"="Opaque"
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

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
				float4 oPos : TEXCOORD1;
				float4 deltaPos : TEXCOORD2;

			};

			Texture2D_float<float4> _BufferTex;
			Texture2D_float _MainTex;
			uniform float _Zero;


			v2f vert(appdata v)
			{
				v2f o;

				float4 lastframe = _BufferTex[v.uv * 1024];
				o.deltaPos = v.vertex - lastframe;
				v.vertex.xyz += o.deltaPos;


				o.vertex = UnityObjectToClipPos(v.vertex);
				o.oPos = v.vertex;
				o.uv = v.uv;
				return o;
			}


			float4 frag(v2f i) : SV_Target
			{
				float4 lastframe = _BufferTex[i.uv * 1024];
				if(any(lastframe + _Zero < 0))
				{
					return float4(1,0,0,1);
				}
				float4 col = _MainTex[i.uv * 2048];
				return i.deltaPos;
			}
			ENDCG
		}
	}
}