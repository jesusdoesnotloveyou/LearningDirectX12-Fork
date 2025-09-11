//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************
 
//cbuffer cbPerObject : register(b0)
//{
//	float4x4 gWorld; 
//};

#define MaxLights 16

#ifndef NUM_DIR_LIGHTS
    #define NUM_DIR_LIGHTS 3
#endif

struct Light
{
    float3 Strength;
    float FalloffStart; // point/spot light only
    float3 Direction;   // directional/spot light only
    float FalloffEnd;   // point/spot light only
    float3 Position;    // point/spot light only
    float SpotPower;
};

cbuffer cbPerObject : register(b0)
{
    float m00;
    float m01;
    float m02;
    float m03;
    float m10;
    float m11;
    float m12;
    float m13;
    float m20;
    float m21;
    float m22;
    float m23;
    float m30;
    float m31;
    float m32;
    float m33;
};

cbuffer cbPass : register(b1)
{
    float4x4 gView;
    float4x4 gInvView;
    float4x4 gProj;
    float4x4 gInvProj;
    float4x4 gViewProj;
    float4x4 gInvViewProj;
    float3 gEyePosW;
    float cbPerObjectPad1;
    float2 gRenderTargetSize;
    float2 gInvRenderTargetSize;
    float gNearZ;
    float gFarZ;
    float gTotalTime;
    float gDeltaTime;
    
    float4 gAmbient;
    
    Light gLights[MaxLights];
};

cbuffer cbPerMaterial : register(b2)
{
    float4 DiffuseAlbedo;
    float3 FresnelR0;
    float Roughness;
    float4x4 MatTransform;
}

struct VertexIn
{
	float3 PosL  : POSITION;
    float3 Normal : NORMAL;
};

struct VertexOut
{
	float4 PosH  : SV_POSITION;
    float3 PosW : POSITION;
    float3 NormalW : NORMAL;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;
	
	// Transform to homogeneous clip space.
    float4x4 gWorld = float4x4(m00, m01, m02, m03,
                               m10, m11, m12, m13,
                               m20, m21, m22, m23,
                               m30, m31, m32, m33);
    
    vout.PosW = mul(float4(vin.PosL, 1.0f), gWorld).xyz;
    vout.PosH = mul(float4(vout.PosW, 1.0f), gViewProj);
	
	// Just pass vertex color into the pixel shader.
    vout.NormalW = mul(vin.Normal, (float3x3)gWorld);
    
    return vout;
}

float3 ComputeDirLight(Light gLight, float3 normal)
{
    float3 lightDir = normalize(gLight.Direction);
    float NdotL = max(dot(lightDir, normal), 0.f);
    return gLight.Strength * NdotL;
}

float4 PS(VertexOut pin) : SV_Target
{
    float3 N = normalize(pin.NormalW);
    
    float4 ambient = gAmbient * DiffuseAlbedo;
    float4 litColor = ambient;
    
#if NUM_DIR_LIGHTS
    
    float3 dirLight = 0.0f;
    
    [unroll]
    for (int i = 0; i < NUM_DIR_LIGHTS; i++)
    {
        dirLight += ComputeDirLight(gLights[i], N);
    }
    
    litColor += float4(dirLight, 0.0f);
    litColor.a = DiffuseAlbedo.a;
    
#endif
    return litColor;
}


