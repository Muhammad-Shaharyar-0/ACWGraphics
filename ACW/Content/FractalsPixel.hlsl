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

float2 opU(float2 d1, float2 d2)
{
	return (d1.x < d2.x) ? d1 : d2;
}

//------------------------------------------------------------------

#define ZERO 0

//------------------------------------------------------------------
float tetrahedron(float3 p, float scale, float iterations) {
	p.y -= 2.0;

	const float3 p0 = float3(-1, -1, -1);
	const float3 p1 = float3(1, 1, -1);
	const float3 p2 = float3(1, -1, 1);
	const float3 p3 = float3(-1, 1, 1);

	for (int i = 0; i < iterations; ++i) {
		float d = distance(p, p0);
		float3 c = p0;

		float t = distance(p, p1);
		if (t < d) {
			d = t;
			c = p1;
		}

		t = distance(p, p2);
		if (t < d) {
			d = t;
			c = p2;
		}

		t = distance(p, p3);
		if (t < d) {
			d = t;
			c = p3;
		}

		p = (p - c)*scale;
	}

	return length(p)*pow(scale, -float(iterations)) - 0.025*0.5;
}

float2 mandelbulb(float3 pos) {
	float n = 8.0;
	float t0 = 1.0;
	float dr = 1.0;

	float r, phi, theta, l;

	float3 z = pos;

	for (int i = 0; i < 8; i++)
	{
		r = length(z);

		if (r > 2.0)continue;

		phi = atan(z.y / z.x);
		theta = asin(z.z / r);

		dr = pow(r, n - 1.0)*dr *n + 1.0;

		z = pow(r, n)*float3(sin(n*theta)*cos(n*phi), sin(n*theta)*sin(n*phi), cos(n*theta)) + pos;
		t0 = min(r, t0);
	}
	return float2(r*log(r) / dr / 2.0, t0);
}

float2 map(in float3 inPos)
{
	float3 pos = inPos;
	float2 res = float2(1e10, 0.0);

	res = opU(res, float2(tetrahedron(pos - float3(4, 2, -5), 2, 10), 60));
	res = opU(res, mandelbulb(pos - float3(0, 2, -5)));

	return res;
}

float2 iBox(in float3 ro, in float3 rd, in float3 rad)
{
	float3 m = 1.0 / rd;
	float3 n = m * ro;
	float3 k = abs(m)*rad;
	float3 t1 = -n - k;
	float3 t2 = -n + k;
	return float2(max(max(t1.x, t1.y), t1.z),
		min(min(t2.x, t2.y), t2.z));
}

const float maxHei = 0.8;

float2 castRay(in float3 ro, in float3 rd)
{
	float2 res = float2(-1.0, -1.0);

	float tmin = 1.0;
	float tmax = 20.0;

	// raymarch primitives   
	float2 tb = iBox(ro, rd, float3(1000, 1000, 1000));
	if (tb.x<tb.y && tb.y>0.0 && tb.x < tmax)
	{
		tmin = max(tb.x, tmin);
		tmax = min(tb.y, tmax);

		float t = tmin;
		for (int i = 0; i < 170 && t < tmax; i++)
		{
			float2 h = map(ro + rd * t);
			if (abs(h.x) < (0.00001*t))
			{
				res = float2(t, h.y);
				break;
			}
			t += h.x;
		}
	}

	return res;
}


float calcSoftshadow(in float3 ro, in float3 rd, in float mint, in float tmax)
{
	// bounding volume
	float tp = (maxHei - ro.y) / rd.y; if (tp > 0.0) tmax = min(tmax, tp);

	float res = 1.0;
	float t = mint;
	for (int i = ZERO; i < 16; i++)
	{
		float h = map(ro + rd * t).x;
		res = min(res, 8.0*h / t);
		t += clamp(h, 0.02, 0.10);
	}
	return clamp(res, 0.0, 1.0);
}

