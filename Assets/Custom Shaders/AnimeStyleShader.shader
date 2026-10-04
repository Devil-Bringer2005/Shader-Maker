Shader "Custom/AnimeStyleShader"
{
    Properties
    {
        [Header(Main Textures)]
        _MainTex ("Main Texture", 2D) = "white" {}

        [Header(Diffuse Properties)]
        _DiffuseColor ("Diffuse Color", Color) = (1,1,1,1)
        _DiffuseThreshold ("Diffuse Threshold", Float) = 0.01
        _DiffuseSmoothness ("Diffuse Smoothness", Float) = 0.01
        _AmbientStrength ("Ambient Strength", Float) = 1

        [Header(Specular Properties)]
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Gloss ("Glossiness", Float) = 1
        _SpecularThreshold ("Specular Threshold", Float) = 0.1
        _SpecularSmoothness ("Specular Smoothness", Float) = 0.1

        [Header(Fresnel Properties)]
        _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FresnelIntensity ("Fresnel Intensity", Float) = 1
        _FresnelThreshold ("Fresnel Threshold", Float) = 0.1
        _FresnelSmoothness ("Fresnel Smoothness", Float) = 0.1

        [Header(Emission Properties)]
        _EmissionTex ("Emission Texture", 2D) = "black" {}
        _EmissionColor ("Emission Color", Color) = (1,1,1,1)
        _EmissionIntensity ("Emission Intensity", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }


        Pass
        {
            Name "CelShadingPass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct MeshData
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normal     : NORMAL;
            };

            struct Interpolators
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float3 worldPos    : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            sampler2D _MainTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _DiffuseColor;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float  _Gloss;
                float  _FresnelIntensity;
                float  _DiffuseThreshold;
                float  _DiffuseSmoothness;
                float  _SpecularThreshold;
                float  _SpecularSmoothness;
                float  _FresnelThreshold;
                float  _FresnelSmoothness;
                float  _AmbientStrength;
            CBUFFER_END

            Interpolators vert (MeshData IN)
            {
                Interpolators OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normal);
                OUT.worldPos    = mul(unity_ObjectToWorld, IN.positionOS).xyz;
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.worldPos);
                return OUT;
            }

            float4 frag (Interpolators IN) : SV_Target
            {
                float3 albedo = tex2D(_MainTex, IN.uv).rgb;

                Light mainLight = GetMainLight(IN.shadowCoord);

                float3 N = normalize(IN.normalWS);
                float3 L = normalize(mainLight.direction);
                float3 V = normalize(_WorldSpaceCameraPos - IN.worldPos);
                float3 H = normalize(L + V);

                /* Diffuse (Cel) */
                float diff = saturate(dot(N, L));
                diff = diff * 0.5 + 0.5;
                diff = smoothstep(
                    _DiffuseThreshold - _DiffuseSmoothness,
                    _DiffuseThreshold + _DiffuseSmoothness,
                    diff
                );

                float diffuseFinal = lerp(_AmbientStrength, 1.2, diff);
                float3 finalDiffuse = diffuseFinal * albedo * _DiffuseColor.rgb;

                /* Specular (Cel) */
                float spec = pow(saturate(dot(N, H)), _Gloss);
                spec = smoothstep(
                    _SpecularThreshold - _SpecularSmoothness,
                    _SpecularThreshold + _SpecularSmoothness,
                    spec
                );

                float3 finalSpecular =
                    spec * mainLight.color * mainLight.shadowAttenuation * _SpecularColor.rgb;

                /* Fresnel */
                float fresnel = 1.0 - saturate(dot(N, V));
                fresnel = pow(fresnel, _FresnelIntensity);
                fresnel = smoothstep(
                    _FresnelThreshold - _FresnelSmoothness,
                    _FresnelThreshold + _FresnelSmoothness,
                    fresnel
                );

                float3 finalFresnel = fresnel * _FresnelColor.rgb;

                float3 finalColor = finalDiffuse + finalSpecular + finalFresnel;
                return float4(finalColor, 1.0);
            }

            ENDHLSL
        }


        Pass
        {
            Name "EmissionPass"
            Tags { "LightMode" = "UniversalForward" }

            Blend One One
            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct MeshData
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            sampler2D _EmissionTex;
            float4 _EmissionTex_ST;
            float4 _EmissionColor;
            float  _EmissionIntensity;

            Interpolators vert (MeshData IN)
            {
                Interpolators OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _EmissionTex);
                return OUT;
            }

            float4 frag (Interpolators IN) : SV_Target
            {
                float3 emission = tex2D(_EmissionTex, IN.uv).rgb;
                float mask = dot(emission, float3(0.299, 0.587, 0.114));
                float3 finalEmission = emission * _EmissionColor.rgb * _EmissionIntensity * mask;
                return float4(finalEmission, 1.0);
            }

            ENDHLSL
        }
    }
}
