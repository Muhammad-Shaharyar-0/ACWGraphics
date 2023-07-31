static float nearPlane = 1.0;
static float farPlane = 1000.0;

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

struct Ray
{
	float3 origin;
	float3 direction;
};

struct VS_QUAD
{
	float4 position : SV_POSITION;
	float2 canvasXY : TEXCOORD0;
};

struct PixelShaderOutput
{
	float4 colour : SV_TARGET;
	float depth : SV_DEPTH;
};

static PixelShaderOutput output;

#define AA 1   // make this 2 or 3 for antialiasing

//------------------------------------------------------------------



float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

//------------------------------------------------------------------

float2 opU(float2 d1, float2 d2)
{
	return (d1.x < d2.x) ? d1 : d2;
}

//------------------------------------------------------------------

#define ZERO 0

//------------------------------------------------------------------

float2 map(in float3 inPos)
{
	float2 res = float2(1e10, 0.0);

	float3 pos = inPos + float3(0.0, 4.0, 0.0);

	float3 sphereCenter = float3(-2.0, 0.25, -1.0);
	float sphereRadius = 0.2;
	float sphereDist = sdSphere(pos - sphereCenter, sphereRadius);

	float angleMultiplier = 0.03;
	float xAngle = 45.0 * pos.x;
	float yAngle = 45.0 * pos.y;
	float zAngle = 45.0 * pos.z;
	float sinX = sin(xAngle);
	float sinY = sin(yAngle);
	float sinZ = sin(zAngle);
	float angleSum = sinX * sinY * sinZ;

	res = opU(res, float2(0.5 * sphereDist + angleMultiplier * angleSum, 65.0));

	return res;
}


float2 iBox(in float3 ro, in float3 rd, in float3 rad)
{
	float3 invRd = 1.0 / rd;
	float3 n = invRd * ro;
	float3 k = abs(invRd) * rad;

	float3 t1 = -n - k;
	float3 t2 = -n + k;

	return float2(max(min(t1.x, t2.x), max(min(t1.y, t2.y), min(t1.z, t2.z))),
		min(max(t1.x, t2.x), max(max(t1.y, t2.y), t2.z)));
}

const float maxHei = 0.8;

float2 castRay(in float3 ro, in float3 rd)
{
	float2 res = float2(-1.0, -1.0);

	float tmin = 1.0;
	float tmax = 20.0;

	// raymarch primitives   
	float2 tb = iBox(ro, rd, float3(1000, 1000, 1000));
	tmin = max(tb.x, tmin);
	tmax = min(tb.y, tmax);

	float t = tmin;
	for (int i = 0; i < 170 && t < tmax; i++)
	{
		float2 h = map(ro + rd * t);
		if (abs(h.x) < (0.00001 * t))
		{
			res = float2(t, h.y);
			break;
		}
		t += h.x;
	}

	return res;
}


float calcSoftshadow(in float3 ro, in float3 rd, in float mint, in float tmax)
{
	// bounding volume
	float tp = (maxHei - ro.y) / rd.y;
	tmax = (tp > 0.0) ? min(tmax, tp) : tmax;

	float res = 1.0;
	float t = mint;
	for (int i = 0; i < 16; i++)
	{
		float h = map(ro + rd * t).x;
		res = min(res, 8.0 * h / t);
		t += clamp(h, 0.02, 0.10);
	}
	return clamp(res, 0.0, 1.0);
}

float3 calcNormal(in float3 pos)
{
	float2 e = float2(1.0, -1.0) * 0.5773 * 0.0005;
	float3 map_e_xyy = map(pos + e.xyy).x;
	float3 map_e_yyx = map(pos + e.yyx).x;
	float3 map_e_yxy = map(pos + e.yxy).x;
	float3 map_e_xxx = map(pos + e.xxx).x;

	return normalize(e.xyy * map_e_xyy + e.yyx * map_e_yyx + e.yxy * map_e_yxy + e.xxx * map_e_xxx);
}

