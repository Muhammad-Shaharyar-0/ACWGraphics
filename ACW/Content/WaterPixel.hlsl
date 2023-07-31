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
	float2 uv = f * f * (3.0 - 2.0 * f);

	float n1 = lerp(Hash(grid + float2(0.0, 0.0)), Hash(grid + float2(1.0, 0.0)), uv.x);
	float n2 = lerp(Hash(grid + float2(0.0, 1.0)), Hash(grid + float2(1.0, 1.0)), uv.x);
	return lerp(n1, n2, uv.y);
}

float fractalNoise(in float2 xy)
{
	float w = 0.7;
	float f = 0.0;

	f += Noise(xy) * w;
	xy *= 2.7;
	w *= 0.5;

	f += Noise(xy) * w;
	xy *= 2.7;
	w *= 0.5;

	f += Noise(xy) * w;
	xy *= 2.7;
	w *= 0.5;

	f += Noise(xy) * w;

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

	materialDiffuse = float4(0.0, 0.6, 0.8, 1.0);
	materialSpecular = float4(0.0, 0.7, 0.9, 1.0);
	texColour = float4(0.0, 0.8, 1.0, 1.0);

	float4 viewDir = normalize(eye - input.posWorld);
	float4 lightDir = normalize(lightPos - input.posWorld);
	float4 reflection = normalize(reflect(-lightDir, input.norm));

	diffuseFactor = saturate(dot(lightDir, input.norm));

	if (diffuseFactor > 0)
	{
		specularFactor = pow(saturate(dot(viewDir, reflection)), 0.1 * 128);
	}

	diffuseColour = lightColour * diffuseFactor;
	specularColour = lightColour * specularFactor;

	finalColour = saturate(ambientColour + (diffuseColour * materialDiffuse) + (specularColour * materialSpecular));

	float4 fogColor = (0.2f, 0.2f, 0.2f, 1.0f); // Gray fog color
	float fogStartDistance = 50.0f; // Start of fog effect at 10 units from the camera
	float fogEndDistance = 100.0f;   // End of fog effect at 50 units from the camera

	float viewDistance = length(input.posWorld);

	// Calculate the fog factor using the view distance and the fog start and end distances.
	float fogFactor = saturate((viewDistance - fogStartDistance) / (fogEndDistance - fogStartDistance));

	// Interpolate the fog color with the original pixel color.
	finalColour = saturate(finalColour * texColour);

	float4 finalColor = lerp(finalColour, fogColor, fogFactor);


	return finalColor;
}