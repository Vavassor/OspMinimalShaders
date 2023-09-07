// An unlit shader that supports many effects.
Shader "OSP Minimal/Unlit Fancy"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        _ScrollVelocity("Scroll Velocity", Vector) = (0, 0, 0, 0)
        [Toggle(USE_GAMMA_COLORSPACE)] _UseGammaSpace("Use Gamma Space Blending", Float) = 1
        [KeywordEnum(None, Custom, Bakery Lightmaps)] _VertexColorMode("Vertex Color Mode", Float) = 0

        [Header(Detail Texture)]
        [Toggle(USE_DETAIL_TEXTURE)] _UseDetailTexture("Enable", Float) = 0
        _DetailTexture("Detail", 2D) = "white" {}
        _DetailTextureTint("Tint", Color) = (1,1,1,1)
        [Enum(Strength,0,Vertex Color Red Channel,1,Vertex Color Alpha Channel,2)] _DetailTextureBlendBy("Blend By", Float) = 0
        _DetailTextureBlend("Strength", Range(0, 1)) = 1
        [Enum(Lerp,0,Transparent,1,Add,2,Multiply,3)] _DetailTextureBlendMode("Blend Mode", Float) = 0
        _DetailTextureScrollVelocity("Scroll Velocity", Vector) = (0, 0, 0, 0)

        [Header(Matcap)]
        [Toggle(USE_MATCAP)] _UseMatcap("Enable", Float) = 0
        [NoScaleOffset] _MatcapTexture("Matcap", 2D) = "" {}
        _MatcapTextureTint("Tint", Color) = (1,1,1,1)
        _MatcapTextureBlend("Strength", Range(0, 1)) = 1
        [Enum(Lerp,0,Transparent,1,Add,2,Multiply,3)] _MatcapTextureBlendMode("Blend Mode", Float) = 0

        [Header(Flipbook)]
        [Toggle(USE_FLIPBOOK)] _UseFlipbook("Enable", Float) = 0
        _FlipbookTexArray("Texture Array", 2DArray) = "" {}
        _FlipbookTint("Tint", Color) = (1,1,1,1)
        _FlipbookScrollVelocity("Scroll Velocity", Vector) = (0, 0, 0, 0)
        [Enum(Replace,0,Transparent,1,Add,2,Multiply,3)] _FlipbookBlendMode("Blend Mode", Float) = 0
        _FlipbookFramesPerSecond("Frames Per Second", Float) = 30
        [Toggle(USE_FLIPBOOK_SMOOTHING)] _UseFlipbookSmoothing("Smoothing", Float) = 0
        [Toggle] _FlipbookUseManualFrame("Control Frame Manually", Float) = 0
        _FlipbookManualFrame("Frame", Float) = 0

        [Header(Effects)]
        [Toggle(USE_AFFINE_MAPPING)] _UseAffineMapping("Use Affine Mapping", Float) = 0
        _AffineDistortion("Affine Distortion", Range(0, 8)) = 0.5
        [Toggle(USE_POLYGON_JITTER)] _UsePolygonJitter("Use Polygon Jitter", Float) = 0
        _PolygonJitter("Polygon Jitter", Range(1,8)) = 4

        [Header(Alpha Test)]
        [Toggle(USE_ALPHA_TEST)] _UseAlphaTest("Enable", Float) = 0
        _AlphaCutoff("Alpha Cutoff", Float) = 0.5

        [Header(Color Blending)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 1 //"One"
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 0 //"Zero"
        [Enum(Add,0,Sub,1,RevSub,2,Min,3,Max,4)] _BlendOp("Blend Operation", Float) = 0 // "Add"

        [Header(Depth Test)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LEqual"
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 1.0 //"On"
        _OffsetFactor("Offset Factor", Range(-1, 1)) = 0
        _OffsetUnits("Offset Units", Range(-1, 1)) = 0

        [Header(Render Settings)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2
        [Toggle(USE_FOG)] _UseFog("Use Fog", Float) = 1
        [Toggle(RECEIVE_SHADOWS)] _ShouldReceiveShadows("Receives Shadows", Float) = 1
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
            #pragma shader_feature_local _VERTEXCOLORMODE_NONE _VERTEXCOLORMODE_CUSTOM _VERTEXCOLORMODE_BAKERY_LIGHTMAPS
            #pragma shader_feature_local USE_ALPHA_TEST
            #pragma shader_feature_local USE_DETAIL_TEXTURE
            #pragma shader_feature_local USE_GAMMA_COLORSPACE
            #pragma shader_feature_local USE_MATCAP
            #pragma shader_feature_local USE_FLIPBOOK
            #pragma shader_feature_local USE_FLIPBOOK_SMOOTHING
            #pragma shader_feature_local USE_AFFINE_MAPPING
            #pragma shader_feature_local USE_POLYGON_JITTER
            #pragma shader_feature_local USE_FOG
            #pragma shader_feature_local RECEIVE_SHADOWS

            #include "OspMinimalCore.cginc"
            #include "AutoLight.cginc"

            uniform float4 _Color;
            UNITY_DECLARE_TEX2D(_MainTex);
            float4 _MainTex_ST;
            float2 _ScrollVelocity;

#ifdef USE_DETAIL_TEXTURE
            UNITY_DECLARE_TEX2D(_DetailTexture);
            float4 _DetailTexture_ST;
            float4 _DetailTextureTint;
            float _DetailTextureBlendBy;
            float _DetailTextureBlend;
            float _DetailTextureBlendMode;
            float2 _DetailTextureScrollVelocity;
#endif

#ifdef USE_MATCAP
            UNITY_DECLARE_TEX2D(_MatcapTexture);
            float4 _MatcapTexture_ST;
            float4 _MatcapTextureTint;
            float _MatcapTextureBlend;
            float _MatcapTextureBlendMode;
#endif

#ifdef USE_FLIPBOOK
            UNITY_DECLARE_TEX2DARRAY(_FlipbookTexArray);
            float4 _FlipbookTexArray_ST;
            float4 _FlipbookTint;
            float2 _FlipbookScrollVelocity;
            float _FlipbookBlendMode;
            float _FlipbookFramesPerSecond;
            float _FlipbookUseManualFrame;
            int _FlipbookManualFrame;
#endif

#ifdef USE_ALPHA_TEST
            float _AlphaCutoff;
#endif

#ifdef USE_AFFINE_MAPPING
            float _AffineDistortion;
#endif

#ifdef USE_POLYGON_JITTER
            float _PolygonJitter;
#endif

            struct vertexInput
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normal : NORMAL;
                float4 color : COLOR0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                // The z component is used for affine texture mapping.
                float3 uv0 : TEXCOORD0;
#ifdef USE_DETAIL_TEXTURE
                float2 uv1 : TEXCOORD1;
#endif
#if defined(LIGHTMAP_ON)
                float2 uv2 : TEXCOORD2;
#endif
#ifdef USE_FLIPBOOK
                float4 uv3 : TEXCOORD7;
#endif
                float4 color : TEXCOORD4;
#ifdef USE_MATCAP
                half3 viewDirection : TEXCOORD8;
                half3 viewNormal : TEXCOORD9;
#endif // USE_MATCAP
                LIGHTING_COORDS(5,10)
                OSP_FOG_COORDS(6)

                UNITY_VERTEX_OUTPUT_STEREO
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_OUTPUT(vertexOutput, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.pos = UnityObjectToClipPos(input.vertex);

#ifdef USE_POLYGON_JITTER
                output.pos = JitterVertex(output.pos, _PolygonJitter);
#endif

                output.uv0.xy = TRANSFORM_TEX(input.uv0, _MainTex) + _Time.y * _ScrollVelocity;
                output.uv0.z = 1.0;

#ifdef USE_AFFINE_MAPPING
                // True affine mapping distorts to an extreme when the camera
                // gets close. PS1 games tessellate polygons that are close to
                // the camera, to compensate. But this tesselation is tough to
                // simulate. So instead use adjustable affine distortion that
                // reduces when close.
                float distance = length(UnityObjectToClipPos(input.vertex));
                float counterCorrection = distance + (output.pos.w * _AffineDistortion) / distance / 2.0;
                output.uv0.xy *= counterCorrection;
                output.uv0.z = counterCorrection;
#endif

#ifdef USE_DETAIL_TEXTURE
                output.uv1 = TRANSFORM_TEX(input.uv0, _DetailTexture) + _Time.y * _DetailTextureScrollVelocity;
#endif

#ifdef USE_MATCAP
                output.viewDirection = normalize(UnityObjectToViewPos(input.vertex.xyz));
                output.viewNormal = normalize(mul((float3x3) UNITY_MATRIX_IT_MV, input.normal));
#endif // USE_MATCAP

#if defined(LIGHTMAP_ON)
                output.uv2 = input.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#ifdef USE_FLIPBOOK
                float2 transformedTexcoord = TRANSFORM_TEX(input.uv0, _FlipbookTexArray);
                float2 scrolledTexcoord = transformedTexcoord + _Time.y * _FlipbookScrollVelocity;
                output.uv3 = GetFlipbookTexcoord(_FlipbookTexArray, scrolledTexcoord, _FlipbookFramesPerSecond, _FlipbookUseManualFrame, _FlipbookManualFrame);
#endif

#ifdef _VERTEXCOLORMODE_BAKERY_LIGHTMAPS
                output.color = DecodeBakeryVertexLightmap(input.color);
#else
                output.color = input.color;
#endif
                
                TRANSFER_VERTEX_TO_FRAGMENT(output)
                OSP_TRANSFER_FOG(input.vertex, output)

                return output;
            }

            fixed GetShadowAttenuation(vertexOutput input)
            {
                fixed shadow = SHADOW_ATTENUATION(input);
#if defined(DIRECTIONAL)
                fixed light = 0.5;
#elif defined(POINT)
                fixed light = (tex2D(_LightTexture0, dot(input._LightCoord, input._LightCoord).rr)).r;
#elif defined(SPOT)
                fixed light = (input._LightCoord.z > 0) * UnitySpotCookie(input._LightCoord) * UnitySpotAttenuate(input._LightCoord.xyz);
#endif
                fixed attenuation = shadow < 0.2 ? (1.0 - light) : 1.0;
                return attenuation;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                UNITY_APPLY_DITHER_CROSSFADE(input.pos.xy);

                float4 texture1Color = UNITY_SAMPLE_TEX2D(_MainTex, input.uv0.xy / input.uv0.z);
                texture1Color.rgb = AdjustToShadingColorSpace(texture1Color.rgb);

                float4 albedo = _Color * texture1Color;

#ifdef USE_DETAIL_TEXTURE
                float4 texture2Color = UNITY_SAMPLE_TEX2D(_DetailTexture, input.uv1);
                texture2Color.rgb = AdjustToShadingColorSpace(texture2Color.rgb);

                float detailBlend = GetBlendAmount(_DetailTextureBlend, input.color, _DetailTextureBlendBy);
                albedo = lerp(albedo, BlendColor(_DetailTextureTint * texture2Color, albedo, _DetailTextureBlendMode), detailBlend);
#endif // USE_DETAIL_TEXTURE

#ifdef USE_MATCAP
                float2 matcapTexcoord = GetMatcapTexcoord(input.viewDirection, input.viewNormal);
                fixed4 matcapColor = UNITY_SAMPLE_TEX2D(_MatcapTexture, matcapTexcoord);
                matcapColor.rgb = AdjustToShadingColorSpace(matcapColor.rgb);

                albedo = lerp(albedo, BlendColor(_MatcapTextureTint * matcapColor, albedo, _MatcapTextureBlendMode), _MatcapTextureBlend);
#endif // USE_MATCAP

#ifdef USE_FLIPBOOK
                float4 flipbookColor = UNITY_SAMPLE_TEX2DARRAY(_FlipbookTexArray, input.uv3.xyz);

#if defined(USE_FLIPBOOK_SMOOTHING)
                float4 flipbookColor2 = UNITY_SAMPLE_TEX2DARRAY(_FlipbookTexArray, input.uv3.xyw);
                flipbookColor = lerp(flipbookColor, flipbookColor2, frac(input.uv3.z));
#endif // USE_FLIPBOOK_SMOOTHING

                flipbookColor.rgb = AdjustToShadingColorSpace(flipbookColor.rgb);
                albedo = BlendColor(_FlipbookTint * flipbookColor, albedo, _FlipbookBlendMode);
#endif // USE_FLIPBOOK

#ifdef USE_ALPHA_TEST
                clip(albedo.a - _AlphaCutoff);
#endif

                float4 indirectLight = albedo;

#if defined(_VERTEXCOLORMODE_CUSTOM) || defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
                indirectLight.rgb *= input.color.rgb;
#endif

                indirectLight.rgb = AdjustFromShadingColorSpace(indirectLight.rgb);

#if defined(LIGHTMAP_ON)
                indirectLight *= SampleLightmap(input.uv2.xy);
#endif // LIGHTMAP_ON

#if defined(RECEIVE_SHADOWS)
                fixed shadow = GetShadowAttenuation(input);
                indirectLight.rgb *= shadow;
#endif

                fixed4 col = fixed4(indirectLight.rgb, albedo.a);

#if defined(USE_FOG)
                OSP_APPLY_FOG(col, input)
#endif

                return col;
            }

            ENDCG
        }
        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }

            // Use multiplicative blending to remove shadows instead of adding light.
            Blend DstColor Zero

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma shader_feature_local USE_FOG
            #pragma shader_feature_local RECEIVE_SHADOWS

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            uniform float4 _Color;
            UNITY_DECLARE_TEX2D(_MainTex);
            float4 _MainTex_ST;
            float2 _ScrollVelocity;

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
                float2 uv0 : TEXCOORD0;
                LIGHTING_COORDS(2,3)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            vertexOutput vert(vertexInput v)
            {
                vertexOutput output;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(vertexOutput, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.pos = UnityObjectToClipPos(v.vertex);
                output.uv0.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + _Time.y * _ScrollVelocity;

                TRANSFER_VERTEX_TO_FRAGMENT(output)

                return output;
            }

            fixed GetShadowAttenuation(vertexOutput input)
            {
                fixed shadow = SHADOW_ATTENUATION(input);
#if defined(DIRECTIONAL)
                fixed light = 0.5;
#elif defined(POINT)
                fixed light = (tex2D(_LightTexture0, dot(input._LightCoord, input._LightCoord).rr)).r;
#elif defined(SPOT)
                fixed light = (input._LightCoord.z > 0) * UnitySpotCookie(input._LightCoord) * UnitySpotAttenuate(input._LightCoord.xyz);
#endif
                fixed attenuation = shadow < 0.2 ? (1.0 - light) : 1.0;
                return attenuation;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                fixed4 col = 1.0;

#if defined(RECEIVE_SHADOWS)
                col.rgb *= GetShadowAttenuation(input);
#endif

                // TODO: Make the shadow brighter where it's foggy.

                return col;
            }

            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZTest LEqual
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "ShadowCaster.cginc"
            ENDCG
        }
        Pass
        {
            Name "META"
            Tags { "LightMode" = "Meta" }
            Cull Off
            CGPROGRAM

            #include "UnityStandardMeta.cginc"
            #include "OspMinimalCore.cginc"

            sampler2D _DetailTexture;
            float4 _DetailTexture_ST;
            float4 _DetailTextureTint;
            float _DetailTextureBlend;

            struct v2f_meta2
            {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;
#ifdef USE_DETAIL_TEXTURE
                float4 uv1 : TEXCOORD1;
#endif
            };

            v2f_meta2 vert_meta2(VertexInput v)
            {
                v2f_meta2 o;
                o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
                o.uv0 = TexCoords(v);
#ifdef USE_DETAIL_TEXTURE
                o.uv1.xy = TRANSFORM_TEX(v.uv0, _DetailTexture);
#endif
                return o;
            }

            float4 frag_meta2(v2f_meta2 i) : SV_Target
            {
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

                float4 texture1Color = tex2D(_MainTex, i.uv0);
                texture1Color.rgb = AdjustToShadingColorSpace(texture1Color.rgb);

                float4 albedo = _Color * texture1Color;

#ifdef USE_DETAIL_TEXTURE
                float4 texture2Color = _DetailTextureTint * tex2D(_DetailTexture, i.uv1);
                texture2Color.rgb = AdjustToShadingColorSpace(texture2Color.rgb);

                albedo = lerp(albedo, texture2Color, _DetailTextureBlend);
#endif // USE_DETAIL_TEXTURE

                albedo.rgb = AdjustFromShadingColorSpace(albedo.rgb);

                o.Albedo = albedo;

                return UnityMetaFragment(o);
            }

            #pragma shader_feature_local USE_DETAIL_TEXTURE
            #pragma shader_feature_local USE_GAMMA_SPACE
            #pragma vertex vert_meta2
            #pragma fragment frag_meta2
            ENDCG
        }
    }
}