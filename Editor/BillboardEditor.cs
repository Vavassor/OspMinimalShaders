using UnityEngine;
using UnityEditor;

namespace OrchidSeal.MinimalShaders.Editor
{
    public class BillboardEditor : ShaderGUI
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
		MaterialProperty tintColorModeProperty = null;

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

		// Render setting properties
		MaterialProperty stayUprightProperty = null;

		bool showBlendingOptions = true;
		bool showBaseOptions = true;
		bool showFlipbookOptions = false;
		bool showRenderOptions = false;

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
		private GUIContent useGammaSpaceLabel = new GUIContent("Use Gamma Space Blending");

		// Base option labels
		private string baseFoldoutLabel = "Base";
		private GUIContent baseTextureLabel = new GUIContent("Base Color");
		private GUIContent tintColorModeLabel = new GUIContent("Tint Color Mode");

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

		// Render setting labels
		private string renderSettingsFoldoutLabel = "Render Settings";
		private GUIContent stayUprightLabel = new GUIContent("Stay Upright");

		override public void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			// Intentionally don't call the base class so that the normal settings aren't rendered.
			// base.OnGUI(materialEditor, properties);

			FindProperties(properties);

			Material targetMaterial = materialEditor.target as Material;
			string[] keywords = targetMaterial.shaderKeywords;

			BlendingOptions(materialEditor, targetMaterial);
			BaseOptions(materialEditor, targetMaterial);
			FlipbookOptions(materialEditor, targetMaterial);
			RenderOptions(materialEditor, targetMaterial);

			materialEditor.EnableInstancingField();
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
			tintColorModeProperty = FindProperty("_ColorMode", properties);

			isFlipbookEnabledProperty = FindProperty("_UseFlipbook", properties);
			flipbookProperty = FindProperty("_FlipbookTexArray", properties);
			flipbookTintProperty = FindProperty("_FlipbookTint", properties);
			flipbookScrollVelocityProperty = FindProperty("_FlipbookScrollVelocity", properties);
			flipbookBlendModeProperty = FindProperty("_FlipbookBlendMode", properties);
			flipbookFramesPerSecondProperty = FindProperty("_FlipbookFramesPerSecond", properties);
			useFlipbookSmoothingProperty = FindProperty("_UseFlipbookSmoothing", properties);
			flipbookUseManualFrameProperty = FindProperty("_FlipbookUseManualFrame", properties);
			flipbookManualFrameProperty = FindProperty("_FlipbookManualFrame", properties);

			stayUprightProperty = FindProperty("_StayUpright", properties);
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
				materialEditor.ShaderProperty(tintColorModeProperty, tintColorModeLabel);
				materialEditor.TextureScaleOffsetProperty(baseTextureProperty);

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

		private void RenderOptions(MaterialEditor materialEditor, Material targetMaterial)
		{
			showRenderOptions = EditorGUILayout.BeginFoldoutHeaderGroup(showRenderOptions, renderSettingsFoldoutLabel);

			if (showRenderOptions)
			{
				materialEditor.ShaderProperty(stayUprightProperty, stayUprightLabel);

				GUILayout.Space(20);
			}

			EditorGUILayout.EndFoldoutHeaderGroup();
		}

		private void SetBlendMode(Material material)
		{
			BlendMode blendMode = (BlendMode) material.GetInt("_BlendMode");

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
	}
}
