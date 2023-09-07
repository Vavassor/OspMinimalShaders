// Billboards are a flat image or sprite that always face the camera.
Shader "OSP Minimal/Billboard"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	    _Color("Tint", Color) = (1, 1, 1, 1)
		[KeywordEnum(Multiply, Overlay)] _ColorMode("Tint Color Mode", Float) = 0
		[HideInInspector] [Enum(Opaque,0,Cutout,1,Transparent,2,Custom,3)] _BlendMode("Blend Mode", Int) = 2
	    [Toggle(USE_GAMMA_COLORSPACE)] _UseGammaSpace("Use Gamma Space Blending", Float) = 1
		[Toggle(STAY_UPRIGHT)] _StayUpright("Stay Upright", Float) = 1

		[Toggle(USE_FLIPBOOK)] _UseFlipbook("Enable Flipbook", Float) = 0
		_FlipbookTexArray("Texture Array", 2DArray) = "" {}
		_FlipbookTint("Tint", Color) = (1,1,1,1)
		_FlipbookScrollVelocity("Scroll Velocity", Vector) = (0, 0, 0, 0)
		[Enum(Replace,0,Transparent,1,Add,2,Multiply,3)] _FlipbookBlendMode("Blend Mode", Float) = 0
		_FlipbookFramesPerSecond("Frames Per Second", Float) = 30
		[Toggle(USE_FLIPBOOK_SMOOTHING)] _UseFlipbookSmoothing("Smoothing", Float) = 0
		[Toggle] _FlipbookUseManualFrame("Control Frame Manually", Float) = 0
		_FlipbookManualFrame("Manual Frame", Float) = 0

		[Toggle(USE_ALPHA_TEST)] _UseAlphaTest("Enable Alpha Test", Float) = 0
		_AlphaCutoff("Alpha Cutoff", Float) = 0.5
		[Toggle] _AlphaToMask("Alpha To Mask", Float) = 1

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Source Blend", Float) = 5 //"SrcAlpha"
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Destination Blend", Float) = 10 //"OneMinusSrcAlpha"
		[Enum(Add,0,Sub,1,RevSub,2,Min,3,Max,4)] _BlendOp("Blend Operation", Float) = 0 // "Add"

		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LessEqual"
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 0.0 //"Off"
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
		    "RenderType" = "Transparent"
		    "DisableBatching" = "True"
			"PreviewType" = "Plane"
	    }

	    Blend [_SrcBlend] [_DstBlend]
		BlendOp [_BlendOp]
		ZTest [_ZTest]
		ZWrite [_ZWrite]
		Cull Off
		AlphaToMask [_AlphaToMask]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma shader_feature_local _ _COLORMODE_MULTIPLY _COLORMODE_OVERLAY
			#pragma shader_feature_local USE_GAMMA_COLORSPACE
		    #pragma shader_feature_local USE_FLIPBOOK
			#pragma shader_feature_local USE_FLIPBOOK_SMOOTHING
			#pragma shader_feature_local USE_ALPHA_TEST
			#pragma shader_feature_local STAY_UPRIGHT

			#include "UnityCG.cginc"
			#include "OspMinimalCore.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				UNITY_FOG_COORDS(2)
				float4 pos : SV_POSITION;
			};

			UNITY_DECLARE_TEX2D(_MainTex);
			float4 _MainTex_ST;
			float4 _Color;

			// Flipbook
			UNITY_DECLARE_TEX2DARRAY(_FlipbookTexArray);
			float4 _FlipbookTexArray_ST;
			float4 _FlipbookTint;
			float2 _FlipbookScrollVelocity;
			float _FlipbookBlendMode;
			float _FlipbookFramesPerSecond;
			float _FlipbookUseManualFrame;
			int _FlipbookManualFrame;

			// Alpha Test
			float _AlphaCutoff;

			bool IsInMirror()
			{
				return unity_CameraProjection[2][0] != 0.0f || unity_CameraProjection[2][1] != 0.0f;
			}

			float3 GetCenterCameraPosition()
			{
				#if defined(USING_STEREO_MATRICES)
					float3 worldPosition = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) / 2.0;
				#else
					float3 worldPosition = _WorldSpaceCameraPos.xyz;
				#endif
				return worldPosition;
			}

			float4x4 LookAtMatrix(float3 forward, float3 up)
			{
				float3 xAxis = normalize(cross(forward, up));
				float3 yAxis = up;
				float3 zAxis = forward;
				return float4x4(
					xAxis.x, yAxis.x, zAxis.x, 0,
					xAxis.y, yAxis.y, zAxis.y, 0,
					xAxis.z, yAxis.z, zAxis.z, 0,
					0, 0, 0, 1
					);
			}

			// Decompose the scale from a transformation matrix.
			float3 GetScale(float4x4 m)
			{
				float3 scale;

				scale.x = length(float3(m[0][0], m[0][1], m[0][2]));
				scale.y = length(float3(m[1][0], m[1][1], m[1][2]));
				scale.z = length(float3(m[2][0], m[2][1], m[2][2]));

				return scale;
			}

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				float3 cameraPositionWs = GetCenterCameraPosition();
				float3 objectCenterWs = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
				float3 objectScale = GetScale(unity_ObjectToWorld);
				float3 forward = mul(unity_ObjectToWorld, float4(0, 0, 1, 0)).xyz;
				float3 viewDirectionWs = objectCenterWs - cameraPositionWs;

				if (IsInMirror())
				{
					viewDirectionWs = mul((float3x3) unity_WorldToObject, unity_CameraWorldClipPlanes[5].xyz);
				}

				#if defined(STAY_UPRIGHT)
					float3 up = float3(0, 1, 0);
				#else
					float3 up = mul(UNITY_MATRIX_I_V, float4(0, 1, 0, 0)).xyz;
				#endif

				float3x3 rotation = LookAtMatrix(viewDirectionWs, up);
				float3 positionWs = mul(rotation, objectScale * length(forward) * v.vertex.xyz) + objectCenterWs.xyz;
				o.pos = mul(UNITY_MATRIX_VP, float4(positionWs, 1.0));

				o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);

				#ifdef USE_FLIPBOOK
					float2 transformedTexcoord = TRANSFORM_TEX(v.uv, _FlipbookTexArray);
					float2 scrolledTexcoord = transformedTexcoord + _Time.y * _FlipbookScrollVelocity;
					o.uv1 = GetFlipbookTexcoord(_FlipbookTexArray, scrolledTexcoord, _FlipbookFramesPerSecond, _FlipbookUseManualFrame, _FlipbookManualFrame);
				#endif

				UNITY_TRANSFER_FOG(o,o.pos);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv0);
				col.rgb = AdjustToShadingColorSpace(col.rgb);

				#if defined(_COLORMODE_MULTIPLY)
					col *= _Color;
				#elif defined(_COLORMODE_OVERLAY)
					col.rgb = lerp(1 - 2 * (1 - col.rgb) * (1 - _Color.rgb), 2 * col.rgb * _Color.rgb, step(col.rgb, 0.5));
					col.a *= _Color.a;
				#endif

				#if defined(USE_FLIPBOOK)
					float4 flipbookColor = UNITY_SAMPLE_TEX2DARRAY(_FlipbookTexArray, i.uv1.xyz);

					#if defined(USE_FLIPBOOK_SMOOTHING)
						float4 flipbookColor2 = UNITY_SAMPLE_TEX2DARRAY(_FlipbookTexArray, i.uv1.xyw);
						flipbookColor = lerp(flipbookColor, flipbookColor2, frac(i.uv1.z));
					#endif

					flipbookColor.rgb = AdjustToShadingColorSpace(flipbookColor.rgb);
					col = BlendColor(_FlipbookTint * flipbookColor, col, _FlipbookBlendMode);
				#endif

				#ifdef USE_ALPHA_TEST
					clip(col.a - _AlphaCutoff);
				#endif

				col.rgb = AdjustFromShadingColorSpace(col.rgb);

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
	CustomEditor "OrchidSeal.MinimalShaders.Editor.BillboardEditor"
}
