Shader "Custom/UnlitEmission"
{
    Properties
    {
        _MainTex("Main Texture" , 2D) = "white" {}
        _EmissionTex("Emission Texture" , 2D) = "" {}
        [HDR] _EmissionColor("Emission Color" , Color) = (1,1,1,1)
        _EmissionIntensity("Emission Intensity" , Float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct MeshData
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            // sampler2D _MainTex;
            // sampler2D _EmissionTex;

            // float4 _MainTex_ST;
            // float4 _EmissionTex_ST;
            // float4 _EmissionColor;
            // float _EmissionIntensity;
            sampler2D _MainTex;
            sampler2D _EmissionTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _EmissionTex_ST;
                float4 _EmissionColor;
                float _EmissionIntensity;
            CBUFFER_END

            Interpolators vert(MeshData IN)
            {
                Interpolators OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag(Interpolators IN) : SV_Target
            {
                float4 texColor = tex2D(_MainTex,IN.uv);
                float4 emissionMask = tex2D(_EmissionTex,IN.uv);

                float3 finalEmission = emissionMask.rgb * _EmissionColor.rgb * _EmissionIntensity;
                float3 finalColor = texColor.rgb + finalEmission;
                return float4(finalColor , texColor.a);
            }
            ENDHLSL
        }
    }
}
