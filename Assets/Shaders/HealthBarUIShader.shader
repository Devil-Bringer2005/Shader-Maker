Shader "UI/HealthBarUIShader"
{
    Properties
    {   
        [PerRenderData] _MainTex("Main Texture" , 2D) = "white" {} 
        [NoScaleOffset] _MaskTex("Mask Texture" , 2D) = "white" {}
        [HDR] _MainColor1("Main Color A" , Color) = (1,1,1,1)
        [HDR] _MainColor2("Main Color B" , Color) = (1,1,1,1)
        _ColorStart("Color Start" , Range(0,1)) = 0
        _ColorEnd("Color End" , Range(0,1)) = 1
        _HealthValue("Health Value" , Range(0,1)) = 1
        _AnimateXY("Animate XY" , Vector) = (0,0,0,0)
        _HealthFlashValue("Health Flashing Value", Range(0,1)) = 1
        _FlickerSpeed("Flicker Speed" , Float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" 
        "RenderPipeline" = "UniversalPipeline"  "CanUseSpriteAtlas" = "True" }

        Blend SrcAlpha OneMinusSrcAlpha
        ZTest Always
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
           


            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0; // uv for texture mapping
                float4 color : COLOR;
            };

            struct Interpolators
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0; // uv for texture tilling
                float2 uvGradient : TEXCOORD1; // uv for gradient mapping
                float2 uvMask : TEXCOORD2;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;

            float4 _MainTex_ST;
            float4 _MaskTex_ST;

            float4 _MainColor1;
            float4 _MainColor2;

            float _ColorStart;
            float _ColorEnd;

            float _HealthValue;
            float _HealthFlashValue;
            float4 _AnimateXY;
            float _FlickerSpeed;

            Interpolators vert(MeshData IN)
            {
                Interpolators OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.vertex.xyz);

                // Tiled texture UV
                OUT.uv = TRANSFORM_TEX(IN.uv0, _MainTex);
                OUT.uvMask = TRANSFORM_TEX(IN.uv0 ,_MaskTex);

                // Non-tiled gradient UV
                OUT.uvGradient = IN.uv0;

                // Getting color of the image component
                OUT.color = IN.color;

                //Movement of texture
                OUT.uv += frac(_AnimateXY.xy * _MainTex_ST.xy *_Time.yy);

                return OUT;
            }

            float InverseLerp(float a , float b , float v)
            {
                return (v-a)/(b-a);
            }

            float4 frag(Interpolators IN) : SV_Target
            {   
                float4 texColor = IN.color;
                
                // Tile the texture based on tilling and offset
                float4 mainTexture = tex2D(_MainTex , IN.uvMask);
                float4 movingTex = tex2D(_MaskTex, IN.uv);

                float4 t = saturate(InverseLerp(_ColorStart ,_ColorEnd,IN.uvGradient.x)); // saturate is clamp01(clamp between 0 and 1)
                
                float4 outputColor = lerp(_MainColor1 ,_MainColor2,t);
                float4 outputColorGradient = lerp(_MainColor1 ,_MainColor2,_HealthValue);

                float barRevealAmount = step(IN.uvMask.x, _HealthValue);
                float4 finalOutput = float4(mainTexture.rgb , mainTexture.a * barRevealAmount) * outputColor * texColor * movingTex;
               

                if(_HealthValue <= _HealthFlashValue)
                {
                     float flickerAmount = saturate(0.8 + 0.15 * sin(_Time.y * _FlickerSpeed));
                     finalOutput *= flickerAmount; 
                }

                // return finalOutput; 
                return outputColorGradient * finalOutput;
            }
            ENDHLSL
        }
    }
}
