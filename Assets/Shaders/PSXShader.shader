Shader "PSX/PSXShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _SnapIntensity("Snap Intensity", Range(0.001, 0.05)) = 0.005
        _DitherIntensity("Dither Intensity", Range(0.001, 0.2)) = 0.1
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "Queue" = "Geometry"
            "RenderType"="Opaque" 
            "LightMode" = "UniversalForward"
        }
        LOD 100

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _SnapIntensity;
            float _DitherIntensity;
            CBUFFER_END

            struct VertexInput 
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VertexOutput 
            {
                float4 positionCS	: SV_POSITION;
                noperspective float2 uv : TEXCOORD0;
            };

            float2 SnapToGrid(float2 value, float snapValue)
            {
                return floor(value / snapValue + 0.5) * snapValue;
            }

            float dither(float2 uv, float ditherIntensity)
            {
                int x = int(fmod(uv.x * 4.0, 4.0));
                int y = int(fmod(uv.y * 4.0, 4.0));

                float bayerMatrix[4][4] = {
                    { 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0 },
                    { 12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0 },
                    { 3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0 },
                    { 15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0 }
                };

                return bayerMatrix[x][y] * ditherIntensity;
            }

        ENDHLSL

        Pass
        {
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;

                o.positionCS = TransformObjectToHClip(i.positionOS);

                float2 screenPos = o.positionCS.xy / o.positionCS.w;
                screenPos = SnapToGrid(screenPos, _SnapIntensity);
                o.positionCS.xy = screenPos * o.positionCS.w;

                o.uv = TRANSFORM_TEX(i.uv, _MainTex);

                return o;
            }

            float4 frag(VertexOutput i) : SV_Target
            {
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                float ditherValue = dither(i.uv, _DitherIntensity);

                col.rgb = floor(col.rgb / _DitherIntensity + ditherValue) * _DitherIntensity;

                return col;
            }
            
            ENDHLSL
        }
    }
}
