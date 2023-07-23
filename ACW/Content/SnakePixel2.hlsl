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

cbuffer Light : register(b1)
{
	float4 lightPos;
	float4 lightColour;
}

struct PixelShaderInput
{
	float4 position : SV_POSITION;
	float4 norm : NORMAL;
	float4 posWorld : TEXCOORD;
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

float4 main(PixelShaderInput input) : SV_TARGET
{
	float4 finalColour = 0;
	float4 diffuseColour = 0;
	float diffuseFactor = 0;
	float4 specularColour = 0;
	float specularFactor = 0;

	float4 ambientColour = float4(0.2, 0.2, 0.3, 1.0);
	float4 materialDiffuse = 0;
	float4 materialSpecular = 0;
	float4 texColour = 0;
	float noise = fractalNoise(input.posWorld.xz);

	materialDiffuse = float4(0.3 * noise, 0.8 * noise, 0.3 * noise, 1.0);
	materialSpecular = float4(0.4 * noise, 0.9 * noise, 0.4 * noise, 1.0);
	texColour = float4(0.2 * noise, 1.0 * noise, 0.2 * noise, 1.0);

	float4 viewDir = normalize(eye - input.posWorld);
	float4 lightDir = normalize(lightPos - input.posWorld);
	float4 reflection = normalize(reflect(-lightDir, input.norm));

	diffuseFactor = saturate(dot(lightDir, input.norm));

	if (diffuseFactor > 0)
	{
		specularFactor = pow(saturate(dot(viewDir, reflection)), 0.8 * 128);
	}

	diffuseColour = lightColour * diffuseFactor;
	specularColour = lightColour * specularFactor;

	finalColour = saturate(ambientColour + (diffuseColour * materialDiffuse) + (specularColour * materialSpecular));

	return saturate(finalColour * texColour);

	return texColour;
}
