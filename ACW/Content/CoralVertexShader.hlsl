cbuffer modelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    float4 eye;
    float4 lookAt;
    float4 upDir;
};

struct VertexInput
{
    float3 position : POSITION;
};

struct VertexOutput
{
    float4 position : SV_POSITION;
};

// Simple function to transform the cube into a star-like object
float3 TransformToStar(float3 position)
{
    // Scale the cube along the Y-axis to make it thinner
    position.y *= 0.5;

    // Apply a sin function to create the star-like effect
    float angle = atan2(position.z, position.x);
    float radius = length(position.xz);
    float starFactor = sin(radius * 10.0) * 0.5 + 0.5;

    // Combine the original position with the modified position
    position.x = cos(angle) * radius * starFactor;
    position.z = sin(angle) * radius * starFactor;

    return position;
}

// Simple shader to do vertex processing on the GPU.
VertexOutput main(VertexInput input)
{
    VertexOutput output;
    input.position = float3(0, 2, 0);
    float3 pos = input.position;

    // Apply the transformation to the star-like shape
    pos = TransformToStar(pos);

    // Output the final position in clip space
    output.position = float4(pos, 1.0f);

    return output;
}
