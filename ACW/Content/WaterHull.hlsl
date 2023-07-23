struct Quad
{
	float Edges[4] : SV_TessFactor;
	float Inside[2] : SV_InsideTessFactor;
};

struct HullShaderOutput
{
	float4 position : SV_POSITION;
};

Quad ConstantHS()
{
	Quad output;

	output.Edges[0] = 20;
	output.Edges[1] = 20;
	output.Edges[2] = 20;
	output.Edges[3] = 20;
	output.Inside[0] = 20;
	output.Inside[1] = 20;

	return output;
}

[domain("quad")]
[partitioning("fractional_even")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(4)]
[patchconstantfunc("ConstantHS")]
HullShaderOutput main(InputPatch <HullShaderOutput, 4> patch, uint i : SV_OutputControlPointID)
{
	HullShaderOutput output;

	output.position = patch[i].position;

	return output;
}