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
// Per-vertex data used as input to the vertex shader.
struct VertexShaderInput
{
	float3 pos : POSITION;
};

struct VertexOutput
{
	float4 position : SV_POSITION;
	float3 cameraPosition : TEXCOORD0; // Output the camera position in world space
};

// Simple shader to do vertex processing on the GPU.
VertexOutput main(VertexShaderInput input)
{
	
	VertexOutput output;

	//float4 pos = float4(input.pos, 1.0f);

	//// Transform the vertex position into projected space.
	//pos = mul(pos, model);
	//pos = mul(pos, view);
	//pos = mul(pos, projection);

	//output.position = pos;


	output.position = float4(input.pos, 1.0f);
	output.cameraPosition = eye.xyz;

	return output;
}
