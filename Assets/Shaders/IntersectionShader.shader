Shader "Custom/IntersectionShader"
{
    Properties
    {
       _MainTex("Main Texture" , 2D) = "white" {}
       _MainColor("Main color" , Color) = (1,1,1,1)

       _IntersectionDepth("Intersection Depth" , Float) = 0.1
       [HDR] _IntersectionColor("Intersection Color" , Color) = (1,1,1,1)
    }

    SubShader
    {
       Tags { "Queue"="Geometry" "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct MeshData
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolator
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };
            
            sampler2D _MainTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _MainColor;
                float4 _IntersectionColor;
                float _IntersectionDepth;
            CBUFFER_END

            void Unity_Remap_float4(float4 In, float2 InMinMax, float2 OutMinMax, out float4 Out)
            {
                Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            Interpolator vert(MeshData IN)
            {
                Interpolator OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }
            
            float4 frag(Interpolator IN) : SV_Target
            {
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;

                float sceneDepthRaw = SampleSceneDepth(screenUV);
                float sceneDepth = LinearEyeDepth(sceneDepthRaw, _ZBufferParams);

                float objectDepth = LinearEyeDepth(IN.screenPos.z / IN.screenPos.w, _ZBufferParams);

                float depthDiff = sceneDepth - objectDepth;
   
                float intersection = saturate(1 - depthDiff / _IntersectionDepth);

                float4 mainColor = tex2D(_MainTex, IN.uv) * _MainColor;
                return lerp(mainColor, _IntersectionColor, intersection);
            }


            ENDHLSL
        }
    }
}
