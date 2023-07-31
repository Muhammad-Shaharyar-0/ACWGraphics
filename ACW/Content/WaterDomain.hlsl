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

struct PixelShaderInput
{
	float4 position : SV_POSITION;
	float4 norm : NORMAL;
	float4 posWorld : TEXCOORD;
};

struct HullShaderOutput
{
	float4 position : SV_POSITION;
};

static float3 QuadPos[4] =
{
	float3(-50, 20, 50),
	float3(-50, 20, -50),
	float3(50, 20, 50),
	float3(50, 20, -50)
};

struct Quad
{
	float Edges[4] : SV_TessFactor;
	float Inside[2] : SV_InsideTessFactor;
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
	return n1;
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

[domain("quad")]
PixelShaderInput main(Quad input, float2 UV : SV_DomainLocation, const OutputPatch<HullShaderOutput, 4> QuadPatch)
{
	PixelShaderInput output;

	float3 vPos1 = (1.0 - UV.y) * QuadPos[0].xyz + UV.y * QuadPos[1].xyz;
	float3 vPos2 = (1.0 - UV.y) * QuadPos[2].xyz + UV.y * QuadPos[3].xyz; 
	float3 uvPos = (1.0 - UV.x) * vPos1 + UV.x * vPos2;

	uvPos.y +=  sin(time) * 0.05;
	uvPos.y += 0.5;

	float dYx = fractalNoise(uvPos.xz + float2(0.1, 0.0));
	float dYz = fractalNoise(uvPos.xz + float2(0.0, 0.1));

	float3 N = normalize(float3(uvPos.y - dYx, 0.2, uvPos.y - dYz));

	output.norm = float4(N, 1.0);
	output.posWorld = float4(uvPos, 1);
	output.position = output.posWorld;
	output.position = mul(output.position, view);
	output.position = mul(output.position, projection);

	return output;
}