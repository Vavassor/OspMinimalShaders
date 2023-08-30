Shader "OSP Minimal/Particle"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	    _Color("Color", Color) = (1, 1, 1, 1)
		[KeywordEnum(Multiply, Overlay)] _ColorMode("Color Mode", Float) = 0
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
		    "RenderType" = "Transparent"
		    "DisableBatching" = "True"
	    }

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma shader_feature_local _ _COLORMODE_MULTIPLY _COLORMODE_OVERLAY

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 pos : SV_POSITION;
			};

			UNITY_DECLARE_TEX2D(_MainTex);
			float4 _MainTex_ST;
			float4 _Color;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				float4 objectPositionVs = float4(UnityObjectToViewPos(float3(0.0, 0.0, 0.0)), 1.0);
				float4 vertexPositionVs = float4(v.vertex.x, v.vertex.y, 0.0, 0.0);
				o.pos = mul(UNITY_MATRIX_P, objectPositionVs + vertexPositionVs);

				UNITY_TRANSFER_FOG(o,o.pos);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv);

#if defined(_COLORMODE_MULTIPLY)
				col *= _Color;
#elif defined(_COLORMODE_OVERLAY)
				col.rgb = lerp(1 - 2 * (1 - col.rgb) * (1 - _Color.rgb), 2 * col.rgb * _Color.rgb, step(col.rgb, 0.5));
				col.a *= _Color.a;
#endif

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
