Shader "Custom/SlashDistortionURP"
{
    Properties
    {
        _NormalTex("Distortion Normal", 2D) = "bump" {}
        _DistortionStrength("Distortion Strength", Range(0,0.1)) = 0.03
        _ScrollSpeed("Scroll Speed", Vector) = (1,0,0,0)
        _Transparency("Alpha", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
                float _DistortionStrength;
                float4 _ScrollSpeed;
                float _Transparency;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                // Screen UV
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;

                // Scroll normal map
                float2 scrollUV = IN.uv + _ScrollSpeed.xy * _Time.y;

                // Sample & unpack normal
                float3 normal = UnpackNormal(
                    SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, scrollUV)
                );

                // Offset screen UV using normal XY
                screenUV += normal.xy * _DistortionStrength;

                // Sample scene color
                float4 sceneColor =
                    SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);

                sceneColor.a = _Transparency;
                return sceneColor;
            }
            ENDHLSL
        }
    }
}
