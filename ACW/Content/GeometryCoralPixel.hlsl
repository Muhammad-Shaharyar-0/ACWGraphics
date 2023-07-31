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

Texture2D txColour : register(t0);
SamplerState txSampler : register(s0);

cbuffer Light : register(b1)
{
	float4 lightPos;
	float4 lightColour;
}

struct PixelShaderInput
{
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD0;

};

float4x4 Transpose(float4x4 mat)
{
	return float4x4(
		mat._m00, mat._m10, mat._m20, mat._m30,
		mat._m01, mat._m11, mat._m21, mat._m31,
		mat._m02, mat._m12, mat._m22, mat._m32,
		mat._m03, mat._m13, mat._m23, mat._m33
		);
}

float4x4 InverseTranspose(float4x4 mat)
{
	float a0 = mat._m00 * mat._m11 - mat._m01 * mat._m10;
	float a1 = mat._m00 * mat._m12 - mat._m02 * mat._m10;
	float a2 = mat._m00 * mat._m13 - mat._m03 * mat._m10;
	float a3 = mat._m01 * mat._m12 - mat._m02 * mat._m11;
	float a4 = mat._m01 * mat._m13 - mat._m03 * mat._m11;
	float a5 = mat._m02 * mat._m13 - mat._m03 * mat._m12;
	float b0 = mat._m20 * mat._m31 - mat._m21 * mat._m30;
	float b1 = mat._m20 * mat._m32 - mat._m22 * mat._m30;
	float b2 = mat._m20 * mat._m33 - mat._m23 * mat._m30;
	float b3 = mat._m21 * mat._m32 - mat._m22 * mat._m31;
	float b4 = mat._m21 * mat._m33 - mat._m23 * mat._m31;
	float b5 = mat._m22 * mat._m33 - mat._m23 * mat._m32;

	float det = a0 * b5 - a1 * b4 + a2 * b3 + a3 * b2 - a4 * b1 + a5 * b0;

	float4x4 inverseMatrix;
	inverseMatrix._m00 = (mat._m11 * b5 - mat._m12 * b4 + mat._m13 * b3) / det;
	inverseMatrix._m01 = (-mat._m01 * b5 + mat._m02 * b4 - mat._m03 * b3) / det;
	inverseMatrix._m02 = (mat._m31 * a5 - mat._m32 * a4 + mat._m33 * a3) / det;
	inverseMatrix._m03 = (-mat._m21 * a5 + mat._m22 * a4 - mat._m23 * a3) / det;
	inverseMatrix._m10 = (-mat._m10 * b5 + mat._m12 * b2 - mat._m13 * b1) / det;
	inverseMatrix._m11 = (mat._m00 * b5 - mat._m02 * b2 + mat._m03 * b1) / det;
	inverseMatrix._m12 = (-mat._m30 * a5 + mat._m32 * a2 - mat._m33 * a1) / det;
	inverseMatrix._m13 = (mat._m20 * a5 - mat._m22 * a2 + mat._m23 * a1) / det;
	inverseMatrix._m20 = (mat._m10 * b4 - mat._m11 * b2 + mat._m13 * b0) / det;
	inverseMatrix._m21 = (-mat._m00 * b4 + mat._m01 * b2 - mat._m03 * b0) / det;
	inverseMatrix._m22 = (mat._m30 * a4 - mat._m31 * a2 + mat._m33 * a0) / det;
	inverseMatrix._m23 = (-mat._m20 * a4 + mat._m21 * a2 - mat._m23 * a0) / det;
	inverseMatrix._m30 = (-mat._m10 * b3 + mat._m11 * b1 - mat._m12 * b0) / det;
	inverseMatrix._m31 = (mat._m00 * b3 - mat._m01 * b1 + mat._m02 * b0) / det;
	inverseMatrix._m32 = (-mat._m30 * a3 + mat._m31 * a1 - mat._m32 * a0) / det;
	inverseMatrix._m33 = (mat._m20 * a3 - mat._m21 * a1 + mat._m22 * a0) / det;

	return Transpose(inverseMatrix);
}


float4 main(PixelShaderInput input) : SV_TARGET
{
	// Convert the pixel position from NDC to clip space
	float4 clipPosition = float4(input.uv * 2.0f - 1.0f, 0.0f, 1.0f);

	// Calculate the view-projection matrix
	float4x4 viewProjection = mul(view, projection);

	// Calculate the inverse of the view-projection matrix
	float4x4 viewProjectionInverse = InverseTranspose(viewProjection);

	// Get the view direction in world space by multiplying the pixel's clip position by the inverse view-projection matrix
	float4 viewDirection = mul(clipPosition, viewProjectionInverse);
	viewDirection /= viewDirection.w; // Perspective divide

	// Calculate the pixel's view position by adding the eye position (camera position) to the view direction
	float4 viewPosition = eye + viewDirection;

	// Calculate the pixel's world position by transforming the view position using the inverse model matrix
	float4 worldPosition = mul(viewPosition, InverseTranspose(model));

	// Use the world position for further calculations or rendering

	float3 underwaterColor = float3(0.0f, 0.4f, 0.7f); // Blueish tint for underwater
	float distortionStrength = 0.005f; // Adjust the distortion strength (0.0f - 0.1f)
	float refractionIndex = 0.8f; // Adjust the refraction index (0.0f - 1.0f)

	// Calculate the distortion offset based on the view direction and distortion strength.
	float2 distortionOffset = worldPosition.xy * distortionStrength;

	// Sample the original pixel color before applying the underwater effect.
	float4 texColour = txColour.Sample(txSampler, input.uv);

	// Apply the distortion offset to the texture coordinates.
	float2 distortedTexCoord = input.uv + distortionOffset;

	// Sample the texture with distortion.
	float4 distortedColor = txColour.Sample(txSampler, distortedTexCoord);

	// Apply the underwater color tint and refraction index.
	float4 underwaterTintedColor = lerp(texColour, float4(underwaterColor, texColour.a), 0.5f);

	// Calculate the final pixel color with the underwater effect.
	float4 finalColor = lerp(underwaterTintedColor, distortedColor, refractionIndex);

	return finalColor;
}