// This shader is for materials for the Projector component.
// https://docs.unity3d.com/2019.4/Documentation/Manual/class-Projector.html
Shader "OSP Minimal/Projector Multiply"
{
    Properties
    {
		[NoScaleOffset] _ShadowTex("Cookie", 2D) = "gray" {}
		[NoScaleOffset] _FalloffTex("FallOff", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
			ZWrite Off

			// Multiplicative blending
			Blend Zero OneMinusSrcAlpha
			Offset -1, -1

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _ShadowTex;
			sampler2D _FalloffTex;

			float4x4 unity_Projector;
			float4x4 unity_ProjectorClip;

			struct v2f
			{
				float4 uvShadow : TEXCOORD0;
				float4 uvFalloff : TEXCOORD1;
				UNITY_FOG_COORDS(2)
				float4 pos : SV_POSITION;
			};

			v2f vert(float4 vertex : POSITION)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(vertex);
				o.uvShadow = mul(unity_Projector, vertex);
				o.uvFalloff = mul(unity_ProjectorClip, vertex);
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 texS = tex2Dproj(_ShadowTex, UNITY_PROJ_COORD(i.uvShadow));
				texS.a = 1.0 - texS.a;

				fixed4 texF = tex2Dproj(_FalloffTex, UNITY_PROJ_COORD(i.uvFalloff));
				fixed4 res = lerp(fixed4(1,1,1,0), texS, texF.a);

				UNITY_APPLY_FOG_COLOR(i.fogCoord, res, fixed4(1,1,1,1));
				return res;
			}
			ENDCG
        }
    }
}
