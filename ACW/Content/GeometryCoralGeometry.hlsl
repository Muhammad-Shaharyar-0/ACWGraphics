// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer modelViewProjectionConstantBuffer : register(b0)
{
	matrix model;
	matrix view;
	matrix projection;
	float4 eye;
	float4 lookAt;
	float4 upDir;
};

cbuffer timeConstantBuffer : register(b1)
{
	float time;
	float3 padding;
}

struct GeometryShaderInput
{
	float4 pos : SV_POSITION;
};

struct PixelShaderInput
{
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 posWorld : TEXCOORD2;
};

static const float3 QuadPos[4] = 
{ 
	float3(-1, 1, 0),
	float3(-1, -1, 0),
	float3(1, 1, 0),
	float3(1, -1, 0),
};

// Geometry Shader main function
[maxvertexcount(6)]
void main(point GeometryShaderInput input[1], inout TriangleStream<PixelShaderInput> OutputStream)
{
    PixelShaderInput output = (PixelShaderInput)0;

    // Get the vertex position
    float4 vPos = input[0].pos;

    // Check if the vertex is above the y threshold
    if (vPos.y > 0.6)
    {
        // Transform the vertex position by the view matrix
        vPos = mul(vPos, view);

        // Define the size of the quad
        float quadSize = 0.5;

        // Vertex 1
        output.position = vPos + float4(quadSize * QuadPos[0], 0.0);
        output.position.z += sin(time) * 0.2;
        output.position = mul(output.position, projection);
        output.uv = ((QuadPos[0].xy * -1) + float2(1, 1)) / 2;
        OutputStream.Append(output);

        // Vertex 2
        output.position = vPos + float4(quadSize * QuadPos[1], 0.0);
        output.position = mul(output.position, projection);
        output.uv = ((QuadPos[1].xy * -1) + float2(1, 1)) / 2;
        OutputStream.Append(output);

        // Vertex 3
        output.position = vPos + float4(quadSize * QuadPos[2], 0.0);
        output.position.z += sin(time) * 0.2;
        output.position = mul(output.position, projection);
        output.uv = ((QuadPos[2].xy * -1) + float2(1, 1)) / 2;
        OutputStream.Append(output);

        // Vertex 4
        output.position = vPos + float4(quadSize * QuadPos[3], 0.0);
        output.position = mul(output.position, projection);
        output.uv = ((QuadPos[3].xy * -1) + float2(1, 1)) / 2;
        OutputStream.Append(output);
    }
}