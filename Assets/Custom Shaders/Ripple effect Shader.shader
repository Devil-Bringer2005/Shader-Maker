Shader "Custom/RippleeffectShader"
{
    Properties
    {
        [MainColor][HDR] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        // _RippleColor("Ripple Color" , Color) = (1, 1, 1, 1)
        _RippleTexture("Ripple Texture" , 2D) = "white"
        _RippleIntensity("Ripple Intensity" , Float) = 1
        _RippleSpeed("Ripple Speed" , Float) = 1

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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uvBase : TEXCOORD0;
                float2 uvRipple : TEXCOORD1;
            };

            sampler2D _RippleTexture;
            sampler2D _BaseMap;
          

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _RippleColor;
                float4 _BaseMap_ST;
                float4 _RippleTexture_ST;
                float _RippleSpeed;
                float _RippleIntensity;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvBase = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uvRipple = TRANSFORM_TEX(IN.uv ,_RippleTexture);

                uvRipple = (1 - (length(IN.uvRipple - 0.5) * _RippleIntensity))  + _Time.y * _RippleSpeed;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //float2 rippleUV = (1 - (length(IN.uvRipple - 0.5) * _RippleIntensity))  + _Time.y * _RippleSpeed;
                half4 color = tex2D(_BaseMap, rippleUV) * _BaseColor;
                //half4 rippleColor = tex2D(_RippleTexture,rippleUV);
                return color;
            }
            ENDHLSL
        }
    }
}