float calcAO(in float3 pos, in float3 nor)
{
	float occ = 0.0;
	float sca = 1.0;
	for (int i = 0; i < 5; i++) // Removed 'ZERO' constant, using direct '0' instead
	{
		float hr = 0.01 + 0.03 * float(i); // Simplified the calculation
		float3 aopos = nor * hr + pos;
		float dd = map(aopos).x;
		occ += (hr - dd) * sca; // Removed unnecessary negation
		sca *= 0.95;
	}
	return clamp(1.0 - 3.0 * occ, 0.0, 1.0) * (0.5 + 0.5 * nor.y);
}

float checkersGradBox(in float2 p)
{
	// filter kernel
	float2 w = fwidth(p) + 0.001;
	// analytical integral (box filter)
	float2 i = 1.0 - 2.0 * abs(frac(p - 0.5 * w) - 0.5); // Simplified the calculation
	// xor pattern
	return 0.25 * i.x * i.y; // Simplified the expression
}


float3 render(in float3 ro, in float3 rd)
{
	float3 col = float3(0.7, 0.9, 1.0) + rd.y * 0.8;
	float2 res = castRay(ro, rd);
	float t = res.x;
	float m = res.y;
	if (m > -0.5)
	{
		float3 pos = ro + t * rd;
		float4 depthPos = mul(mul(float4(pos, 1), view), projection);
		output.depth = depthPos.z / depthPos.w;
		float3 nor = (m < 1.5) ? float3(0.0, 1.0, 0.0) : calcNormal(pos);
		float3 ref = reflect(rd, nor);

		// material
		float3 diffuseColor = 0.45 + 0.35 * sin(float3(0.05, 0.08, 0.10) * (m - 1.0));
		if (m < 1.5)
		{
			float f = checkersGradBox(5.0 * pos.xz);
			diffuseColor = 0.3 + f * float3(0.1, 0.1, 0.1);
		}

		// lighting
		float occ = calcAO(pos, nor);
		float3 lightDir = normalize(float3(-10, 100, -10));
		float3 halfVec = normalize(lightDir - rd);
		float ambient = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
		float diffuse = clamp(dot(nor, lightDir), 0.0, 1.0);
		float backface = clamp(dot(nor, normalize(float3(-lightDir.x, 0.0, -lightDir.z))), 0.0, 1.0) * clamp(1.0 - pos.y, 0.0, 1.0);
		float fresnel = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);

		diffuse *= calcSoftshadow(pos, lightDir, 0.02, 2.5);
		fresnel *= calcSoftshadow(pos, ref, 0.02, 2.5);

		float specular = pow(clamp(dot(nor, halfVec), 0.0, 1.0), 16.0) *
			diffuse * (0.04 + 0.96 * pow(clamp(1.0 + dot(halfVec, rd), 0.0, 1.0), 5.0));

		float3 lighting = float3(0.0, 0.0, 0.0);
		lighting += 1.30 * diffuse * float3(1.00, 0.80, 0.55);
		lighting += 0.30 * ambient * float3(0.40, 0.60, 1.00) * occ;
		lighting += 0.40 * fresnel * float3(0.40, 0.60, 1.00) * occ;
		lighting += 0.50 * backface * float3(0.25, 0.25, 0.25) * occ;
		lighting += 0.25 * fresnel * float3(1.00, 1.00, 1.00) * occ;
		col = diffuseColor * lighting;
		col += 9.00 * specular * float3(1.00, 0.90, 0.70);

		col = lerp(col, float3(0.8, 0.9, 1.0), 1.0 - exp(-0.0002 * t * t * t));
	}
	else
	{
		discard;
	}

	return float3(clamp(col, 0.0, 1.0));
}

PixelShaderOutput main(VS_QUAD input)
{
	float zoom = 10.0;
	float2 xy = zoom * input.canvasXY;
	float3 pixelPos = float3(xy, nearPlane);


	Ray eyeRay;
	eyeRay.origin = eye.xyz;
	eyeRay.direction = normalize(pixelPos - eye.xyz);

	float3 pixelColour = render(eyeRay.origin, eyeRay.direction);

	output.colour = float4(pixelColour, 1.0);

	return output;
}