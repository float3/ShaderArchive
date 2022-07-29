Shader "3/TensionMap"
{
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
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"


			struct appdata
			{
				centroid float4 vertex : POSITION;
				centroid float2 uv : TEXCOORD0;
			};

			struct v2g
			{
				centroid float4 vertex : POSITION;
				centroid float2 uv : TEXCOORD0;
			};

			struct g2f
			{
				centroid float4 vertex : SV_POSITION;
				centroid float2 uv : TEXCOORD0;
				nointerpolation float4 data : TEXCOORD1;
				nointerpolation uint primitiveID : TEXCOORD2;
			};


			v2g vert(appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = v.uv;
				return o;
			}

			[maxvertexcount(3)]
			void geom(triangleadj v2g input[6], inout TriangleStream<g2f> outStream, uint fragID : SV_PrimitiveID)
			{
				g2f o;
				o.primitiveID = fragID;
				// First Tri
				float a = distance(input[0].vertex, input[1].vertex);
				float b = distance(input[1].vertex, input[2].vertex);
				float c = distance(input[2].vertex, input[0].vertex);
				float Perimeter = (a + b + c) / 2.0;
				float Area = sqrt(Perimeter * (Perimeter - a) * (Perimeter - b) * (Perimeter - c));
				float3 Center = (input[0].vertex + input[1].vertex + input[2].vertex) / 3.0;
				Center = UnityObjectToClipPos(Center);
				o.data = float4(Center, Area);
				for (int i = 0; i < 3; i++)
				{
					o.vertex = UnityObjectToClipPos(input[i].vertex);
					o.uv = input[i].uv;
					outStream.Append(o);
				}
				outStream.RestartStrip();
			}

			float4 frag(g2f i) : SV_Target
			{
				return float4(i.data.aaa, 1.0);
			}
			ENDCG
		}
	}
}