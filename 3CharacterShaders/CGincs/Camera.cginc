#ifndef CHARACTERSHADERS_CAMERA_INCLUDED
#define CHARACTERSHADERS_CAMERA_INCLUDED

struct Camera
{
    float NoV;
    float3 viewDir;
};

bool isOrtho()
{
    return unity_OrthoParams.w == 1 || UNITY_MATRIX_P[3][3] == 1;
}

float3 CalculateViewDirection(float3 worldPos)
{
    return !isOrtho()
               ? normalize(_WorldSpaceCameraPos - worldPos)
               : normalize(UNITY_MATRIX_I_V._m02_m12_m22);
}

Camera GetCamera(float3 worldPos, float3 normal)
{
    Camera cameraData;
    cameraData.viewDir = CalculateViewDirection(worldPos);
    cameraData.NoV = dot(cameraData.viewDir, normal);
    return cameraData;
}
#endif
