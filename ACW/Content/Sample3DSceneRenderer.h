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
		void DrawReflectiveBubbles();
		void DrawVertexCoral();
		void DrawImplicitCoral();
		void DrawTerrain();
		void DrawGeometryCorals();
		void DrawWater();
		void DrawUnderWaterEffect();

		void CreateBuffers();
		void SetBuffers();
		void UpdateBuffers();

		void CreateBlendStates();
		void CreateDepthStencils();
		void CreateRasteriserStates();
		void CreateSamplerState();
		void CreateUnderwaterRenderTarget();
	private:
		//Cached pointer to device resources.
		std::shared_ptr<DX::DeviceResources> m_deviceResources;
		Microsoft::WRL::ComPtr<ID3D11DeviceContext3> mContext;

		Microsoft::WRL::ComPtr<ID3D11ShaderResourceView> mUnderwaterTexture;
	
		//Input layout for vertex data
		Microsoft::WRL::ComPtr<ID3D11InputLayout>	m_inputLayout;
		
		//Cube vertices/indices
		Microsoft::WRL::ComPtr<ID3D11Buffer>		m_vertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer>		m_indexBuffer;


		Microsoft::WRL::ComPtr<ID3D11Buffer> m_fullScreenQuadVertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer> m_fullScreenQuadIndexBuffer;

		//Plant vertices/indices
		Microsoft::WRL::ComPtr<ID3D11Buffer> mPlantVertexBuffer;
		Microsoft::WRL::ComPtr<ID3D11Buffer> mPlantIndexBuffer;

		//Implicit primitives shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	m_vertexShaderImplicitPrimitives;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	m_pixelShaderImplicitPrimitives;

		//Implicit primitives shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader>	m_vertexShaderVertexCoral;
		Microsoft::WRL::ComPtr<ID3D11PixelShader>	m_pixelShaderVertexCoral;

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

		//Underwater shaders
		Microsoft::WRL::ComPtr<ID3D11VertexShader> mVertexShaderUnderwater;
		Microsoft::WRL::ComPtr<ID3D11PixelShader> mPixelShaderUnderwater;

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

