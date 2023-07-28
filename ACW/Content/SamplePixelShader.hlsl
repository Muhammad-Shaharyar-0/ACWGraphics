// Input from the vertex shader
struct VertexOutput
{
    float4 position : SV_POSITION;
    float3 cameraPosition : TEXCOORD0;
};

// Texture sampler for the underwater texture
Texture2D underwaterTexture : register(t0);
SamplerState txSampler : register(s0);

// The underwater color and density


float4 main(VertexOutput input) : SV_TARGET
{

    float4 underwaterColor = float4(0.0f, 0.4f, 0.8f, 0.7f);
    float underwaterDensity = 0.1f;
    // Calculate the distance from the camera to the pixel
    float3 viewDir = normalize(input.position - input.cameraPosition);
    float distanceToCamera = length(viewDir);

    // Apply fog based on the distance
    float fogFactor = saturate(distanceToCamera * underwaterDensity);

    // Interpolate the underwater color with the scene color
    float4 sceneColor = underwaterColor * fogFactor;
    float4 underwaterSceneColor = lerp(sceneColor, float4(0, 0.4, 0.6, 1), fogFactor);

    // Apply texture mapping for additional underwater effect
    float4 textureColor = underwaterTexture.Sample(txSampler, input.position.xy);


    return lerp(underwaterSceneColor, textureColor, 0.5f);
}