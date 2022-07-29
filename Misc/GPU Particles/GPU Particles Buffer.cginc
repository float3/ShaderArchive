struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    uint id : SV_VertexID;
};


// v2f vert(appdata v)
// {
//     v2f o;
//     o.vertex = float4(uvToScreen(v.uv), 1, 1);
//
//     float4 lastframe = _BufferTex[v.uv * Dimensions()];
//
//     o.deltaPos = v.vertex + normalize(v.normal) * (sin(_Time.y));
//
//     o.oPos = v.vertex; // + o.deltaPos;
//
//     o.id = v.id;
//
//
//     o.uv = v.uv;
//     return o;
// }

v2f vert(appdata v)
{
    v2f o = (v2f)0;
    o.vertex = v.vertex;
    o.oPos = v.vertex;
    o.id = v.id;
    o.uv = v.uv;
    return o;
}

[maxvertexcount(3)]
void geom(triangle v2f IN[3], inout TriangleStream<v2f> triStream, uint triID : SV_PrimitiveID)
{
    v2f o;

    o = IN[0];

    o.vertex.x = (IN[0].id - 1) / TEXSIZE;
    o.vertex.y = 1 - (1 / TEXSIZE);

    triStream.Append(o);

    o = IN[1];

    o.vertex.x = (IN[1].id + 1) / TEXSIZE;
    o.vertex.y = 1 - (1 / TEXSIZE);

    triStream.Append(o);

    o = IN[2];

    o.vertex.x = (IN[2].id + 1) / TEXSIZE;
    o.vertex.y = 1 + (1 / TEXSIZE);

    triStream.Append(o);
}


float4 frag(v2f i) : SV_Target
{
    float3 re;
    if (!_Start)
    {
        re = i.oPos;
    }
    else
    {
        re = i.deltaPos;
    }
    return float4(re, 1);
}
