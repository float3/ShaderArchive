#ifndef CHARACTERSHADERS_MESHDATA_INCLUDED
#define CHARACTERSHADERS_MESHDATA_INCLUDED


struct Mesh
{
    float3 normal;
    float4 tangent;
    float3 bitangent;
    float3x3 tangentToWorld;
};


Mesh CalculateMeshData(float3 normal, float4 tangent, bool facing)
{
    Mesh meshData;
    #ifdef DOUBLESIDED
    UNITY_BRANCH
    if (!facing)
    {
        normal *= -1;
        tangent *= -1;
    }
    #endif
    meshData.normal = normal; // clipIfNeg(normal, CalculateViewDirection(worldPos)); // TODO:
    meshData.tangent = tangent;
    meshData.bitangent = cross(tangent.xyz, normal) * (tangent.w * unity_WorldTransformParams.w);
    meshData.tangentToWorld = float3x3(tangent.xyz, meshData.bitangent, normal);
    return meshData;
}

#endif
