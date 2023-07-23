// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
	matrix model;
	matrix view;
	matrix projection;
	float4 eye;
};

struct VS_Canvas
{
	float4 position : SV_POSITION;
	float2 canvasXY : TEXCOORD0;
};

cbuffer timeConstantBuffer : register(b1)
{
	float time;
	float3 padding;
}

VS_Canvas main(float4 vPos : POSITION)
{
	VS_Canvas output;

	output.position = float4(sign(vPos.xy), 0, 1);
	output.position.y += time * 0.1;
	float aspectRatio = projection._m11 / projection._m00;
	output.canvasXY = sign(vPos.xy) * float2(aspectRatio, 1.0);

	return output;
}