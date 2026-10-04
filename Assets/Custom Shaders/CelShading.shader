Shader "Custom/CelShading"
{
     Properties
    {   
        [Header(Main Textures)]
        [Space]
        [Space]
        _MainTex("Main Texture" , 2D) = "white" {}
        _ShadeTex1("Shaded Tex" ,2D) = "white" {}
        _ShadeStrength("Shade Strength" ,Range(0,1)) = 1
        
        [Header(Diffuse properties)]
        [Space]
        [Space]
        _DiffuseColor("Diffuse Color" , Color) = (1,1,1,1)
        _DiffuseStrength("Diffuse Strength" , Float) = 1
        _DiffuseThreshold("Diffuse Threshold", Float) = 0.01
        _DiffuseSmoothness("Diffuse Smoothness" , Float) = 0.01
       
        
        [Header(Specular properties)]
        [Space]
        [Space]
        _SpecularColor("Specular Color" , Color) = (1,1,1,1)
        _Gloss("Glossiness" , Float) = 1
        _SpecularThreshold("Specular Threshold" , Float) = 0.1
        _SpecularSmoothness("Specular Smoothness" , Float) = 0.1

        [Header(Fresnel properties)]
        [Space]
        [Space]
        _FresnelColor("Fresnel Color" , Color) = (1,1,1,1)
        _FresnelIntensity("Fresnel Intensity" , Float) = 1
        _FresnelThreshold("Fresnel Threshold" , Float) = 0.1
        _FresnelSmoothness("Fresnel Smoothness" , Float) = 0.1

        [Header(Ambient properties)]
        [Space]
        [Space]
        _AmbientStrength("Ambient Strength" , Float) = 1

        [Header(Emission properties)]
        [Space]
        [Space]
        [Toggle(_USE_Emission)] _UseEmission ("Use Emission", Float) = 0
        _EmissionTex("Emission Texture" , 2D) = "" {}
        _EmissionColor("Emission Color" , Color) = (1,1,1,1)
        _EmissionIntensity("Emission Intensity" , Float) = 1

        [Header(Shadows properties)]
        [Space]
        [Space]
        _ShadowSmoothness("Shadow Smoothness" , Range(0,1)) = 0.5
       
        [Header(Hatching properties)]
        [Space]
        [Space]
        [Toggle(_USE_HATCHING)] _UseHatching ("Use Hatching", Float) = 0
        _HatchTex("Hatch Texture" , 2D) = "white" {}
        _HatchMask("Hatch mask" ,2D) = "white" {}
        [HDR] _HatchColor("Hatch Color" , Color) = (1,1,1,1)
        _HatchThreshold("Hatch Threshold", Float) = 0.01
        _HatchSmoothness("Hatch Smoothness" , Float) = 0.01
        _HatchOpacity("Hatch Opacity" , Float) = 0.5

        [Header(Hatching Animation)]
        [Space]
        [Space]
        _AnimationSpeed("Animation Speed" , Float) = 1
        _AnimationOffset("Animation Offset" , Range(0,1)) = 0.37

        [Header(Outline)]
        [Space]
        [Space]
        _OutlineColor("Outline Color" , Color) = (0,0,0,1)
        _OutlineWidth("Outline Width" , Float) = 0.01

        [Header(Dissolve)]
        [Space]
        [Space]
        [Toggle(_USE_Dissolve)] _UseDissolve("Use Dissolve" , Float) = 0
        [HDR] _DissolveColor("Dissolve Color" , Color) = (1,1,1,1)
        [NoScaleOffset] _DissolveTex("Dissolve Tex" , 2D) = "white" {}
        _DissolveThreshold("Dissolve Threshold" , Float) = 0.1
        _DissolveThickness("Dissolve Thickness" , Float) = 0.1

        [Enum(UnityEngine.Rendering.BlendMode)]
            _SrcFactor("Src Factor", Float) = 5

        [Enum(UnityEngine.Rendering.BlendMode)]
            _DstFactor("Dst Factor" , Float) = 10

        [Enum(UnityEngine.Rendering.BlendOp)]
            _Opp("Operation" , Float) = 0     
        
    }

    SubShader
    {   
        Name "CelShadingPass"

        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}

        Blend [_SrcFactor] [_DstFactor]
        BlendOp [_Opp]

        Pass
        {   
            // Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _LIGHTS_PER_OBJECT
            
            // forward +
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP

            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma shader_feature _USE_HATCHING
            #pragma shader_feature _USE_Emission
            #pragma shader_feature _USE_Dissolve

            struct MeshData
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Interpolators
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS: TEXCOORD1;
                float3 wPos : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
                float3 normalOS : TEXCOORD4;
                float3 positionOS : TEXCOORD5;
                float2 hatchUV : TEXCOORD6; 
                float  fogCoord	: TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
       
            sampler2D _MainTex;
            sampler2D _EmissionTex;
            sampler2D _HatchTex;
            sampler2D _DissolveTex;
            sampler2D _ShadeTex1;
            sampler2D _HatchMask;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _HatchTex_ST;
                float4 _ShadeTex1_ST;
                float4 _HatchMask_ST;

                float _ShadeStrength;

                float4 _DiffuseColor;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float4 _EmissionColor;
                float4 _HatchColor;

                float _DiffuseStrength;
                float _DiffuseThreshold;
                float _DiffuseSmoothness;

                float _Gloss;
                float _SpecularThreshold;
                float _SpecularSmoothness;

                float _FresnelIntensity;
                float _FresnelThreshold;
                float _FresnelSmoothness;

                float _AmbientStrength;
                float _EmissionIntensity;
                float _ShadowSmoothness;

                float _UseHatching;
                float _HatchThreshold;
                float _HatchSmoothness;
                float _HatchOpacity;

                float _AnimationSpeed;
                float _AnimationOffset;

                float4 _OutlineColor;
                float _OutlineWidth;

                float _DissolveThreshold;
                float _DissolveThickness;
                float4 _DissolveColor;
                float4 _DissolveTex_ST;
            CBUFFER_END

            Interpolators vert(MeshData IN)
            {
                Interpolators OUT = (Interpolators)0;

                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.hatchUV = TRANSFORM_TEX(IN.uv, _HatchTex);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
                OUT.normalOS = IN.normal;
                OUT.positionOS = IN.positionOS.xyz;
                OUT.wPos = mul(unity_ObjectToWorld , IN.positionOS).xyz;
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.wPos);
                OUT.fogCoord = ComputeFogFactor(OUT.positionHCS.z);
                return OUT;
            }

            float4 frag(Interpolators IN) : SV_Target
            {   
                // Textures
                float4 texColor = tex2D(_MainTex,IN.uv);
                float4 shadeTex = tex2D(_ShadeTex1,IN.uv);
                float hatchMask = tex2D(_HatchMask,IN.uv).r;

                // Lighting Data
                Light mainLight = GetMainLight(IN.shadowCoord);
                float3 mlDirection = mainLight.direction;
                float3 mlColor = mainLight.color;
                float mldistanceAtt = mainLight.distanceAttenuation;
                float mlshadowAtt = mainLight.shadowAttenuation;
                float shadow = mainLight.shadowAttenuation;
                float shadowSmooth = smoothstep(_ShadowSmoothness,1.0,shadow);
                shadowSmooth = lerp(0.35, 1.0, shadowSmooth);

                float3 N = normalize(IN.normalWS); // NORMAL
                float3 L = normalize(mlDirection); // Light direction
                float3 V = normalize(_WorldSpaceCameraPos - IN.wPos); // View Angle
                float3 R = reflect(-L,N); // Relect Angle

                // Diffuse Lighting (CelShading)
                float diffuseLight = saturate(dot(N,L)) * 0.5 + 0.5;
                float diffuseSmooth = smoothstep(_DiffuseThreshold , (_DiffuseThreshold + _DiffuseSmoothness) , diffuseLight);
                float maxDiffuse = max(diffuseSmooth, _DiffuseStrength);
                float3 shadedAlbedo = lerp(texColor.rgb,texColor.rgb * shadeTex.rgb,_ShadeStrength);
                float3 finalDiffuse = maxDiffuse  * mlColor * shadedAlbedo * _DiffuseColor.rgb;
                // float3 finalDiffuse = shadowSmooth; 
                
                //Object-space Triplanar Hatching
                float3 finalHatch = 0;

                #if defined(_USE_HATCHING)
                
                    float3 p = IN.positionOS * _HatchTex_ST.x;
                    float phaseOffset = _AnimationOffset;
                    float animPhase = frac(_Time.y * _AnimationSpeed);
                    float3 p1 = p;
                    float3 p2 = p + phaseOffset;
                    float3 nOS = normalize(IN.normalOS);

                    float3 blend = abs(nOS);
                    blend /= (blend.x + blend.y + blend.z + 1e-5);

                    float3 hatchX = tex2D(_HatchTex, p1.yz).rgb;
                    float3 hatchY = tex2D(_HatchTex, p1.xz).rgb;
                    float3 hatchZ = tex2D(_HatchTex, p1.xy).rgb;

                    float3 hatchTex1 = hatchX * blend.x + hatchY * blend.y + hatchZ * blend.z;


                    float3 hatchX2 = tex2D(_HatchTex, p2.yz).rgb;
                    float3 hatchY2 = tex2D(_HatchTex, p2.xz).rgb;
                    float3 hatchZ2 = tex2D(_HatchTex, p2.xy).rgb;


                    float3 hatchTex2 = hatchX2 * blend.x + hatchY2 * blend.y + hatchZ2 * blend.z;

                    float hatchLight = saturate(1.0 - dot(N, L));
                    float hatchSmooth = smoothstep(_HatchThreshold - _HatchSmoothness,_HatchThreshold + _HatchSmoothness,hatchLight);
                    float hatchOpacitySmooth = smoothstep(0,_HatchOpacity,1.0 - mlshadowAtt); 
                    hatchSmooth *= shadowSmooth;

                
                    float hatchAnim = smoothstep(0.3, 0.7, animPhase);
                    float3 mixedHatch = lerp(hatchTex1, hatchTex2, hatchAnim);
                    float hatch = 1.0 - dot(mixedHatch, float3(0.333,0.333,0.333));
                    finalHatch = -hatch * hatchMask * hatchSmooth * _HatchColor.rgb * hatchOpacitySmooth;   
                #endif
                

                // Specular Lighting (CelShading)
                float specularLight = saturate(dot(V,R));
                specularLight = saturate(pow(specularLight , _Gloss));
                float specularSmooth = smoothstep(_SpecularThreshold , (_SpecularThreshold + _SpecularSmoothness) , specularLight);
                float3 finalSpecular = specularSmooth * mlColor * shadowSmooth * _SpecularColor.rgb;
               
                // Fresnel Lighting (CelShading)
                float fresnelLight =  1.0 - saturate(dot(N, V));
                fresnelLight = pow(fresnelLight , _FresnelIntensity);
                float fresnelSmooth = smoothstep(_FresnelThreshold , (_FresnelThreshold + _FresnelSmoothness) , fresnelLight);
                float3 finalFresnel = fresnelSmooth * _FresnelColor.rgb;

                // Ambient Lighting
                float ambientLight = saturate(dot(N,L));
                float3 maxAmbient = max(ambientLight , _AmbientStrength);
                float3 ambient = maxAmbient * SampleSH(N) * texColor.rgb * _DiffuseColor.rgb;
        
                //Emission mask
                float3 finalEmission = 0;

                #if defined(_USE_Emission)

                    float4 emissionTex = tex2D(_EmissionTex, IN.uv);
                    float mask = dot(emissionTex.rgb, float3(0.299, 0.587, 0.114)); // Use texture brightness as mask
                    finalEmission = emissionTex.rgb * _EmissionColor.rgb * _EmissionIntensity * mask;
                #endif

               

                // Additional Light Calculations
                InputData inputData = (InputData)0;
                inputData.positionWS = IN.wPos;
                inputData.normalWS = N;
                inputData.viewDirectionWS = V;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);

    
                // #if defined(_LIGHTS_PER_OBJECT)
                //     return float4(1, 0, 0, 1);
                // #endif

                
                float3 additionalDiffuse = 0;
                float3 additionalSpecular = 0;

                #if defined(_ADDITIONAL_LIGHTS)

                    uint pixelLightCount = GetAdditionalLightsCount();

                    LIGHT_LOOP_BEGIN(pixelLightCount)
                        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, half4(1,1,1,1));

                        float3 L = normalize(light.direction);
                        float3 R = reflect(-L, N);

                        float att = light.distanceAttenuation * light.shadowAttenuation;

                        // Toon diffuse (Additional)
                        float diff = saturate(dot(N, L)) * 0.5 + 0.5;
                        diff = smoothstep(_DiffuseThreshold,_DiffuseThreshold + _DiffuseSmoothness,diff);

                        additionalDiffuse += diff * att * light.color * texColor.rgb * _DiffuseColor.rgb;

                        // Toon specular (Additional)
                        float spec = pow(saturate(dot(V, R)), _Gloss);
                        float specStep = smoothstep(_SpecularThreshold,_SpecularThreshold + _SpecularSmoothness,spec);
                        additionalSpecular += specStep * att * light.color* _SpecularColor.rgb;

                    LIGHT_LOOP_END
                #endif

                // Final Output (CelShading)         
                float3 mixedColor = finalDiffuse + additionalDiffuse + additionalSpecular + finalSpecular + finalFresnel + ambient + finalEmission + finalHatch;
                float4 finalOutput = float4(mixedColor,1);
                finalOutput.rgb = MixFog(finalOutput.rgb, IN.fogCoord);

                // Dissolve Shader
                float dissolveStepUp = 1;
                float3 finalDissolve = finalOutput;
                float visibleMask = 1;

                #if defined (_USE_Dissolve)
                    float threshold = saturate(_DissolveThreshold);
                    float thickness = saturate(_DissolveThickness);
                    float4 dissolveTex = tex2D(_DissolveTex,IN.positionOS);
                    float dissolveValue = saturate(dissolveTex.r);
                    visibleMask = step(dissolveValue,threshold);
                    dissolveStepUp = step(dissolveValue,threshold + thickness);
                    float dissolveStepDown = step(dissolveTex.r,threshold - thickness);
                    float dissolveDifference = dissolveStepUp - dissolveStepDown;
                    finalDissolve = lerp(finalOutput,_DissolveColor,dissolveDifference);
                #endif

                return float4(finalDissolve.rgb , finalOutput.a * visibleMask);

            }
            ENDHLSL
        }
        
        //Outline
        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            Cull Front
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _HatchTex_ST;
                float4 _ShadeTex1_ST;
                float4 _HatchMask_ST;
                float _ShadeStrength;

                float4 _DiffuseColor;
                float4 _SpecularColor;
                float4 _FresnelColor;
                float4 _EmissionColor;
                float4 _HatchColor;

                float _DiffuseStrength;
                float _DiffuseThreshold;
                float _DiffuseSmoothness;

                float _Gloss;
                float _SpecularThreshold;
                float _SpecularSmoothness;

                float _FresnelIntensity;
                float _FresnelThreshold;
                float _FresnelSmoothness;

                float _AmbientStrength;
                float _EmissionIntensity;
                float _ShadowSmoothness;

                float _UseHatching;
                float _HatchThreshold;
                float _HatchSmoothness;
                float _HatchOpacity;

                float _AnimationSpeed;
                float _AnimationOffset;

                float4 _OutlineColor;
                float _OutlineWidth;

                float _DissolveThreshold;
                float _DissolveThickness;
                float4 _DissolveColor;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                // Get clip position 
                float4 clipPos = TransformWorldToHClip(positionWS);

                // Depth-based scaling
                float depthScale = clipPos.w * 0.01;
                depthScale = clamp(depthScale, 0.5, 3.0); // safety clamp

                // Extrude along normal
                positionWS += normalWS * _OutlineWidth * depthScale;

                // Final clip position
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {   
                return _OutlineColor;
            }

            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
