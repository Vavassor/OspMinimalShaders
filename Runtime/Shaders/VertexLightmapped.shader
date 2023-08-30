// A shader that supports vertex lightmaps.
Shader "OSP Minimal/Vertex Lightmapped"
{
    Properties
    {
       _MainTex("Albedo", 2D) = "white" {}
       _Color("Color", Color) = (1,1,1,1)
       _ScrollVelocity("Scroll Velocity", Vector) = (0, 0, 0, 0)
       [Toggle(USE_GAMMA_SPACE)] _UseGammaSpace("Use Gamma Space Blending", Float) = 0

       [Header(Multitexturing)]
       [Toggle(USE_MULTITEXTURING)] _UseMultitexturing("Multitexturing", Float) = 0
       _Texture2("Texture 2", 2D) = "white" {}
       _Texture2Color("Texture 2 Color", Color) = (1,1,1,1)
       _CombineBlend("Combine Blend", Range(0, 1)) = 0.5
       _Texture2ScrollVelocity("Scroll Velocity", Vector) = (0, 0, 0, 0)

       [KeywordEnum(None, Custom, Bakery Lightmaps)] _VertexColorMode("Vertex Color Mode", Float) = 0

       [Header(Alpha Test)]
       [Toggle(USE_ALPHA_TEST)] _UseAlphaTest("Alpha Test", Float) = 0
       _AlphaCutoff("Alpha Cutoff", Float) = 0.5

       [Header(Color Blending)]
       [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", Float) = 1 //"One"
       [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DestBlend", Float) = 0 //"Zero"
       [Enum(Add,0,Sub,1,RevSub,2,Min,3,Max,4)] _BlendOp("Blend Operation", Float) = 0 // "Add"

       [Header(Depth Test)]
       [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LessEqual"
       [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1.0 //"On"
       _OffsetFactor("Offset Factor", Range(-1, 1)) = 0
       _OffsetUnits("Offset Units", Range(-1, 1)) = 0

       [Header(Culling)]
       [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Blend [_SrcBlend] [_DstBlend]
        BlendOp [_BlendOp]
        ZTest[_ZTest]
        ZWrite[_ZWrite]
        Cull [_Cull]
        Offset [_OffsetFactor], [_OffsetUnits]

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nodirlightmap nodynlightmap novertexlight
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile _VERTEXCOLORMODE_NONE _VERTEXCOLORMODE_CUSTOM _VERTEXCOLORMODE_BAKERY_LIGHTMAPS
            #pragma shader_feature_local USE_ALPHA_TEST
            #pragma shader_feature_local USE_MULTITEXTURING
            #pragma shader_feature_local USE_GAMMA_SPACE

            #define USING_FOG (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            uniform float4 _Color;
            UNITY_DECLARE_TEX2D(_MainTex);
            float4 _MainTex_ST;
            float2 _ScrollVelocity;

            UNITY_DECLARE_TEX2D(_Texture2);
            float4 _Texture2_ST;
            float4 _Texture2Color;
            float _CombineBlend;
            float2 _Texture2ScrollVelocity;

            float _AlphaCutoff;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normal : NORMAL;
#if defined(_VERTEXCOLORMODE_CUSTOM) || defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
                float4 color : COLOR0;
#endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
#ifdef USE_MULTITEXTURING
                float2 uv1 : TEXCOORD1;
#endif
#if defined(LIGHTMAP_ON)
                float2 uv2 : TEXCOORD2;
#endif
#if defined(_VERTEXCOLORMODE_CUSTOM) || defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
                float4 color : TEXCOORD4;
#endif
                SHADOW_COORDS(5)
#if USING_FOG
                fixed fog : TEXCOORD6;
#endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_OUTPUT(vertexOutput, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.pos = UnityObjectToClipPos(input.vertex);

                output.uv0 = TRANSFORM_TEX(input.uv0, _MainTex) + _Time.y * _ScrollVelocity;

#ifdef USE_MULTITEXTURING
                output.uv1 = TRANSFORM_TEX(input.uv0, _Texture2) + _Time.y * _Texture2ScrollVelocity;
#endif

#if defined(LIGHTMAP_ON)
                output.uv2 = input.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#ifdef _VERTEXCOLORMODE_BAKERY_LIGHTMAPS
                // Decode baked HDR vertex color (RGBM)
                output.color = input.color;
                output.color.rgb *= input.color.a * 8.0;
                output.color.rgb *= output.color.rgb;
#endif

#ifdef _VERTEXCOLORMODE_CUSTOM
                output.color = input.color;
#endif
                
                TRANSFER_SHADOW(output)
                
#if USING_FOG
                float3 eyePos = UnityObjectToViewPos(input.vertex);
                float fogCoord = length(eyePos.xyz);
                UNITY_CALC_FOG_FACTOR_RAW(fogCoord);
                output.fog = saturate(unityFogFactor);
#endif

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                UNITY_APPLY_DITHER_CROSSFADE(input.pos.xy);

                float4 texture1Color = UNITY_SAMPLE_TEX2D(_MainTex, input.uv0);
#ifdef USE_GAMMA_SPACE
                texture1Color.rgb = LinearToGammaSpace(texture1Color.rgb);
#endif
                float4 albedo = _Color * texture1Color;

#ifdef USE_MULTITEXTURING
                float4 texture2Color = _Texture2Color * UNITY_SAMPLE_TEX2D(_Texture2, input.uv1);
#ifdef USE_GAMMA_SPACE
                texture2Color.rgb = LinearToGammaSpace(texture2Color.rgb);
#endif // USE_GAMMA_SPACE
                albedo = lerp(albedo, texture2Color, _CombineBlend);
#endif // USE_MULTITEXTURING

#ifdef USE_ALPHA_TEST
                clip(albedo.a - _AlphaCutoff);
#endif

                float4 indirectLight = albedo;

#if defined(_VERTEXCOLORMODE_CUSTOM) || defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
                indirectLight.rgb *= input.color.rgb;
#endif

#ifdef USE_GAMMA_SPACE
                indirectLight.rgb = GammaToLinearSpace(indirectLight.rgb);
#endif

#if defined(LIGHTMAP_ON)
                fixed4 lightmapSample = UNITY_SAMPLE_TEX2D(unity_Lightmap, input.uv2.xy);
                half4 bakedColor = half4(DecodeLightmap(lightmapSample), 1.0);
                indirectLight *= bakedColor;
#endif // LIGHTMAP_ON

                fixed shadow = SHADOW_ATTENUATION(input);
                fixed4 col = fixed4(indirectLight.rgb * shadow, albedo.a);

#if USING_FOG
                col.rgb = lerp(unity_FogColor.rgb, col.rgb, input.fog);
#endif

                return col;
            }

            ENDCG
        }
        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }

            // additive blending
            Blend One One

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            uniform float4 _Color;
            UNITY_DECLARE_TEX2D(_MainTex);
            float4 _MainTex_ST;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                SHADOW_COORDS(2)
                UNITY_FOG_COORDS(3)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            vertexOutput vert(vertexInput v)
            {
                vertexOutput output;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(vertexOutput, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.pos = UnityObjectToClipPos(v.vertex);
                output.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                TRANSFER_SHADOW(output)
                UNITY_TRANSFER_FOG(output, output.pos);

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float3 albedo = _Color.rgb * UNITY_SAMPLE_TEX2D(_MainTex, input.texcoord).rgb;
                fixed shadow = SHADOW_ATTENUATION(input);
                fixed4 col = fixed4(albedo * shadow, 1.0);

                UNITY_APPLY_FOG_COLOR(input.fogCoord, col, fixed4(0, 0, 0, 0));

                return col;
            }

            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
        Pass
        {
            Name "META"
            Tags { "LightMode" = "Meta" }
            Cull Off
            CGPROGRAM

            #include "UnityStandardMeta.cginc"

            sampler2D _Texture2;
            float4 _Texture2_ST;
            float4 _Texture2Color;
            float _CombineBlend;

            struct v2f_meta2
            {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;
#ifdef USE_MULTITEXTURING
                float4 uv1 : TEXCOORD1;
#endif
            };

            v2f_meta2 vert_meta2(VertexInput v)
            {
                v2f_meta2 o;
                o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
                o.uv0 = TexCoords(v);
#ifdef USE_MULTITEXTURING
                o.uv1.xy = TRANSFORM_TEX(v.uv0, _Texture2);
#endif
                return o;
            }

            float4 frag_meta2(v2f_meta2 i) : SV_Target
            {
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

                float4 texture1Color = tex2D(_MainTex, i.uv0);
#ifdef USE_GAMMA_SPACE
                texture1Color.rgb = LinearToGammaSpace(texture1Color.rgb);
#endif
                float4 albedo = _Color * texture1Color;

#ifdef USE_MULTITEXTURING
                float4 texture2Color = _Texture2Color * tex2D(_Texture2, i.uv1);
#ifdef USE_GAMMA_SPACE
                texture2Color.rgb = LinearToGammaSpace(texture2Color.rgb);
#endif // USE_GAMMA_SPACE
                albedo = lerp(albedo, texture2Color, _CombineBlend);
#endif // USE_MULTITEXTURING

#ifdef USE_GAMMA_SPACE
                albedo.rgb = GammaToLinearSpace(albedo.rgb);
#endif

                o.Albedo = albedo;

                return UnityMetaFragment(o);
            }

            #pragma shader_feature_local USE_MULTITEXTURING
            #pragma shader_feature_local USE_GAMMA_SPACE
            #pragma vertex vert_meta2
            #pragma fragment frag_meta2
            ENDCG
        }
    }
}