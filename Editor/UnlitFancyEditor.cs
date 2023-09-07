using UnityEditor;
using UnityEngine;

namespace OrchidSeal.MinimalShaders.Editor
{
    public class UnlitFancyEditor : ShaderGUI
    {
        public enum BlendMode
        {
            Opaque,
            Cutout,
            Transparent,
            Custom
        }

        // Blending properties
        MaterialProperty blendModeProperty = null;
        MaterialProperty useAlphaTestProperty = null;
        MaterialProperty alphaCutoffProperty = null;
        MaterialProperty alphaToMaskProperty = null;
        MaterialProperty sourceBlendProperty = null;
        MaterialProperty destinationBlendProperty = null;
        MaterialProperty blendOperationProperty = null;
        MaterialProperty zTestProperty = null;
        MaterialProperty zWriteProperty = null;
        MaterialProperty useGammaSpaceProperty = null;

        // Base properties
        MaterialProperty baseTextureProperty = null;
        MaterialProperty baseTextureTintProperty = null;
        MaterialProperty baseScrollVelocityProperty = null;
        MaterialProperty vertexColorModeProperty = null;

        // Detail properties
        MaterialProperty useDetailTextureProperty = null;
        MaterialProperty detailTextureProperty = null;
        MaterialProperty detailTextureTintProperty = null;
        MaterialProperty detailScrollVelocityProperty = null;
        MaterialProperty detailTextureBlendByProperty = null;
        MaterialProperty detailTextureBlendProperty = null;
        MaterialProperty detailTextureBlendModeProperty = null;

        // Matcap properties
        MaterialProperty isMatcapEnabledProperty = null;
        MaterialProperty matcapTextureProperty = null;
        MaterialProperty matcapTextureTintProperty = null;
        MaterialProperty matcapTextureBlendProperty = null;
        MaterialProperty matcapTextureBlendModeProperty = null;

        // Flipbook properties
        MaterialProperty isFlipbookEnabledProperty = null;
        MaterialProperty flipbookProperty = null;
        MaterialProperty flipbookTintProperty = null;
        MaterialProperty flipbookScrollVelocityProperty = null;
        MaterialProperty flipbookBlendModeProperty = null;
        MaterialProperty flipbookFramesPerSecondProperty = null;
        MaterialProperty useFlipbookSmoothingProperty = null;
        MaterialProperty flipbookUseManualFrameProperty = null;
        MaterialProperty flipbookManualFrameProperty = null;

        // Effect properties
        MaterialProperty useAffineMappingProperty = null;
        MaterialProperty affineDistortionProperty = null;
        MaterialProperty usePolygonJitterProperty = null;
        MaterialProperty polygonJitterProperty = null;

        // Render setting properties
        MaterialProperty cullProperty = null;
        MaterialProperty useFogProperty = null;
        MaterialProperty receiveShadowsProperty = null;
        MaterialProperty offsetFactorProperty = null;
        MaterialProperty offsetUnitsProperty = null;

        // Blending option labels
        private string blendingFoldoutLabel = "Blending";
        private GUIContent blendModeLabel = new GUIContent("Blending Mode", "Opaque:\nCannot be seen through.\n\nCutout:\nCut holes in geometry by discarding any pixel whose combined alpha is below a cutoff threshold.\n\nTransparent:\nSmoothly blended transparency that uses the combined alpha values of pixels.\n\nCustom:\nControl all blending settings separately.");
        private GUIContent useAlphaTestLabel = new GUIContent("Use Alpha Test");
        private GUIContent alphaCutoffLabel = new GUIContent("Alpha Cutoff");
        private GUIContent alphaToMaskLabel = new GUIContent("Alpha To Mask");
        private GUIContent sourceBlendLabel = new GUIContent("Source Blend");
        private GUIContent destinationBlendLabel = new GUIContent("Destination Blend");
        private GUIContent blendOperationLabel = new GUIContent("Blend Operation");
        private GUIContent zTestLabel = new GUIContent("Depth Test");
        private GUIContent zWriteLabel = new GUIContent("Depth Write");
        private GUIContent useGammaSpaceLabel = new GUIContent("Use Gamma Space Blending", "Perform shader calculations in gamma space. Blending with the framebuffer will still follow the color space workflow in project settings.");

