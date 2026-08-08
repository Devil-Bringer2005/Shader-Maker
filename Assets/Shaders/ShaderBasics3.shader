Shader "vertex/ShaderBasics3"
{
    Properties
    {
        _MainTexture("Main Texture" , 2D) = "white" {} 
        _Amplitude("Amplitide" , Float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" 
        "Queue" = "Geometry"
        "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            # define TAU 6.283185
           
            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0; // uv for texture mapping
                float3 normals : NORMAL;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTexture;
            float4 _MainTexture_ST;
            float _Amplitude;

            float InverseLerp(float a , float b , float v)
            {
                return (v-a)/(b-a);
            }

            Interpolators vert(MeshData IN)
            {
                Interpolators OUT;

                // float wavesY = cos((IN.uv0.y - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                // float wavesX = cos((IN.uv0.x - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                // IN.vertex.y = wavesY * wavesX * _Amplitude;
                float sinValue = 1 - pow(abs(sin(3.14 * IN.uv0 / 2.0)),2.0);
                float2 uvCentered = IN.uv0 - 0.5;
                float radialDistance = length(uvCentered);

                //float waves = cos((radialDistance.xxx - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                float waves = cos((sinValue.xxx - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                IN.vertex.y = waves * _Amplitude;


                OUT.vertex = TransformObjectToHClip(IN.vertex);
                OUT.normal = TransformObjectToWorldNormal(IN.normals);
                //OUT.uv = TRANSFORM_TEX(IN.uv0 , _MainTexture);
                OUT.uv = IN.uv0;
                OUT.normal = IN.normals;
                return OUT;
            }

            float4 frag(Interpolators IN) : SV_Target
            {
                float4 textureColor = tex2D(_MainTexture , IN.uv);  

                float2 uvCentered = IN.uv - 0.5;
                float radialDistance = length(uvCentered);

                float sinValue = 1 - pow(abs(sin(3.14 * IN.uv / 2.0)),2.0);
                //float waves = cos((radialDistance.xxx - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                //float waves = cos((sinValue.xxx - _Time.y * 0.1) * TAU * 5) * 0.5 + 0.5;
                //return waves;
                return textureColor;
            }
            ENDHLSL
        }
    }
}
