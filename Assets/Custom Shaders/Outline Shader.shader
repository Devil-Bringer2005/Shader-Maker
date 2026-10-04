Shader "Custom/OutlineShader"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		[HDR] _OutlineColor("Outline Color", Color) = (0,0,0,1) 
		_OutlineThickness("Outline Thickness" ,Float) = 1
	}

	SubShader
	{	
		Tags
		{
			"RenderType" = "Transparent" 
			"Queue" = "Transparent"
			"RenderPipeline" = "UniversalPipeline"
		}

		Pass
		{
			Cull Front
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


			float _OutlineThickness;
			float4 _OutlineColor;

			struct MeshData
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0 ;
				float3 normal : NORMAL;
			};

			struct Interpolator 
			{
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD0;
			};

			Interpolator vert(MeshData IN)
			{
				Interpolator OUT;
				OUT.normal = TransformObjectToWorldNormal(IN.normal);
				float3 normalOS = IN.normal;
				float3 offsetPos = IN.vertex.xyz + normalOS * _OutlineThickness; 
				OUT.vertex = TransformObjectToHClip(offsetPos);
				return OUT;
			}

			float4 frag(Interpolator IN): SV_Target
			{

				return _OutlineColor;
			} 

			ENDHLSL
		}


		Pass
		{	
			

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			sampler2D _MainTex;
			float4 _MainTex_ST;

		

			struct MeshData
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0 ;
				float3 normal : NORMAL;
			};

			struct Interpolator 
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0 ;
				float3 normal : TEXCOORD1;
			};

			Interpolator vert(MeshData IN)
			{
				Interpolator OUT;

				OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
				OUT.uv = IN.uv;
				OUT.uv = TRANSFORM_TEX(IN.uv , _MainTex);
				OUT.normal = IN.normal;

				return OUT;
			}

			float4 frag(Interpolator IN): SV_Target
			{
				float4 texColor = tex2D(_MainTex , IN.uv);

				return texColor;
			} 

			ENDHLSL
		}

	}
}
