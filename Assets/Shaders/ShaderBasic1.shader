Shader "Custom/ShaderBasic1"
{
    Properties
    {
        _MainTex("Main Texture" , 2D) = "white" {} 
        [HDR] _MainColor1("Main Color A" , Color) = (1,1,1,1)
        [HDR] _MainColor2("Main Color B" , Color) = (1,1,1,1)
        _ColorStart("Color Start" , Range(0,1)) = 0
        _ColorEnd("Color End" , Range(0,1)) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" 
        "RenderPipeline" = "UniversalPipeline" }

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
                float3 normals : NORMAL;
            };

            struct Interpolators
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainColor1;
            float4 _MainColor2;

            float _ColorStart;
            float _ColorEnd;

            Interpolators vert(MeshData IN)
            {
                Interpolators OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.vertex.xyz);
                OUT.normal = TransformObjectToWorldNormal(IN.normals);
                //OUT.uv = IN.uv0;
                OUT.uv = TRANSFORM_TEX(IN.uv0 , _MainTex);
                OUT.normal = IN.normals;
                return OUT;
            }

            float InverseLerp(float a , float b , float v)
            {
                return (v-a)/(b-a);
            }

            float4 frag(Interpolators IN) : SV_Target
            {
                float2 uvs = IN.uv;
                // float4 mainColor = _MainColor1;
                float4 textureColor = tex2D(_MainTex , uvs);

                

                float4 t = saturate(InverseLerp(_ColorStart ,_ColorEnd,IN.uv.x)); // saturate is clamp01(clamp between 0 and 1)
                float4 outputColor = lerp(_MainColor1 ,_MainColor2,t);


                //return float4(IN.normal ,1);
                // return float4(IN.uv.xxx,1);
                return outputColor;
                // return(uvs ,0,1);
                // return textureColor * mainColor;
            }
            ENDHLSL
        }
    }
}
