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

struct VertexShaderInput
{
	float3 pos : POSITION;
};

struct HullShaderInput
{
	float4 position : SV_POSITION;
};

HullShaderInput main(VertexShaderInput input)
{
	HullShaderInput output;

	output.position = float4(0, 0, 0, 1);

	return output;
}