Shader "Custom/Shader1"
{
    Properties
    {
        _Color("Main Color" , Color) = (1,1,1,1)
        [HDR] _EmissionColor("Emission Color" , Color) = (1,1,1,1)

        _MainTexture("Main Texture" , 2D) = "white" {}
        _AnimateXY("Animate X Y" , Vector) = (0,0,0,0)

        // _EmissiveIntensity("Emission Intensity" , Float) = 1

        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcFactor("Src Factor", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstFactor("Dst Factor" , Float) = 10
        [Enum(UnityEngine.Rendering.BlendOp)]
        _Opp("Operation" , Float) = 0


    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Blend [_SrcFactor] [_DstFactor]
        BlendOp [_Opp]
        
        //Blend One Zero
        // blend formula
        // source = whatever this shader outputs
        // destination = whatever is in the Background

        // source * (SourceAlpha) + destination * (destinationAlpha)


        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct MeshData // per-vertex mesh data
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;// Actaul UV channel (We can use multiple)
                float3 normal : NORMAL; 
            };

            struct v2f // Vertex to Fragment Shader (struct used to pass data from vertex to fragment)
            {
                float4 vertex : SV_POSITION; // clip space position
                float2 uv : TEXCOORD0; // just a container like this 
                float3 normal : NORMAL;
            };

            float4 _Color;
            float4 _EmissionColor;
            sampler2D _MainTexture;
            // Float _EmissiveIntensity;
            float4 _MainTexture_ST;
            float4 _AnimateXY;

            v2f vert(MeshData IN) // Vertex Shader
            {   
                v2f OUT;
                OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv , _MainTexture);
                OUT.uv += frac(_AnimateXY.xy * _MainTexture_ST.xy *_Time.yy);
                OUT.normal = IN.normal;
                return OUT;
            }

            float4 frag(v2f IN) : SV_Target // Fragment Shader
            {   
                float2 uvs = IN.uv;
                //return float4(uvs,0,1);

                float4 textureColor = tex2D(_MainTexture,uvs);
                float4 color = _Color;
                float4 emissionColor = _EmissionColor;
                return textureColor * color * emissionColor;
                
            }
            ENDHLSL
        }
    }
}
