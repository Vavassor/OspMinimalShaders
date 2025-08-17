#ifndef VERTEX_LIT_META_CGINC_
#define VERTEX_LIT_META_CGINC_

#include "UnityStandardMeta.cginc"

struct FragmentInput
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
#ifdef EDITOR_VISUALIZATION
    float2 vizUV        : TEXCOORD1;
    float4 lightCoord   : TEXCOORD2;
#endif
};

FragmentInput VertexMeta(VertexInput v)
{
    FragmentInput o;
    o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
    o.uv = float4(v.uv0, 0, 0);
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

float4 FragmentMeta(v2f_meta i) : SV_Target
{
    UnityMetaInput o;
    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);
    
    fixed4 baseColor = tex2D(_MainTex, i.uv) * _Color;
    half3 diffuseColor = baseColor.rgb;
    
    #ifdef EDITOR_VISUALIZATION
        o.Albedo = diffuseColor;
        o.VizUV = i.vizUV;
        o.LightCoord = i.lightCoord;
    #else
        o.Albedo = diffuseColor;
        o.SpecularColor = _SpecColor.xyz;
    #endif
    
    return UnityMetaFragment(o);
}

#endif // VERTEX_LIT_META_CGINC_
