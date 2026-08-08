Shader "Custom/OilPaintEffect"
{
    Properties
    {
        _MainTex("Main Texture" , 2D) = "white" {}
        [HDR] _MainColor("Main Color" , Color) = (1,1,1,1)

        [Normal] _NormalTex("Normal Texture" , 2D) = "bump" {}
        _NormalStrength("Normal Strength" , Range(-2,2)) = 1
        
        [HDR] _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _Glossiness("Gloss" , Range(0,1)) = 0.5

        _ShadingGradient("Shading Gradient" , 2D) = "white" {}
        _OilPaintGuide("Paint Guide" ,2D) = "white" {}
        _OilPaintSmoothness("Paint Smoothness" , Range(0,1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag



            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"



            struct MeshData
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct Interpolator
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
                float3 wPos : TEXCOORD4;
                float3 tangentWS : TEXCOORD5;
                float3 bitangentWS : TEXCOORD6;
            };


            sampler2D _MainTex;
            sampler2D _NormalTex;
            sampler2D _ShadingGradient;
            sampler2D _OilPaintGuide;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _MainColor;
                float4 _SpecularColor;
                float _NormalStrength;
                float _Glossiness;
                float _OilPaintSmoothness;
            CBUFFER_END

  

            Interpolator vert(MeshData IN)
            {
                Interpolator OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normal = IN.normal;
                float3 normalWS = TransformObjectToWorldNormal(IN.normal);
                float3 tangentWS = TransformObjectToWorldDir(IN.tangent.xyz);
                float3 bitangentWS = cross(normalWS, tangentWS) * IN.tangent.w;

                OUT.tangentWS = tangentWS;
                OUT.bitangentWS = bitangentWS;
                OUT.normalWS = normalWS;
                OUT.wPos = mul(unity_ObjectToWorld , IN.positionOS).xyz;
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.wPos);
                return OUT;
            }

            float4 frag(Interpolator IN) : SV_Target
            {   
                // All Textures Maps
                float4 mainTex = tex2D(_MainTex , IN.uv);
                float4 oilGuideTex = tex2D(_OilPaintGuide, IN.uv);
                float3 normalTS = UnpackNormal(tex2D(_NormalTex,IN.uv)); // converts to normal map 
                normalTS.xy *= _NormalStrength;  // normal intensity
                normalTS = normalize(normalTS);
                
                float3x3 TBN = float3x3(
                    normalize(IN.tangentWS),
                    normalize(IN.bitangentWS),
                    normalize(IN.normalWS)
                );

                // Lighting Data
                Light mainLight = GetMainLight(IN.shadowCoord);
                float3 mlDirection = mainLight.direction;
                float3 mlColor = mainLight.color;
                float mldistanceAtt = mainLight.distanceAttenuation;
                float mlshadowAtt = mainLight.shadowAttenuation;

                // Lighting Variables
                float3 N = normalize(mul(normalTS,TBN)); // NORMAL
                float3 L = normalize(mlDirection); // Light direction
                float3 V = normalize(_WorldSpaceCameraPos - IN.wPos); // View Angle
                float3 R = reflect(-L,N); // Relect Angle
                float3 H = normalize(L + V);

                // Diffuse Lighting
                float diffuse = saturate(dot(N,L));
                diffuse = saturate(diffuse + 0.5);
                float diffuseStep = smoothstep(oilGuideTex.r - _OilPaintSmoothness , oilGuideTex.r + _OilPaintSmoothness , diffuse);
                // float diffuseStep2 = smooth

                // Specular Lighting
                //float specular = pow(saturate(dot(N, H)), _Glossiness);
                float specular = saturate(dot(R ,V));
                specular = saturate(pow(specular,_Glossiness * 128)); 
                float specularThreshold = oilGuideTex.r + _Glossiness;
                float specularStep = smoothstep(specularThreshold - _OilPaintSmoothness, specularThreshold + _OilPaintSmoothness, specular);
                

                // Oilpaint attenuation
                float oilAtt = smoothstep(oilGuideTex.r - _OilPaintSmoothness, oilGuideTex.r + _OilPaintSmoothness, mldistanceAtt * mlshadowAtt);
                
                // Gradient ramp
                float4 ramp = tex2D(_ShadingGradient, float2(diffuseStep, 0.5));

                float3 finalColor = ((mainTex.rgb * ramp.rgb * mlColor.rgb) + (specularStep * _SpecularColor.rgb * mlColor.rgb )) * oilAtt * _MainColor;

                return float4 (finalColor,1);
            
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
