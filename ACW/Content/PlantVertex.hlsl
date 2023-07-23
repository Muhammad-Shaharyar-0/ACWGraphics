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

struct GeometryShaderInput
{
	float4 position : SV_POSITION;
};

float Hash(float2 grid)
{
	float h = dot(grid, float2 (127.1, 311.7));
	return frac(sin(h)*43758.5453123);
}

float Noise(in float2 p)
{
	float2 grid = floor(p);
	float2 f = frac(p);
	float2 uv = f * f*(3.0 - 2.0*f);
	float n1, n2, n3, n4;
	n1 = Hash(grid + float2(0.0, 0.0));
	n2 = Hash(grid + float2(1.0, 0.0));
	n3 = Hash(grid + float2(0.0, 1.0));
	n4 = Hash(grid + float2(1.0, 1.0));
	n1 = lerp(n1, n2, uv.x);
	n2 = lerp(n3, n4, uv.x);
	n1 = lerp(n1, n2, uv.y);
	return n1;//2*(2.0*n1 -1.0);
}

float fractalNoise(in float2 xy)
{
	float w = .7;
	float f = 0.0;
	for (int i = 0; i < 4; i++)
	{
		f += Noise(xy) * w; w *= 0.5; xy *= 2.7;
	}
	return f;
}

GeometryShaderInput main(VertexShaderInput input)
{
	GeometryShaderInput output;

	output.position = float4(input.pos, 1);
	output.position.y = fractalNoise(output.position.xz) + 0.1;

	return output;
}