        // Base option labels
        private string baseFoldoutLabel = "Base";
        private GUIContent baseTextureLabel = new GUIContent("Base Color");
        private GUIContent baseScrollVelocityLabel = new GUIContent("Scroll Velocity");
        private GUIContent vertexColorModeLabel = new GUIContent("Vertex Color Mode", "None:\nDo not use vertex colors.\n\nMultiply:\nMultiply the vertex color with the base color.\n\nBakery Lightmaps:\nVertex lightmaps created by Bakery GPU Lightmapper.");

        // Detail option labels
        private string detailFoldoutLabel = "Detail";
        private GUIContent useDetailTextureLabel = new GUIContent("Enabled");
        private GUIContent detailTextureLabel = new GUIContent("Detail Color");
        private GUIContent detailScrollVelocityLabel = new GUIContent("Scroll Velocity");
        private GUIContent detailTextureBlendByLabel = new GUIContent("Blend By");
        private GUIContent detailTextureBlendLabel = new GUIContent("Strength");
        private GUIContent detailTextureBlendModeLabel = new GUIContent("Blend Mode");

        // Matcap option labels
        private string matcapFoldoutLabel = "Matcap";
        private GUIContent isMatcapEnabledLabel = new GUIContent("Enabled");
        private GUIContent matcapTextureLabel = new GUIContent("Matcap");
        private GUIContent matcapTextureBlendLabel = new GUIContent("Strength");
        private GUIContent matcapTextureBlendModeLabel = new GUIContent("Blend Mode");

        // Flipbook option labels
        private string flipbookFoldoutLabel = "Flipbook";
        private GUIContent isFlipbookEnabledLabel = new GUIContent("Enabled");
        private GUIContent flipbookLabel = new GUIContent("Flipbook");
        private GUIContent flipbookScrollVelocityLabel = new GUIContent("Scroll Velocity");
        private GUIContent flipbookBlendModeLabel = new GUIContent("Blend Mode");
        private GUIContent flipbookFramesPerSecondLabel = new GUIContent("Frames Per Second");
        private GUIContent useFlipbookSmoothingLabel = new GUIContent("Smoothing");
        private GUIContent flipbookUseManualFrameLabel = new GUIContent("Control Frame Manually");
        private GUIContent flipbookManualFrameLabel = new GUIContent("Manual Frame");

        // Effect option labels
        private string effectFoldoutLabel = "Effects";
        private GUIContent useAffineMappingLabel = new GUIContent("Affine Texture Mapping", "Map textures without correcting for perspective. This causes warping the more perpendicular triangles are from the camera. This type of mapping is used by the PlayStation 1.");
        private GUIContent affineDistortionLabel = new GUIContent("Affine Distortion", "Reduce the distortion when the camera is close. Some PS1 games used dynamic tessellation to reduce warping. So this allows some of that control without needing tessellation.");
        private GUIContent usePolygonJitterLabel = new GUIContent("Use Polygon Jitter", "Remove subpixel rasterization of triangles. This causes polygon jitter similar to games on the Nintendo DS or PlayStation 1.");
        private GUIContent polygonJitterLabel = new GUIContent("Polygon Jitter", "The grid size in pixels to snap vertices to. A value of 1 simulates PS1 and DS behavior exactly. However, on modern high resolution displays, it may not be as visible unless you set a higher value.");

