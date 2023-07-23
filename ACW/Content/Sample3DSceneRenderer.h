#pragma once

#include "..\Common\DeviceResources.h"
#include "ShaderStructures.h"
#include "..\Common\StepTimer.h"
#include <vector>
#include "DDSTextureLoader.h"

namespace ACW
{
	// This sample renderer instantiates a basic rendering pipeline.
	class Sample3DSceneRenderer
	{
	public:
		Sample3DSceneRenderer(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		void CreateDeviceDependentResources();
		void CreateWindowSizeDependentResources();
		void ReleaseDeviceDependentResources();
		void Update(DX::StepTimer const& timer, const std::vector<bool>& pInput);
		void Render();

	private:
		void DrawSpheres();
		void DrawImplicitShapes();
		void DrawImplicitPrimitives();
		void DrawFractals();
		void DrawTerrain();
		void DrawPlants();
		void DrawSnakes();
		void DrawWater();

		void CreateBuffers();
		void SetBuffers();
		void UpdateBuffers();

		void CreateBlendStates();
		void CreateDepthStencils();
		void CreateRasteriserStates();
		void CreateSamplerState();

	private:
		//Cached pointer to device resources.
		std::shared_ptr<DX::DeviceResources> m_deviceResources;
		Microsoft::WRL::ComPtr<ID3D11DeviceContext3> mContext;

		//Input layout for vertex data
		Microsoft::WRL::ComPtr<ID3D11InputLayout>	m_inputLayout;

		//Cube vertices/indices
		Microsoft::WRL::ComPtr<ID3D11Buffer>		m_vertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		m_indexBuffer;

		//Plant vertices/indices
		Microsoft::WRL::ComPtr<ID3D11Buffer> mPlantVertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer> mPlantIndexBuffer;

		//Snake vertices/indices
		Microsoft::WRL::ComPtr<ID3D11Buffer> mSnakeVertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer> mSnakeIndexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer> mSnakeVertexBuffer2;
		Microsoft::WRL::ComPtr<ID3D11Buffer> mSnakeIndexBuffer2;

		//Implicit shapes shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	m_vertexShaderImplicitShapes;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	m_pixelShaderImplicitShapes;

		//Implicit primitives shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	m_vertexShaderImplicitPrimitives;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	m_pixelShaderImplicitPrimitives;

		//Terrain shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderTerrain;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderTerrain;
		Microsoft::WRL::ComPtr<ID3D11HullShader> mHullShaderTerrain;
		Microsoft::WRL::ComPtr<ID3D11DomainShader> mDomainShaderTerrain;

		//Spheres shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderSpheres;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderSpheres;

		//Plant shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderPlants;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderPlants;
		Microsoft::WRL::ComPtr<ID3D11GeometryShader> mGeometryShaderPlants;

		//Snake shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderSnakes;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderSnakes;
		Microsoft::WRL::ComPtr<ID3D11GeometryShader> mGeometryShaderSnakes;
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderSnakes2;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderSnakes2;
		Microsoft::WRL::ComPtr<ID3D11GeometryShader> mGeometryShaderSnakes2;

		//Fractal shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderFractals;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderFractals;

		//Water shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderWater;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderWater;
		Microsoft::WRL::ComPtr<ID3D11HullShader> mHullShaderWater;
		Microsoft::WRL::ComPtr<ID3D11DomainShader> mDomainShaderWater;

		//Rasteriser states
		Microsoft::WRL::ComPtr<ID3D11RasterizerState> mDefaultRasteriser;
		Microsoft::WRL::ComPtr<ID3D11RasterizerState> mWireframeRasteriser;

		//Texture/Sampler
		Microsoft::WRL::ComPtr<ID3D11ShaderResourceView> mPlantTexture;
		Microsoft::WRL::ComPtr<ID3D11SamplerState> mSampler;

		//Blend states
		Microsoft::WRL::ComPtr<ID3D11BlendState> mAlphaBlend;
		Microsoft::WRL::ComPtr<ID3D11BlendState> mNoBlend;

		//Depth stencils
		Microsoft::WRL::ComPtr<ID3D11DepthStencilState> mDepthLessThanEqual;
		Microsoft::WRL::ComPtr<ID3D11DepthStencilState> mDepthLessThanEqualAll;

		//Constant buffers pointers
		Microsoft::WRL::ComPtr<ID3D11Buffer>		m_constantBufferCamera;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		mConstantBufferLight;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		mConstantBufferTime;

		//Constant buffers data
		ModelViewProjectionConstantBuffer	m_constantBufferDataCamera;
		LightConstantBuffer mConstantBufferDataLight;
		TimeConstantBuffer mConstantBufferDataTime;

		//Variables
		uint32	m_indexCount;
		uint32 mPlantIndex;
		uint32 mSnakeIndex;
		bool	m_loadingComplete;
		DirectX::XMVECTOR eye = { 0, 5, -10, 1 };
		DirectX::XMVECTOR at = { 0.0f, 5.0f, 1.0f, 0.0f };
		DirectX::XMVECTOR up = { 0.0f, 1.0f, 0.0f, 0.0f };
		DirectX::XMMATRIX lookAt;
	};
}

