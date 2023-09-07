// An unlit shader for transparent objects. It optionally supports lightmaps.
Shader "OSP Minimal/Unlit Transparent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1, 1, 1, 1)
        [KeywordEnum(None, Multiply, Bakery Lightmaps)] _VertexColorMode("Vertex Color Mode", Float) = 1
        [Toggle(USE_GAMMA_COLORSPACE)] _UseGammaSpace("Use Gamma Space Blending", Float) = 1
        [Toggle(USE_FOG)] _UseFog("Use Fog", Float) = 1
        [Toggle(USE_LIGHTMAP)] _UseLightmap("Use Lightmap", Float) = 1
        [Enum(Premultiplied Alpha,1,Straight Alpha,5)] _SrcBlend("Alpha Blend", Float) = 5
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Blend [_SrcBlend] OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        Cull [_Cull]

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nodirlightmap nodynlightmap novertexlight
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma shader_feature_local _VERTEXCOLORMODE_NONE _VERTEXCOLORMODE_MULTIPLY _VERTEXCOLORMODE_BAKERY_LIGHTMAPS
            #pragma shader_feature_local USE_GAMMA_COLORSPACE
            #pragma shader_feature_local USE_FOG
            #pragma shader_feature_local USE_LIGHTMAP

            #include "UnityCG.cginc"
            #include "OspMinimalCore.cginc"
            #include "Unlit Standard.cginc"
            
            ENDCG
        }
        Pass
        {
            Name "META"
            Tags { "LightMode" = "Meta" }
            Cull Off

            CGPROGRAM
            #pragma vertex vert_meta
            #pragma fragment frag_meta
            #pragma shader_feature_local _VERTEXCOLORMODE_NONE _VERTEXCOLORMODE_MULTIPLY _VERTEXCOLORMODE_BAKERY_LIGHTMAPS
            #pragma shader_feature_local USE_GAMMA_COLORSPACE
            #include "Unlit Standard.cginc"
            ENDCG
        }
    }
}
