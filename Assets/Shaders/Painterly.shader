Shader "Custom/PainterlyURP"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [HDR] _SpecularColor("Specular Color", Color) = (1,1,1,1)

        _MainTex ("Albedo", 2D) = "white" {}
        [Normal]_Normal ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(-2, 2)) = 1

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _ShadingGradient("Shading Gradient", 2D) = "white" {}
        _PainterlyGuide("Painterly Guide", 2D) = "white" {}
        _PainterlySmoothness("Painterly Smoothness", Range(0,1)) = 0.1
    }

    SubShader
    {
        Tags{ "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque" }

        Pass
        {
            Name "ForwardLit"
            Tags{ "LightMode"="UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ SCREEN_SPACE_OCCLUSION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);
            TEXTURE2D(_Normal);        SAMPLER(sampler_Normal);
            TEXTURE2D(_PainterlyGuide);SAMPLER(sampler_PainterlyGuide);
            TEXTURE2D(_ShadingGradient);SAMPLER(sampler_ShadingGradient);

            float4 _Color;
            float4 _SpecularColor;

            float _Glossiness;
            float _Metallic;
            float _NormalStrength;
            float _PainterlySmoothness;

            struct VIn
            {
                float4 pos : POSITION;
                float2 uv  : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct VOut
            {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
            };

            VOut vert(VIn v)
            {
                VOut o;
                o.pos = TransformObjectToHClip(v.pos.xyz);
                o.uv = v.uv;
                o.worldPos = TransformObjectToWorld(v.pos.xyz);

                o.normalWS = normalize(TransformObjectToWorldNormal(v.normal));
                o.tangentWS = normalize(TransformObjectToWorldDir(v.tangent.xyz));
                o.bitangentWS = cross(o.normalWS, o.tangentWS) * v.tangent.w;

                return o;
            }

            float3 GetNormal(VOut i)
            {
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal, i.uv), _NormalStrength);
                float3x3 TBN = float3x3(i.tangentWS, i.bitangentWS, i.normalWS);
                return normalize(mul(normalTS, TBN));
            }

            float4 frag(VOut i) : SV_Target
            {
                float4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;

                float3 N = GetNormal(i);
                float3 V = normalize(GetWorldSpaceViewDir(i.worldPos));

                // main directional light
                Light mainLight = GetMainLight();

                float3 L = normalize(mainLight.direction);
                float NdotL = saturate(dot(N, L) + 0.2);

                float painterlyGuide = SAMPLE_TEXTURE2D(_PainterlyGuide, sampler_PainterlyGuide, i.uv).r;

                float diff = smoothstep(
                    painterlyGuide - _PainterlySmoothness,
                    painterlyGuide + _PainterlySmoothness,
                    NdotL
                );

                // specular
                float3 R = reflect(-L, N);
                float vDotR = dot(V, R);

                float specThreshold = painterlyGuide + _Glossiness;

                float specFactor = smoothstep(
                    specThreshold - _PainterlySmoothness,
                    specThreshold + _PainterlySmoothness,
                    vDotR
                ) * _Glossiness;

                float3 spec = _SpecularColor.rgb * mainLight.color * specFactor;

                float3 grad = SAMPLE_TEXTURE2D(_ShadingGradient, sampler_ShadingGradient, float2(diff, 0)).rgb;

                float3 color = (albedo.rgb * grad * mainLight.color + spec);

                return float4(color, albedo.a);
            }

            ENDHLSL
        }
    }
}
