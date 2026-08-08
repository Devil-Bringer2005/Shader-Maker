Shader "Custom/ArcSystemCelShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)

        _LightDir ("Light Direction", Vector) = (0,0,1,0)
        _ShadowThreshold ("Shadow Threshold", Range(0,1)) = 0.5

        _ShadowColor ("Shadow Color", Color) = (0.25,0.25,0.3,1)
        _HighlightColor ("Highlight Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                float2 uv         : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            float3 _LightDir;
            float _ShadowThreshold;
            float4 _ShadowColor;
            float4 _HighlightColor;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);
                float3 lightDir = normalize(_LightDir);

                float NdotL = dot(normal, lightDir);
                float shade = step(_ShadowThreshold, NdotL);

                float4 albedo = tex2D(_MainTex, IN.uv) * _Color;

                float4 litColor = lerp(_ShadowColor, _HighlightColor, shade);
                return albedo * litColor;
            }
            ENDHLSL
        }
    }
}
