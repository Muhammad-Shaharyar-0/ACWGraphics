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

struct VS_Canvas
{
	float4 position : SV_POSITION;
	float2 canvasXY : TEXCOORD0;
};

VS_Canvas main(float4 vPos : POSITION)
{
	VS_Canvas output;

	// Generate the position output
	output.position = float4(sign(vPos.xy), 0, 1);

	// Calculate the aspect ratio
	float aspectRatio = projection._m11 / projection._m00;

	// Generate the canvasXY output
	output.canvasXY = sign(vPos.xy) * float2(aspectRatio, 1.0);

	return output;
}