        // Render setting labels
        private string renderSettingsFoldoutLabel = "Render Settings";
        private GUIContent cullLabel = new GUIContent("Cull", "Skip drawing polygons based on which way they're facing relative to the camera. Turn off for two-sided meshes.");
        private GUIContent useFogLabel = new GUIContent("Fog");
        private GUIContent receiveShadowsLabel = new GUIContent("Receive Shadows");
        private GUIContent offsetFactorLabel = new GUIContent("Polygon Offset Factor");
        private GUIContent offsetUnitsLabel = new GUIContent("Polygon Offset Units");

        private bool showBlendingOptions = true;
        private bool showBaseOptions = true;
        private bool showDetailOptions = false;
        private bool showMatcapOptions = false;
        private bool showFlipbookOptions = false;
        private bool showEffectOptions = false;
        private bool showRenderSettings = false;

        override public void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            // Intentionally don't call the base class so that the normal settings aren't rendered.
            // base.OnGUI(materialEditor, properties);

            FindProperties(properties);

            Material targetMaterial = materialEditor.target as Material;

            BlendingOptions(materialEditor, targetMaterial);
            BaseOptions(materialEditor, targetMaterial);
            DetailOptions(materialEditor, targetMaterial);
            MatcapOptions(materialEditor, targetMaterial);
            FlipbookOptions(materialEditor, targetMaterial);
            EffectOptions(materialEditor, targetMaterial);
            RenderSettings(materialEditor, targetMaterial);
        }

        private void FindProperties(MaterialProperty[] properties)
        {
            blendModeProperty = FindProperty("_BlendMode", properties);
            useAlphaTestProperty = FindProperty("_UseAlphaTest", properties);
            alphaCutoffProperty = FindProperty("_AlphaCutoff", properties);
            alphaToMaskProperty = FindProperty("_AlphaToMask", properties);
            sourceBlendProperty = FindProperty("_SrcBlend", properties);
            destinationBlendProperty = FindProperty("_DstBlend", properties);
            blendOperationProperty = FindProperty("_BlendOp", properties);
            zTestProperty = FindProperty("_ZTest", properties);
            zWriteProperty = FindProperty("_ZWrite", properties);
            useGammaSpaceProperty = FindProperty("_UseGammaSpace", properties);

            baseTextureProperty = FindProperty("_MainTex", properties);
            baseTextureTintProperty = FindProperty("_Color", properties);
            baseScrollVelocityProperty = FindProperty("_ScrollVelocity", properties);
            vertexColorModeProperty = FindProperty("_VertexColorMode", properties);

            isMatcapEnabledProperty = FindProperty("_UseMatcap", properties);
            matcapTextureProperty = FindProperty("_MatcapTexture", properties);
            matcapTextureTintProperty = FindProperty("_MatcapTextureTint", properties);
            matcapTextureBlendProperty = FindProperty("_MatcapTextureBlend", properties);
            matcapTextureBlendModeProperty = FindProperty("_MatcapTextureBlendMode", properties);

            useDetailTextureProperty = FindProperty("_UseDetailTexture", properties);
            detailTextureProperty = FindProperty("_DetailTexture", properties);
            detailTextureTintProperty = FindProperty("_DetailTextureTint", properties);
            detailScrollVelocityProperty = FindProperty("_DetailTextureScrollVelocity", properties);
            detailTextureBlendByProperty = FindProperty("_DetailTextureBlendBy", properties);
            detailTextureBlendProperty = FindProperty("_DetailTextureBlend", properties);
            detailTextureBlendModeProperty = FindProperty("_DetailTextureBlendMode", properties);

            isFlipbookEnabledProperty = FindProperty("_UseFlipbook", properties);
            flipbookProperty = FindProperty("_FlipbookTexArray", properties);
            flipbookTintProperty = FindProperty("_FlipbookTint", properties);
            flipbookScrollVelocityProperty = FindProperty("_FlipbookScrollVelocity", properties);
            flipbookBlendModeProperty = FindProperty("_FlipbookBlendMode", properties);
            flipbookFramesPerSecondProperty = FindProperty("_FlipbookFramesPerSecond", properties);
            useFlipbookSmoothingProperty = FindProperty("_UseFlipbookSmoothing", properties);
            flipbookUseManualFrameProperty = FindProperty("_FlipbookUseManualFrame", properties);
            flipbookManualFrameProperty = FindProperty("_FlipbookManualFrame", properties);

            useAffineMappingProperty = FindProperty("_UseAffineMapping", properties);
            affineDistortionProperty = FindProperty("_AffineDistortion", properties);
            usePolygonJitterProperty = FindProperty("_UsePolygonJitter", properties);
            polygonJitterProperty = FindProperty("_PolygonJitter", properties);

            cullProperty = FindProperty("_Cull", properties);
            offsetFactorProperty = FindProperty("_OffsetFactor", properties);
            offsetUnitsProperty = FindProperty("_OffsetUnits", properties);
            useFogProperty = FindProperty("_UseFog", properties);
            receiveShadowsProperty = FindProperty("_ShouldReceiveShadows", properties);
        }

