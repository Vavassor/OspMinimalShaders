// A per-vertex lighting shader that supports vertex lightmaps and a light source fixed to the camera.
Shader "OSP Minimal/Vertex Lit"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
        [Enum(None, 0, Multiply, 1)] _VertexColorBlendMode("Vertex Color", Float) = 1
        [Toggle(ALPHA_TEST_ON)] _UseAlphaTest("Use Alpha Test", Float) = 0
        _Cutoff("Alpha Cutoff", Float) = 0.5
        [Toggle(USE_GAMMA_SPACE)] _UseGammaSpace("Use Gamma Space Blending", Float) = 0
        [Toggle(PIXEL_SHARPEN_ON)] _UsePixelSharpen("Sharp Pixels", Float) = 0
        
        [Header(Detail)]
        [Toggle(DETAIL_MAP_ON)] _UseDetailMap("Enable", Float) = 0
        _DetailMap("Detail", 2D) = "white" {}
        _DetailMapTint("Tint", Color) = (1,1,1,1)
        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3)] _DetailUvSet("UV Set", Float) = 0
        [Enum(Mask Red, 0, Vertex Color Red, 1, Vertex Color Green, 2, Vertex Color Blue, 3, Vertex Color Alpha, 4)] _DetailMaskType("Mask Type", Int) = 0
        [NoScaleOffset] _DetailMask("Detail Mask", 2D) = "white" {}
        _DetailMapBlend("Strength", Range(0, 1)) = 1
        [Enum(Lerp,0,Transparent,1,Add,2,Multiply,3)] _DetailTextureBlendMode("Blend Mode", Float) = 0

        [Header(Lighting)]
        // _Ramp("Shadow Ramp", 2D) = "white" {}
        _LightingBlend("Lighting", Range(0, 1)) = 1
        _ShadowBoost("Shadow Boost", Range(0,1)) = 0.0
        _ShadowAlbedo("Shadow Tint", Range(0,1)) = 0.5
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Float) = 10
        _FinalLightingMultiplier("Final Lighting Multiplier", Float) = 1
        _FinalLightingMinBrightness("Final Lighting Min Brightness", Float) = 0
        [KeywordEnum(None,Vertex)] _Vrclv_Mode("VRC Light Volumes", Int) = 0

        [Header(Fixed Light)]
        [Toggle(FIXED_LIGHT_ON)] _UseFixedLight("Fixed Light", Float) = 0
        _FixedAmbientColor("Ambient Color", Color) = (0.5, 0.5, 0.5, 1.0)
        _FixedLightColor("Light Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // The default is Mario 64 light direction. https://forum.unity.com/threads/fake-shadows-in-shader.1276139/#post-8098937
        _FixedLightDirection("Light Direction", Vector) = (-0.6929, -0.6929, -0.6929, 0.0)
        
        [Header(Effects)]
        [Toggle(AFFINE_MAPPING_ON)] _UseAffineMapping("Use Affine Mapping", Float) = 0
        _AffineDistortion("Affine Distortion", Range(0, 8)) = 0.5
        [Toggle(POLYGON_JITTER_ON)] _UsePolygonJitter("Use Polygon Jitter", Float) = 0
        _PolygonJitter("Polygon Jitter", Range(0,8)) = 4
        
        [Header(Dither)]
        [Toggle(DITHER_ON)] _UseDither("Enabled", Int) = 0
        [NoScaleOffset] _DitherPattern("Pattern", 2D) = "black" {}
        [Enum(UV0, 0, Screen_UV, 4)] _DitherUvSet("UV Set", Int) = 0
        [IntRange] _DitherScale("Scale", Range(1, 16)) = 2
        _DitherColorDepth("Color Depth", Float) = 32
        
        [Header(UV Tile Discard)]
        [Toggle(UV_TILE_DISCARD_ON)] _UseUvTileDiscard("Enable", Float) = 0
        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3)] _TileDiscardUvSet("UV Set", Float) = 0
        _UvTileDiscardRow0("Row 0", Vector) = (0, 0, 0, 0)
        _UvTileDiscardRow1("Row 1", Vector) = (0, 0, 0, 0)
        _UvTileDiscardRow2("Row 2", Vector) = (0, 0, 0, 0)
        _UvTileDiscardRow3("Row 3", Vector) = (0, 0, 0, 0)
        
        [Header(Blend)]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Source Blend", Float) = 5 //"SrcAlpha"
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Destination Blend", Float) = 10 //"OneMinusSrcAlpha"
        [Enum(Add,0,Sub,1,RevSub,2,Min,3,Max,4)] _BlendOp("Blend Operation", Float) = 0 // "Add"
        
        [Header(Culling)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull", Float) = 2 //"Back"
        
        [Header(Depth Test)]
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4 //"LessEqual"
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Float) = 0.0 //"Off"
        _OffsetFactor("Offset Factor", Range(-1, 1)) = 0
        _OffsetUnits("Offset Units", Range(-1, 1)) = 0
        
        [Header(Stencil)]
        _StencilRef("Reference", Int) = 0
        _StencilReadMask("Read Mask", Int) = 255
        _StencilWriteMask("Write Mask", Int) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass("Pass", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFail("Fail", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail("ZFail", Float) = 0
    }
    SubShader
    {
        Blend [_BlendSrc] [_BlendDst]
        BlendOp [_BlendOp]
        Cull [_CullMode]
        Offset [_OffsetFactor], [_OffsetUnits]
        Stencil
        {
            Ref [_StencilRef]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask] 
            Comp [_StencilComp]
            Pass [_StencilPass]
            Fail [_StencilFail]
            ZFail [_StencilZFail]
        }
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase nodirlightmap nodynlightmap
            #pragma multi_compile_instancing
            #pragma shader_feature_local AFFINE_MAPPING_ON
            #pragma shader_feature_local ALPHA_TEST_ON
            #pragma shader_feature_local DETAIL_MAP_ON
            #pragma shader_feature_local DITHER_ON
            #pragma shader_feature_local FIXED_LIGHT_ON
            #pragma shader_feature_local PIXEL_SHARPEN_ON
            #pragma shader_feature_local POLYGON_JITTER_ON
            #pragma shader_feature_local USE_GAMMA_SPACE
            #pragma shader_feature_local UV_TILE_DISCARD_ON
            #pragma shader_feature_local _VRCLV_MODE_NONE _VRCLV_MODE_VERTEX
            #include "./Vertex Lit.cginc"
            ENDCG
        }
        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            
            Blend One One // additive blending

            CGPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd
            #pragma multi_compile_instancing
            #pragma shader_feature_local AFFINE_MAPPING_ON
            #pragma shader_feature_local ALPHA_TEST_ON
            #pragma shader_feature_local DETAIL_MAP_ON
            #pragma shader_feature_local DITHER_ON
            #pragma shader_feature_local PIXEL_SHARPEN_ON
            #pragma shader_feature_local POLYGON_JITTER_ON
            #pragma shader_feature_local USE_GAMMA_SPACE
            #pragma shader_feature_local UV_TILE_DISCARD_ON
            #include "./Vertex Lit.cginc"
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
            #pragma vertex VertexMeta
            #pragma fragment FragmentMeta
            #pragma shader_feature EDITOR_VISUALIZATION
            #include "./Vertex Lit Meta.cginc"
            ENDCG
        }
    }
}