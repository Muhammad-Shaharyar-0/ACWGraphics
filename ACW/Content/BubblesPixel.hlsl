//static float4 eye = float4(0, 0, 15, 1);
static float nearPlane = 1.0;
static float farPlane = 1000.0;

static float4 lightColour = float4(0.2, 0.4, 0.7, 1);
static float3 lightPos = float3(-10, 100, -10);
static float4 backgroundColour = float4(0.1, 0.1, 0.1, 1);

static float4 sphereColour1 = float4(1, 1, 1, 1); 
static float4 sphereColour2 = float4(1, 1, 1, 1); 
static float4 sphereColour3 = float4(1, 1, 1, 1); 
static float shininess = 60;


#define NOBJECTS 3

// A constant buffer that stores the three basic column-major matrices for composing geometry.
cbuffer ModelViewProjectionConstantBuffer : register(b0)
{
	matrix model;
	matrix view;
	matrix projection;
	float4 eye;
	float4 lookAt;
	float4 upDir;
};

struct Sphere 
{
	float3 centre;
	float radiusSqrd;
	float4 colour;
	float diffuse, specular, reflected, shininess;
};

static Sphere spheres[NOBJECTS] = {
	{ 2.0, -5.0, 0.0, 0.01, sphereColour1, 0.3, 0.5, 0.7, shininess },
	{ 0.0, -5.0, 0.0, 0.01, sphereColour2, 0.5, 0.7, 0.7, shininess },
	{ -2.5, -5.0, 0.0, 0.01, sphereColour3, 0.5, 0.3, 0.7, shininess }
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

float SphereIntersect(Sphere sphere, Ray ray, out bool hit)
{
	float3 viewDir = sphere.centre - ray.origin;
	float A = dot(viewDir, ray.direction);
	float B = dot(viewDir, viewDir) - A * A;

	float radius = sqrt(sphere.radiusSqrd);
	float disc = radius * radius - B;
	if (disc < 0.0)
	{
		hit = false;
		return farPlane;
	}

	float discSqrt = sqrt(disc);
	float time = A - discSqrt;
	hit = (time >= 0.0);
	return hit ? time : farPlane;
}

float3 SphereNormal(Sphere sphere, float3 pos)
{
	return normalize(pos - sphere.centre);
}



float4 Phong(float3 normal, float3 lightDir, float3 viewDir, float shininess, float4 diffuseColour, float4 specularColour)
{
	float NormalDotLightDir = dot(normal, lightDir);
	float diffuse = saturate(NormalDotLightDir);
	float3 reflection = reflect(lightDir, normal);
	float specular = pow(saturate(dot(viewDir, reflection)), shininess) * (NormalDotLightDir > 0.0);
	return diffuse * diffuseColour + specular * specularColour;
}


bool Shadow(Ray ray)
{
	for (int i = 0; i < NOBJECTS; i++)
	{
		bool hit;
		SphereIntersect(spheres[i], ray, hit);
		if (hit)
		{
			return true;
		}
	}
	return false;
}

float4 Shade(float3 hitPos, float3 normal, float3 viewDir, int hitObj, float lightIntensity)
{
	float3 lightDir = normalize(lightPos - hitPos);
	float4 diffuse = spheres[hitObj].colour * spheres[hitObj].diffuse;
	float4 specular = spheres[hitObj].colour * spheres[hitObj].specular;

	Ray shadowRay;
	shadowRay.origin = hitPos;
	shadowRay.direction = lightDir;

	bool isShadowed = Shadow(shadowRay);

	return !isShadowed * lightColour * lightIntensity * Phong(normal, lightDir, viewDir, spheres[hitObj].shininess, diffuse, specular);
}

float3 NearestHit(Ray ray, out int hitObj, out bool anyHit)
{
	float minTime = farPlane;
	hitObj = -1;
	anyHit = false;
	for (int i = 0; i < NOBJECTS; i++)
	{
		bool hit;
		float time = SphereIntersect(spheres[i], ray, hit);
		if (hit && time < minTime)
		{
			hitObj = i;
			minTime = time;
			anyHit = true;
		}
	}

	// If anyHit is false, return ray.origin (no hit found)
	// Otherwise, return ray.origin + ray.direction * minTime
	return anyHit ? ray.origin + ray.direction * minTime : ray.origin;
}

float4 RayTracing(Ray ray)
{
	int hitObj;
	bool hit;
	float3 normal;
	float4 colour = float4(0, 0, 0, 0);
	float lightIntensity = 1.0;

	float3 nearestHit = NearestHit(ray, hitObj, hit);

	// Calculate the depth position only if hit is true
	if (hit)
	{
		float4 depthPos = mul(mul(float4(nearestHit, 1), view), projection);
		output.depth = depthPos.z / depthPos.w;
	}
	else
	{
		// No hit, discard the pixel
		discard;
	}

	for (int depth = 1; depth < 5; depth++)
	{
		if (hit)
		{
			normal = SphereNormal(spheres[hitObj], nearestHit);
			colour += Shade(nearestHit, normal, ray.direction, hitObj, lightIntensity);

			lightIntensity *= spheres[hitObj].reflected;
			ray.origin = nearestHit;
			ray.direction = reflect(ray.direction, normal);
			nearestHit = NearestHit(ray, hitObj, hit);
		}
		else
		{
			colour += backgroundColour / depth / depth;
		}
	}
	return colour;
}


PixelShaderOutput main(VS_QUAD input)
{
	float zoom = 5.0;
	float2 xy = zoom * input.canvasXY;
	float distEyeToCanvas = nearPlane;
	float3 pixelPos = float3(xy, distEyeToCanvas);

	float3 viewDir = normalize(eye.xyz - lookAt.xyz);
	float3 viewLeft = cross(upDir.xyz, viewDir);
	float3 viewUp = cross(viewDir, viewLeft);
	viewLeft = normalize(viewLeft);
	viewUp = normalize(viewUp);

	float3 pixelWorld = pixelPos.x * viewLeft + pixelPos.y * viewUp + pixelPos.z * viewDir;

	Ray eyeRay;
	eyeRay.origin = eye.xyz;
	eyeRay.direction = normalize(pixelWorld - eye.xyz);

	output.colour = RayTracing(eyeRay);

	return output;
}