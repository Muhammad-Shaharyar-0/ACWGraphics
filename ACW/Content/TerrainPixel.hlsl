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

#define NOISE_TABLE_SIZE 256

// Precomputed noise lookup table
static float g_NoiseTable[NOISE_TABLE_SIZE];

// Initialize the noise lookup table
void InitializeNoiseTable()
{
	for (int i = 0; i < NOISE_TABLE_SIZE; i++)
	{
		float2 grid = float2(floor(i), frac(i));
		float2 f = frac(grid);
		float2 uv = f * f * (3.0 - 2.0 * f);

		int index00 = (int)grid.x + (int)grid.y * NOISE_TABLE_SIZE;
		int index01 = index00 + 1;
		int index10 = index00 + NOISE_TABLE_SIZE;
		int index11 = index10 + 1;

		float n1 = Hash(grid + float2(0.0, 0.0));
		float n2 = Hash(grid + float2(1.0, 0.0));
		float n3 = Hash(grid + float2(0.0, 1.0));
		float n4 = Hash(grid + float2(1.0, 1.0));
		n1 = lerp(n1, n2, uv.x);
		n2 = lerp(n3, n4, uv.x);
		g_NoiseTable[i] = lerp(n1, n2, uv.y);
	}
}

// Compute noise using the precomputed lookup table
float Noise(in float2 p)
{
	float2 grid = floor(p);
	float2 f = frac(p);
	float2 uv = f * f * (3.0 - 2.0 * f);

	int index00 = (int)grid.x + (int)grid.y * NOISE_TABLE_SIZE;
	int index01 = index00 + 1;
	int index10 = index00 + NOISE_TABLE_SIZE;
	int index11 = index10 + 1;

	float n1 = g_NoiseTable[index00];
	float n2 = g_NoiseTable[index01];
	float n3 = g_NoiseTable[index10];
	float n4 = g_NoiseTable[index11];
	n1 = lerp(n1, n2, uv.x);
	n2 = lerp(n3, n4, uv.x);
	return lerp(n1, n2, uv.y);
}

// fractalNoise remains unchanged
float fractalNoise(in float2 xy)
{
	float w = 0.7;
	float f = 0.0;
	for (int i = 0; i < 4; i++)
	{
		f += Noise(xy) * w;
		w *= 0.5;
		xy *= 2.7;
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

	float4 ambientColour = float4(0.1, 0.1, 0.1, 1.0);
	float4 materialDiffuse = 0;
	float4 materialSpecular = 0;
	float4 texColour = 0;

	materialDiffuse = float4(0.8, 0.5, 0.25, 1.0);
	materialSpecular = float4(0.3, 0.2, 0.1, 1.0);
	texColour = float4(1.0, 0.7, 0.3, 1.0) * fractalNoise(input.posWorld.xz);


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

	// Calculate the distance from the camera (view position) to the pixel being rendered.
	float4 fogColor = (0.5f, 0.5f, 0.5f, 1.0f); // Gray fog color
	float fogStartDistance = 15.0f; // Start of fog effect at 10 units from the camera
	float fogEndDistance = 100.0f;   // End of fog effect at 50 units from the camera

	float viewDistance = length(input.posWorld);

	// Calculate the fog factor using the view distance and the fog start and end distances.
	float fogFactor = saturate((viewDistance - fogStartDistance) / (fogEndDistance - fogStartDistance));

	// Interpolate the fog color with the original pixel color.
	finalColour = saturate(finalColour* texColour);

	float4 finalColor = lerp(finalColour, fogColor, fogFactor);


	return finalColor;
}