Shader "Custom/Diffuse"
{   
	 Properties
    {
        _MainTex("Main Texture" , 2D) = "white" {}
        _EmissionTex("Emission Texture" , 2D) = "" {}
        [HDR] _EmissionColor("Emission Color" , Color) = (1,1,1,1)
        _EmissionIntensity("Emission Intensity" , Float) = 1
        _Gloss("Glossiness" , Float) = 1
        _FresnelIntensity("Fresnel Intensity" , Float) = 1
        _LightCutoffValue("Light Cutoff Value", Float) = 0.01
        _LightFalloffValue("Light Falloff Value" , Float) = 0.01
        _AmbientStrength("Ambient Strenght" , Float) = 1
        _DiffuseColor("Diffuse Color" , Color) = (1,1,1,1)
        _SpecularColor("Specular Color" , Color) = (1,1,1,1)
        _FresnelColor("Fresnel Color" , Color) = (1,1,1,1)
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct MeshData
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Interpolators
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: TEXCOORD1;
                float3 wPos : TEXCOORD2;
            };
       
            sampler2D _MainTex;
            sampler2D _EmissionTex;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _EmissionTex_ST;
                float4 _EmissionColor;
                float _EmissionIntensity;
                float _Gloss;
                float _FresnelIntensity;
                float _LightCutoffValue;
                float _LightFalloffValue;
                float _AmbientStrength;
                float4 _DiffuseColor;
                float4 _SpecularColor;
                float4 _FresnelColor;
            CBUFFER_END

            Interpolators vert(MeshData IN)
            {
                Interpolators OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.wPos = mul(unity_ObjectToWorld , IN.positionOS);
                return OUT;
            }

            float4 frag(Interpolators IN) : SV_Target
            {
                float4 texColor = tex2D(_MainTex,IN.uv);
                float4 emissionMask = tex2D(_EmissionTex,IN.uv);

                // Lighting
                Light mainLight = GetMainLight();
                float3 mlDirection = mainLight.direction;
                float3 mlColor = mainLight.color;
                float mldistanceAtt = mainLight.distanceAttenuation;
                float mlshadowAtt = mainLight.shadowAttenuation;

                // Diffuse Lighting
                float3 N = normalize(IN.normal);
                float3 L = normalize(mlDirection);
                float3 diffuseLight = saturate(dot(N,L)) * mlshadowAtt * mlColor;
                float3 diffuseCutOff = smoothstep(_LightCutoffValue , (_LightCutoffValue + _LightFalloffValue) , diffuseLight);
                float3 diffuseAmbient = max(diffuseCutOff , _AmbientStrength) * texColor.rgb * _DiffuseColor;
                float3 finalDiffuse;

                // Specular Lighting
                float3 V = normalize(_WorldSpaceCameraPos - IN.wPos);
                float3 R = reflect(-L,N);
                float3 specularLight = saturate(dot(V,R));
                specularLight = saturate(pow(specularLight , _Gloss)) * mlColor * mlshadowAtt;
                float3 specularCutOff = smoothstep(_LightCutoffValue , (_LightCutoffValue + _LightFalloffValue) , specularLight) * _SpecularColor;
        
               
                // Fresnel Lighting
                float fresnelLight =  pow(1.0 - saturate(dot(N, V)), _FresnelIntensity);
                float3 fresnelCutOff = smoothstep(_LightCutoffValue , (_LightCutoffValue + _LightFalloffValue) , fresnelLight) * _FresnelColor;
        

                // Emission Mask
                float3 finalEmission = emissionMask.rgb * _EmissionColor.rgb * _EmissionIntensity;

               

                float3 finalColor = diffuseAmbient + specularCutOff + finalEmission;
                return float4(finalColor , texColor.a);

                
            }
            ENDHLSL
        }
    }
}
