// A per-vertex lighting shader that supports vertex lightmaps and a light source fixed to the camera.
Shader "OSP Minimal/Vertex Lit"
{
    Properties
    {
       _MainTex("Albedo", 2D) = "white" {}
       _Color("Color", Color) = (1,1,1,1)
       _SpecColor("Specular Color", Color) = (1,1,1,1)
       _Shininess("Shininess", Float) = 10
       [Toggle(USE_GAMMA_SPACE)] _UseGammaSpace("Use Gamma Space Blending", Float) = 0

       [Header(Fixed Light)]
       [Toggle(USE_FIXED_LIGHT)] _UseFixedLight("Fixed Light (Not recommended for VR)", Float) = 0
       _FixedAmbientColor("Ambient Color", Color) = (0.5, 0.5, 0.5, 1.0)
       _FixedLightColor("Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
       // The default is Mario 64 light direction. https://forum.unity.com/threads/fake-shadows-in-shader.1276139/#post-8098937
       _FixedLightDirection("Light Direction", Vector) = (-0.6929, -0.6929, -0.6929, 0.0)

       [Header(Lightmaps)]
       [KeywordEnum(None, Custom, Bakery Lightmaps)] _VertexColorMode("Vertex Color Mode", Float) = 0
    }
    SubShader
    {
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
            #pragma shader_feature_local USE_FIXED_LIGHT
            #pragma shader_feature_local USE_GAMMA_SPACE

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            uniform float4 _LightColor0;

            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float _Shininess;
            UNITY_DECLARE_TEX2D(_MainTex);
            float4 _MainTex_ST;

#ifdef USE_FIXED_LIGHT
            uniform float4 _FixedAmbientColor;
            uniform float4 _FixedLightColor;
            uniform float3 _FixedLightDirection;
#endif

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
                float2 uv1 : TEXCOORD1;
                float3 diffuseLight : TEXCOORD2;
                float4 specularReflection : TEXCOORD3;
#if defined(_VERTEXCOLORMODE_CUSTOM) || defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
                float4 color : TEXCOORD4;
#endif
                SHADOW_COORDS(5)
                UNITY_FOG_COORDS(6)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_OUTPUT(vertexOutput, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float4x4 modelMatrix = unity_ObjectToWorld;
                float3x3 modelMatrixInverse = unity_WorldToObject;
                float3 normalDirection = normalize(mul(input.normal, modelMatrixInverse));
                float3 viewDirection = normalize(_WorldSpaceCameraPos - mul(modelMatrix, input.vertex).xyz);
                float3 lightDirection;
                float attenuation;

#ifdef USE_FIXED_LIGHT
                float3 ambientLighting = _FixedAmbientColor.rgb;
                float3 lightColor = _FixedLightColor.rgb;
                lightDirection = -normalize(mul((float3x3) UNITY_MATRIX_I_V, _FixedLightDirection));
                attenuation = 1.0; // no attenuation
#else
                float3 ambientLighting = UNITY_LIGHTMODEL_AMBIENT.rgb;
                float3 lightColor = _LightColor0.rgb;

                if (0.0 == _WorldSpaceLightPos0.w)
                {
                    // directional light?
                    attenuation = 1.0; // no attenuation
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                }
                else
                {
                    // point or spot light
                    float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - mul(modelMatrix, input.vertex).xyz;
                    float distance = length(vertexToLightSource);
                    attenuation = 1.0 / distance; // linear attenuation 
                    lightDirection = normalize(vertexToLightSource);
                }
#endif

#ifdef USE_GAMMA_SPACE
                ambientLighting = LinearToGammaSpace(ambientLighting);
                lightColor = LinearToGammaSpace(lightColor);
#endif

                float3 diffuseReflection = attenuation * lightColor * max(0.0, dot(normalDirection, lightDirection));

                float3 specularReflection;
                if (dot(normalDirection, lightDirection) < 0.0)
                {
                    // light source on the wrong side?
                    specularReflection = float3(0.0, 0.0, 0.0);
                }
                else
                {
                    // light source on the right side
                    specularReflection = attenuation * lightColor * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
                }

                output.diffuseLight = ambientLighting + diffuseReflection;
                output.specularReflection = float4(specularReflection, 1.0);
                output.pos = UnityObjectToClipPos(input.vertex);
                output.uv0 = TRANSFORM_TEX(input.uv0, _MainTex);

#if defined(LIGHTMAP_ON)
                output.uv1 = input.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif

#if defined(_VERTEXCOLORMODE_CUSTOM)
                output.color = input.color;
#elif defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
                // Decode baked HDR vertex color (RGBM)
                output.color = input.color;
                output.color.rgb *= input.color.a * 8.0;
                output.color.rgb *= output.color.rgb;
#endif
                
                TRANSFER_SHADOW(output)
                UNITY_TRANSFER_FOG(output, output.pos);

                return output;
            }

            float4 frag(vertexOutput input) : COLOR
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                UNITY_APPLY_DITHER_CROSSFADE(input.pos.xy);

                float4 textureColor = UNITY_SAMPLE_TEX2D(_MainTex, input.uv0);

#ifdef USE_GAMMA_SPACE
                textureColor.rgb = LinearToGammaSpace(textureColor.rgb);
#endif

                float4 albedo = _Color * textureColor;
                float4 indirectLight = albedo;

#if defined(_VERTEXCOLORMODE_CUSTOM) || defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
                indirectLight.rgb *= input.color.rgb;
#endif
#if defined(LIGHTMAP_ON)
                fixed4 lightmapSample = UNITY_SAMPLE_TEX2D(unity_Lightmap, input.uv1.xy);
                half4 bakedColor = half4(DecodeLightmap(lightmapSample), 1.0);
                indirectLight *= bakedColor;
#endif // LIGHTMAP_ON

                fixed shadow = SHADOW_ATTENUATION(input);
                input.diffuseLight *= shadow;
                input.specularReflection *= shadow;

                fixed4 col = fixed4(indirectLight.rgb + albedo.rgb * input.diffuseLight + input.specularReflection, 1.0);

#ifdef USE_GAMMA_SPACE
                col.rgb = GammaToLinearSpace(col.rgb);
#endif

                UNITY_APPLY_FOG(input.fogCoord, col);

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

            uniform float4 _LightColor0;

            uniform float4 _Color;
            uniform float4 _SpecColor;
            uniform float _Shininess;
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
                float3 diffuseLight : TEXCOORD1;
                float4 specularReflection : COLOR;
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

                float4x4 modelMatrix = unity_ObjectToWorld;
                float3x3 modelMatrixInverse = unity_WorldToObject;
                float3 normalDirection = normalize(mul(v.normal, modelMatrixInverse));
                float3 viewDirection = normalize(_WorldSpaceCameraPos - mul(modelMatrix, v.vertex).xyz);
                float3 lightDirection;
                float attenuation;

                if (0.0 == _WorldSpaceLightPos0.w)
                {
                    // directional light?
                    attenuation = 1.0; // no attenuation
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                }
                else
                {
                    // point or spot light
                    float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - mul(modelMatrix, v.vertex).xyz;
                    float distance = length(vertexToLightSource);
                    attenuation = 1.0 / distance; // linear attenuation 
                    lightDirection = normalize(vertexToLightSource);
                }

                float3 diffuseReflection = attenuation * _LightColor0.rgb * max(0.0, dot(normalDirection, lightDirection));

                float3 specularReflection;
                if (dot(normalDirection, lightDirection) < 0.0)
                {
                    // light source on the wrong side?
                    specularReflection = float3(0.0, 0.0, 0.0);
                }
                else
                {
                    // light source on the right side
                    specularReflection = attenuation * _LightColor0.rgb * _SpecColor.rgb * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), _Shininess);
                }

                output.diffuseLight = diffuseReflection;
                output.specularReflection = float4(specularReflection, 1.0);
                // no ambient contribution in this pass
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
                input.diffuseLight *= shadow;
                input.specularReflection *= shadow;

                fixed4 col = fixed4(albedo * input.diffuseLight + input.specularReflection, 1.0);

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

            float4 frag_meta2(v2f_meta i) : SV_Target
            {
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
                o.Albedo = tex2D(_MainTex, i.uv) * _Color;
                o.SpecularColor = _SpecColor.xyz;
                return UnityMetaFragment(o);
            }

            #pragma vertex vert_meta
            #pragma fragment frag_meta2
            ENDCG
        }
    }
}