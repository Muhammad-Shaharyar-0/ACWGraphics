cbuffer modelViewProjectionConstantBuffer : register(b0)
{
    matrix model;
    matrix view;
    matrix projection;
    float4 eye;
    float4 lookAt;
    float4 upDir;
};


struct PixelInput
{
    float4 position : SV_POSITION;
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

float4 main(PixelInput input) : SV_Target
{
    // You can apply color changing and other effects here if needed
    return float4(0.2f, 0.2f, 0.4f, 1.0f); // Example: Coral green color

	
}
