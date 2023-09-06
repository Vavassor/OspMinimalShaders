#ifndef UNLIT_STANDARD_CGINC_
#define UNLIT_STANDARD_CGINC_

#include "OspMinimalCore.cginc"
#include "UnityMetaPass.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
    float4 color : COLOR0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float4 color : TEXCOORD3;
    OSP_FOG_COORDS(4)
    float4 vertex : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};

struct v2f_meta
{
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float4 color : TEXCOORD1;
#ifdef EDITOR_VISUALIZATION
    float2 vizUV        : TEXCOORD4;
    float4 lightCoord   : TEXCOORD5;
#endif
};

UNITY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST;
float4 _Color;

float _AlphaCutoff;

// Forward Base Pass............................................................

v2f vert(appdata v)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
    o.uv1 = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;

#ifdef _VERTEXCOLORMODE_BAKERY_LIGHTMAPS
    o.color = DecodeBakeryVertexLightmap(v.color);
#else
    o.color = v.color;
#endif

    OSP_TRANSFER_FOG(v.vertex, o)

    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

    fixed4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv0);
    col.rgb = AdjustToShadingColorSpace(col.rgb);
    col *= _Color;

#if defined(USE_ALPHA_TEST)
    clip(col.a - _AlphaCutoff);
#endif

#if defined(_VERTEXCOLORMODE_MULTIPLY) || defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
    col.rgb *= i.color.rgb;
#endif

    col.rgb = AdjustFromShadingColorSpace(col.rgb);

#if defined(LIGHTMAP_ON) && defined(USE_LIGHTMAP) && !defined(_VERTEXCOLORMODE_BAKERY_LIGHTMAPS)
    col.rgb *= SampleLightmap(i.uv1.xy);
#endif

#if defined(USE_FOG)
    OSP_APPLY_FOG(col, i)
#endif

    return col;
}

// Meta Pass....................................................................

v2f_meta vert_meta(appdata v)
{
    v2f_meta o;
    o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
    o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
    o.color = v.color;

#ifdef EDITOR_VISUALIZATION
    o.vizUV = 0;
    o.lightCoord = 0;

    if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
    {
        o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.uv0.xy, v.uv1.xy, v.uv2.xy, unity_EditorViz_Texture_ST);
    }
    else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
    {
        o.vizUV = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
    }
#endif

    return o;
}

float4 frag_meta(v2f_meta i) : SV_Target
{
    UnityMetaInput o;
    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

    fixed4 albedo = UNITY_SAMPLE_TEX2D(_MainTex, i.uv0);
    albedo.rgb = AdjustToShadingColorSpace(albedo.rgb);
    albedo *= _Color;

#if defined(USE_ALPHA_TEST)
    clip(alpha.a - _AlphaCutoff);
#endif

#if defined(_VERTEXCOLORMODE_MULTIPLY)
    albedo.rgb *= i.color.rgb;
#endif

    albedo.rgb = AdjustFromShadingColorSpace(albedo.rgb);

#ifdef EDITOR_VISUALIZATION
    o.Albedo = albedo;
    o.VizUV = i.vizUV;
    o.LightCoord = i.lightCoord;
#else
    o.Albedo = albedo;
#endif

    return UnityMetaFragment(o);
}

#endif // UNLIT_STANDARD_CGINC_