float3 calcNormal(in float3 pos)
{
#if 1
	float2 e = float2(1.0, -1.0)*0.5773*0.0005;
	return normalize(e.xyy*map(pos + e.xyy).x +
		e.yyx*map(pos + e.yyx).x +
		e.yxy*map(pos + e.yxy).x +
		e.xxx*map(pos + e.xxx).x);
#else
	float3 n = float3(0.0);
	for (int i = ZERO; i < 4; i++)
	{
		float3 e = 0.5773*(2.0*float3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
		n += e * map(pos + 0.0005*e).x;
	}
	return normalize(n);
#endif    
}

float calcAO(in float3 pos, in float3 nor)
{
	float occ = 0.0;
	float sca = 1.0;
	for (int i = ZERO; i < 5; i++)
	{
		float hr = 0.01 + 0.12*float(i) / 4.0;
		float3 aopos = nor * hr + pos;
		float dd = map(aopos).x;
		occ += -(dd - hr)*sca;
		sca *= 0.95;
	}
	return clamp(1.0 - 3.0*occ, 0.0, 1.0) * (0.5 + 0.5*nor.y);
}

float checkersGradBox(in float2 p)
{
	// filter kernel
	float2 w = fwidth(p) + 0.001;
	// analytical integral (box filter)
	float2 i = 2.0*(abs(frac((p - 0.5*w)*0.5) - 0.5) - abs(frac((p + 0.5*w)*0.5) - 0.5)) / w;
	// xor pattern
	return 0.5 - 0.5*i.x*i.y;
}

float3 render(in float3 ro, in float3 rd)
{
	float3 col = float3(0.7, 0.9, 1.0) + rd.y*0.8;
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
		col = 0.45 + 0.35*sin(float3(0.05, 0.08, 0.10)*(m - 1.0));
		if (m < 1.5)
		{

			float f = checkersGradBox(5.0*pos.xz);
			col = 0.3 + f * float3(0.1, 0.1, 0.1);
		}

		// lighting
		float occ = calcAO(pos, nor);
		float3  lig = normalize(float3(-10, 100, -10));
		float3  hal = normalize(lig - rd);
		float amb = clamp(0.5 + 0.5*nor.y, 0.0, 1.0);
		float dif = clamp(dot(nor, lig), 0.0, 1.0);
		float bac = clamp(dot(nor, normalize(float3(-lig.x, 0.0, -lig.z))), 0.0, 1.0)*clamp(1.0 - pos.y, 0.0, 1.0);
		float dom = smoothstep(-0.2, 0.2, ref.y);
		float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);

		dif *= calcSoftshadow(pos, lig, 0.02, 2.5);
		dom *= calcSoftshadow(pos, ref, 0.02, 2.5);

		float spe = pow(clamp(dot(nor, hal), 0.0, 1.0), 16.0)*
			dif *
			(0.04 + 0.96*pow(clamp(1.0 + dot(hal, rd), 0.0, 1.0), 5.0));

		float3 lin = float3(0.0, 0.0, 0.0);
		lin += 1.30*dif*float3(1.00, 0.80, 0.55);
		lin += 0.30*amb*float3(0.40, 0.60, 1.00)*occ;
		lin += 0.40*dom*float3(0.40, 0.60, 1.00)*occ;
		lin += 0.50*bac*float3(0.25, 0.25, 0.25)*occ;
		lin += 0.25*fre*float3(1.00, 1.00, 1.00)*occ;
		col = col * lin;
		col += 9.00*spe*float3(1.00, 0.90, 0.70);

		col = lerp(col, float3(0.8, 0.9, 1.0), 1.0 - exp(-0.0002*t*t*t));
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
	float distEyeToCanvas = nearPlane;
	float3 pixelPos = float3(xy, -distEyeToCanvas);

	Ray eyeRay;
	eyeRay.origin = eye.xyz;
	eyeRay.direction = normalize(pixelPos - eye.xyz);

	float3 pixelColour = render(eyeRay.origin, eyeRay.direction);
	output.colour = float4(pixelColour, 1.0);
	return output;
}