        private void BlendingOptions(MaterialEditor materialEditor, Material targetMaterial)
        {
            showBlendingOptions = EditorGUILayout.BeginFoldoutHeaderGroup(showBlendingOptions, blendingFoldoutLabel);

            if (showBlendingOptions)
            {
                EditorGUI.BeginChangeCheck();
                materialEditor.ShaderProperty(blendModeProperty, blendModeLabel);
                if (EditorGUI.EndChangeCheck())
                {
                    SetBlendMode(targetMaterial);
                }

                float blendMode = blendModeProperty.floatValue;

                if (blendMode == (float)BlendMode.Custom)
                {
                    materialEditor.ShaderProperty(sourceBlendProperty, sourceBlendLabel);
                    materialEditor.ShaderProperty(destinationBlendProperty, destinationBlendLabel);
                    materialEditor.ShaderProperty(blendOperationProperty, blendOperationLabel);
                    materialEditor.ShaderProperty(zTestProperty, zTestLabel);
                    materialEditor.ShaderProperty(zWriteProperty, zWriteLabel);
                    materialEditor.ShaderProperty(useAlphaTestProperty, useAlphaTestLabel);

                    EditorGUI.BeginDisabledGroup(useAlphaTestProperty.floatValue == 0.0f);
                    materialEditor.ShaderProperty(alphaCutoffProperty, alphaCutoffLabel);
                    materialEditor.ShaderProperty(alphaToMaskProperty, alphaToMaskLabel);
                    EditorGUI.EndDisabledGroup();
                }

                if (blendMode == (float)BlendMode.Cutout)
                {
                    materialEditor.ShaderProperty(alphaCutoffProperty, alphaCutoffLabel);
                    materialEditor.ShaderProperty(alphaToMaskProperty, alphaToMaskLabel);
                }

                materialEditor.RenderQueueField();
                materialEditor.ShaderProperty(useGammaSpaceProperty, useGammaSpaceLabel);

                GUILayout.Space(20);
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void BaseOptions(MaterialEditor materialEditor, Material targetMaterial)
        {
            showBaseOptions = EditorGUILayout.BeginFoldoutHeaderGroup(showBaseOptions, baseFoldoutLabel);

            if (showBaseOptions)
            {
                materialEditor.TexturePropertySingleLine(baseTextureLabel, baseTextureProperty, baseTextureTintProperty);
                materialEditor.TextureScaleOffsetProperty(baseTextureProperty);
                Vector2Property(baseScrollVelocityProperty, baseScrollVelocityLabel);
                materialEditor.ShaderProperty(vertexColorModeProperty, vertexColorModeLabel);

                GUILayout.Space(20);
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void DetailOptions(MaterialEditor materialEditor, Material targetMaterial)
        {
            showDetailOptions = EditorGUILayout.BeginFoldoutHeaderGroup(showDetailOptions, detailFoldoutLabel);

            if (showDetailOptions)
            {
                materialEditor.ShaderProperty(useDetailTextureProperty, useDetailTextureLabel);

                EditorGUI.BeginDisabledGroup(useDetailTextureProperty.floatValue == 0.0f);

                materialEditor.TexturePropertySingleLine(detailTextureLabel, detailTextureProperty, detailTextureTintProperty);
                materialEditor.TextureScaleOffsetProperty(detailTextureProperty);
                Vector2Property(detailScrollVelocityProperty, detailScrollVelocityLabel);

                materialEditor.ShaderProperty(detailTextureBlendByProperty, detailTextureBlendByLabel);
                if (detailTextureBlendByProperty.floatValue == 0.0f)
                {
                    materialEditor.ShaderProperty(detailTextureBlendProperty, detailTextureBlendLabel);
                }
                
                materialEditor.ShaderProperty(detailTextureBlendModeProperty, detailTextureBlendModeLabel);

                EditorGUI.EndDisabledGroup();

                GUILayout.Space(20);
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void MatcapOptions(MaterialEditor materialEditor, Material targetMaterial)
        {
            showMatcapOptions = EditorGUILayout.BeginFoldoutHeaderGroup(showMatcapOptions, matcapFoldoutLabel);

            if (showMatcapOptions)
            {
                materialEditor.ShaderProperty(isMatcapEnabledProperty, isMatcapEnabledLabel);

                EditorGUI.BeginDisabledGroup(isMatcapEnabledProperty.floatValue == 0.0f);

                materialEditor.TexturePropertySingleLine(matcapTextureLabel, matcapTextureProperty, matcapTextureTintProperty);
                materialEditor.ShaderProperty(matcapTextureBlendProperty, matcapTextureBlendLabel);
                materialEditor.ShaderProperty(matcapTextureBlendModeProperty, matcapTextureBlendModeLabel);

                EditorGUI.EndDisabledGroup();

                GUILayout.Space(20);
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void FlipbookOptions(MaterialEditor materialEditor, Material targetMaterial)
        {
            showFlipbookOptions = EditorGUILayout.BeginFoldoutHeaderGroup(showFlipbookOptions, flipbookFoldoutLabel);

            if (showFlipbookOptions)
            {
                materialEditor.ShaderProperty(isFlipbookEnabledProperty, isFlipbookEnabledLabel);

                EditorGUI.BeginDisabledGroup(isFlipbookEnabledProperty.floatValue == 0.0f);

                materialEditor.TexturePropertySingleLine(flipbookLabel, flipbookProperty, flipbookTintProperty);
                materialEditor.TextureScaleOffsetProperty(flipbookProperty);
                Vector2Property(flipbookScrollVelocityProperty, flipbookScrollVelocityLabel);
                materialEditor.ShaderProperty(flipbookBlendModeProperty, flipbookBlendModeLabel);
                materialEditor.ShaderProperty(flipbookFramesPerSecondProperty, flipbookFramesPerSecondLabel);
                materialEditor.ShaderProperty(useFlipbookSmoothingProperty, useFlipbookSmoothingLabel);

                materialEditor.ShaderProperty(flipbookUseManualFrameProperty, flipbookUseManualFrameLabel);
                if (flipbookUseManualFrameProperty.floatValue > 0.0f)
                {
                    materialEditor.ShaderProperty(flipbookManualFrameProperty, flipbookManualFrameLabel);
                }

                EditorGUI.EndDisabledGroup();

                GUILayout.Space(20);
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void EffectOptions(MaterialEditor materialEditor, Material targetMaterial)
        {
            showEffectOptions = EditorGUILayout.BeginFoldoutHeaderGroup(showEffectOptions, effectFoldoutLabel);

            if (showEffectOptions)
            {
                materialEditor.ShaderProperty(useAffineMappingProperty, useAffineMappingLabel);

                EditorGUI.BeginDisabledGroup(useAffineMappingProperty.floatValue == 0.0f);
                materialEditor.ShaderProperty(affineDistortionProperty, affineDistortionLabel);
                EditorGUI.EndDisabledGroup();

                materialEditor.ShaderProperty(usePolygonJitterProperty, usePolygonJitterLabel);

                EditorGUI.BeginDisabledGroup(usePolygonJitterProperty.floatValue == 0.0f);
                materialEditor.ShaderProperty(polygonJitterProperty, polygonJitterLabel);
                EditorGUI.EndDisabledGroup();

                GUILayout.Space(20);
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void RenderSettings(MaterialEditor materialEditor, Material targetMaterial)
        {
            showRenderSettings = EditorGUILayout.BeginFoldoutHeaderGroup(showRenderSettings, renderSettingsFoldoutLabel);

            if (showRenderSettings)
            {
                materialEditor.ShaderProperty(cullProperty, cullLabel);
                materialEditor.ShaderProperty(useFogProperty, useFogLabel);

                materialEditor.ShaderProperty(receiveShadowsProperty, receiveShadowsLabel);
                // The forward add pass is only used to receive cast shadows.
                targetMaterial.SetShaderPassEnabled("ForwardAdd", receiveShadowsProperty.floatValue == 1.0f);

                materialEditor.ShaderProperty(offsetFactorProperty, offsetFactorLabel);
                materialEditor.ShaderProperty(offsetUnitsProperty, offsetUnitsLabel);
                materialEditor.EnableInstancingField();

                GUILayout.Space(20);
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }

        private void SetBlendMode(Material material)
        {
            BlendMode blendMode = (BlendMode)material.GetInt("_BlendMode");

            switch (blendMode)
            {
                case BlendMode.Opaque:
                    {
                        material.SetOverrideTag("RenderType", "Opaque");
                        material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
                        material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.Zero);
                        material.SetFloat("_BlendOp", (float)UnityEngine.Rendering.BlendOp.Add);
                        material.SetFloat("_ZTest", 4.0f);
                        material.SetFloat("_ZWrite", 1.0f);
                        material.SetFloat("_UseAlphaTest", 0.0f);
                        material.DisableKeyword("USE_ALPHA_TEST");
                        material.SetFloat("_AlphaToMask", 0.0f);
                        material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                        break;
                    }

                case BlendMode.Cutout:
                    {
                        material.SetOverrideTag("RenderType", "TransparentCutout");
                        material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
                        material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.Zero);
                        material.SetFloat("_BlendOp", (float)UnityEngine.Rendering.BlendOp.Add);
                        material.SetFloat("_ZTest", 4.0f);
                        material.SetFloat("_ZWrite", 1.0f);
                        material.SetFloat("_UseAlphaTest", 1.0f);
                        material.EnableKeyword("USE_ALPHA_TEST");
                        material.SetFloat("_AlphaToMask", 1.0f);
                        material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                        break;
                    }

                case BlendMode.Transparent:
                    {
                        material.SetOverrideTag("RenderType", "Transparent");
                        material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                        material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        material.SetFloat("_BlendOp", (float)UnityEngine.Rendering.BlendOp.Add);
                        material.SetFloat("_ZTest", 4.0f);
                        material.SetFloat("_ZWrite", 0.0f);
                        material.SetFloat("_UseAlphaTest", 0.0f);
                        material.DisableKeyword("USE_ALPHA_TEST");
                        material.SetFloat("_AlphaToMask", 0.0f);
                        material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                        break;
                    }

                case BlendMode.Custom:
                    {
                        material.SetOverrideTag("RenderType", "Opaque");
                        break;
                    }

                default:
                    break;
            }
        }

        private void Vector2Property(MaterialProperty property, GUIContent name)
        {
            EditorGUI.BeginChangeCheck();
            Vector2 vector2 = EditorGUILayout.Vector2Field(name, new Vector2(property.vectorValue.x, property.vectorValue.y), null);
            if (EditorGUI.EndChangeCheck())
            {
                property.vectorValue = new Vector4(vector2.x, vector2.y, property.vectorValue.z, property.vectorValue.w);
            }
        }
    }
}