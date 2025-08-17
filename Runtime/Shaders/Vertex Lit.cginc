#ifndef VERTEX_LIT_CGINC_
#define VERTEX_LIT_CGINC_

#include "UnityCG.cginc"
#include <AutoLight.cginc>
#include <UnityPBSLighting.cginc>

#if defined(_VRCLV_MODE_VERTEX)
#include "LightVolumes.cginc"
#endif

// Light coordinates...............................................................................

#ifdef POINT
#define OSP_DECLARE_LIGHT_COORDS(idx) unityShadowCoord3 _LightCoord : TEXCOORD##idx;
#define OSP_COMPUTE_LIGHT_COORDS(a, positionWs) a._LightCoord = mul(unity_WorldToLight, positionWs).xyz;
// #define OSP_LIGHT_ATTENUATION(input) \
//     (tex2D(_LightTexture0, dot(input._LightCoord, input._LightCoord).rr).r)
#define OSP_LIGHT_ATTENUATION(input) \
    (tex2Dlod(_LightTexture0, float4(dot(input._LightCoord, input._LightCoord).rr, 0, 0)).r)
#endif

#ifdef SPOT
#define OSP_DECLARE_LIGHT_COORDS(idx) unityShadowCoord4 _LightCoord : TEXCOORD##idx;
#define OSP_COMPUTE_LIGHT_COORDS(a, positionWs) a._LightCoord = mul(unity_WorldToLight, positionWs);
// #define OSP_LIGHT_ATTENUATION(input) \
//     ((input._LightCoord.z > 0) * tex2D(_LightTexture0, input._LightCoord.xy / input._LightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(input._LightCoord.xyz, input._LightCoord.xyz).xx).r)
#define OSP_LIGHT_ATTENUATION(input) \
    ((input._LightCoord.z > 0) * tex2Dlod(_LightTexture0, float4(input._LightCoord.xy / input._LightCoord.w + 0.5, 0, 0)).w * tex2Dlod(_LightTextureB0, float4(dot(input._LightCoord.xyz, input._LightCoord.xyz).xx, 0, 0)).r)
#endif

#ifdef DIRECTIONAL
#define OSP_DECLARE_LIGHT_COORDS(idx)
#define OSP_COMPUTE_LIGHT_COORDS(a, positionWs)
#define OSP_LIGHT_ATTENUATION(input) 1.0
#endif

#ifdef POINT_COOKIE
#define OSP_DECLARE_LIGHT_COORDS(idx) unityShadowCoord3 _LightCoord : TEXCOORD##idx;
#define OSP_COMPUTE_LIGHT_COORDS(a, positionWs) a._LightCoord = mul(unity_WorldToLight, positionWs).xyz;
// #define OSP_LIGHT_ATTENUATION(input) \
//     (tex2D(_LightTextureB0, dot(input._LightCoord, input._LightCoord).rr).r * texCUBE(_LightTexture0, input._LightCoord).w)
#define OSP_LIGHT_ATTENUATION(input) \
     (tex2Dlod(_LightTextureB0, float4(dot(input._LightCoord, input._LightCoord).rr, 0, 0)).r * texCUBElod(_LightTexture0, float4(input._LightCoord, 0)).w)
#endif

#ifdef DIRECTIONAL_COOKIE
#define OSP_DECLARE_LIGHT_COORDS(idx) unityShadowCoord2 _LightCoord : TEXCOORD##idx;
#define OSP_COMPUTE_LIGHT_COORDS(a, positionWs) a._LightCoord = mul(unity_WorldToLight, positionWs).xy;
// #define OSP_LIGHT_ATTENUATION(input) \
//     (tex2D(_LightTexture0, input._LightCoord).w)
#define OSP_LIGHT_ATTENUATION(input) \
    (tex2Dlod(_LightTexture0, float4(input._LightCoord, 0, 0)).w)
#endif

// Shadow Receiving................................................................................

// Macros from AutoLight.cginc assume variables have specific names which differ from ours.
// So redefine our own here.

#if defined(SHADOWS_SCREEN)
#if defined(UNITY_NO_SCREENSPACE_SHADOWS)
#define OSP_TRANSFER_SHADOW(a, positionCs, positionWs) a._ShadowCoord = mul(unity_WorldToShadow[0], positionWs);
#else // UNITY_NO_SCREENSPACE_SHADOWS
#define OSP_TRANSFER_SHADOW(a, positionCs, positionWs) a._ShadowCoord = ComputeScreenPos(positionCs);
#endif
#define OSP_SHADOW_COORDS(idx1) unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
#endif // SHADOWS_SCREEN

#if defined (SHADOWS_DEPTH) && defined (SPOT)
#define OSP_SHADOW_COORDS(idx1) unityShadowCoord4 _ShadowCoord : TEXCOORD##idx1;
#define OSP_TRANSFER_SHADOW(a, positionCs, positionWs) a._ShadowCoord = mul(unity_WorldToShadow[0], positionWs);
#endif

#if defined (SHADOWS_CUBE)
#define OSP_SHADOW_COORDS(idx1) unityShadowCoord3 _ShadowCoord : TEXCOORD##idx1;
#define OSP_TRANSFER_SHADOW(a, positionCs, positionWs) a._ShadowCoord.xyz = positionWs.xyz - _LightPositionRange.xyz;
#endif

#if !defined (SHADOWS_SCREEN) && !defined (SHADOWS_DEPTH) && !defined (SHADOWS_CUBE)
#define OSP_SHADOW_COORDS(idx1)
#define OSP_TRANSFER_SHADOW(a, positionCs, positionWs)
#endif

// Pixel Sharpen....................................................................................

// https://github.com/cnlohr/shadertrixx/blob/main/README.md#lyuma-beautiful-retro-pixels-technique
float2 SharpenPixelUv(float2 uv, float4 texelSize)
{
    float2 coord = uv.xy * texelSize.zw;
    float2 fr = frac(coord + 0.5);
    float2 fw = max(abs(ddx(coord)), abs(ddy(coord)));
    return uv.xy + (saturate((fr-(1-fw)*0.5)/fw) - fr) * texelSize.xy;
}

// Polygon Jitter...............................................................

// The vertex jitter on the PS1 and DS is due to the lack of subpixel
// rasterization. So, simulate this by snapping vertices to the nearest pixel.
// 
// However, because modern screens are much higher resolution, the jitter isn't
// as visible. So, the amount of jitter is adjustable to use a larger than 1-pixel
// grid, to exaggerate the effect.
float4 JitterVertex(float4 clipPosition, float jitter)
{
    if (jitter == 0.0) return clipPosition;
    float4 snapped = clipPosition;
    float2 grid = (0.5 / jitter) * _ScreenParams.xy;
    snapped.xyz = clipPosition.xyz / clipPosition.w;
    snapped.xy = floor(grid * snapped.xy) / grid;
    snapped.xyz *= snapped.w;
    return snapped;
}

// In VR, JitterVertex sucks to behold. So instead round the world space position, which has a
// similar look.
float3 RoundVertex(float3 positionWs, float jitter)
{
    if (jitter < 1e-2) return positionWs;
    float grid = 20.0 * jitter;
    positionWs.xyz = floor(grid * positionWs.xyz) / grid;
    return positionWs;
}

// Color Blending...................................................................................

#define BLEND_MODE_LERP 0
#define BLEND_MODE_TRANSPARENT 1
#define BLEND_MODE_ADD 2
#define BLEND_MODE_MULTIPLY 3

float4 BlendColor(float4 s, float4 d, float blendMode)
{
    switch (blendMode)
    {
    case BLEND_MODE_LERP: return s;
    case BLEND_MODE_TRANSPARENT:
        {
            float resultAlpha = s.a + d.a * (1.0 - s.a);
            float3 resultRgb = (s.a * s.rgb + (1.0 - s.a) * d.a * d.rgb) / resultAlpha;
            return float4(resultRgb, resultAlpha);
        }
    case BLEND_MODE_ADD: return s + d;
    case BLEND_MODE_MULTIPLY: return s * d;
    default: return 0;
    }
}

// Vertex Color Blending............................................................................

#define VERTEX_COLOR_BLEND_NONE 0
#define VERTEX_COLOR_BLEND_MULTIPLY 1

float3 BlendVertexColor(float3 s, float3 d, float blendMode)
{
    switch (blendMode)
    {
        case VERTEX_COLOR_BLEND_NONE: return d;
        case VERTEX_COLOR_BLEND_MULTIPLY: return s * d;
        default: return d;
    }
}

// Input............................................................................................

struct VertexInput
{
    float4 vertex : POSITION;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
    float2 uv3 : TEXCOORD3;
    half3 normal : NORMAL;
    float4 color0 : COLOR0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct FragmentInput
{
    float4 positionCs : SV_POSITION;
    float4 uv0 : TEXCOORD0;
    float4 screenUv : TEXCOORD1;
    float4 color0 : TEXCOORD2;
    float3 directDiffuse : TEXCOORD3;
    float3 directLightColor : TEXCOORD4;
    float4 specularReflection : TEXCOORD5;
    UNITY_FOG_COORDS(6)
    half4 ambientColor : TEXCOORD7_centroid;
    half4 lightmapTexcoord : TEXCOORD8_centroid;
    OSP_DECLARE_LIGHT_COORDS(9)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

// UV Sets..........................................................................................

float2 SelectUv(VertexInput v, int index)
{
    switch(index)
    {
    case 0:
        return v.uv0.xy;
    case 1:
        return v.uv1.xy;
    case 2:
        return v.uv2.xy;
    case 3:
        return v.uv3.xy;
    default:
        return v.uv0.xy;
    }
}

// Uniforms.........................................................................................

float4 _Color;
UNITY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST;
float4 _MainTex_TexelSize;
float _VertexColorBlendMode;
half _Cutoff;

UNITY_DECLARE_TEX2D(_DetailMap);
float4 _DetailMap_ST;
float4 _DetailMap_TexelSize;
int _DetailMaskType;
UNITY_DECLARE_TEX2D(_DetailMask);
half4 _DetailMapTint;
half _DetailMapBlend;
half _DetailMapBlendMode;
half _DetailUvSet;

half _LightingBlend;
// UNITY_DECLARE_TEX2D(_Ramp);
half _ShadowBoost;
half _ShadowAlbedo;
float _Shininess;
half _FinalLightingMultiplier;
half _FinalLightingMinBrightness;

uniform float4 _FixedAmbientColor;
uniform float4 _FixedLightColor;
uniform float3 _FixedLightDirection;

float _AffineDistortion;
float _PolygonJitter;

UNITY_DECLARE_TEX2D(_DitherPattern);
float4 _DitherPattern_TexelSize;
int _DitherUvSet;
float _DitherScale;
fixed _DitherColorDepth;

float _TileDiscardUvSet;
float4 _UvTileDiscardRow0;
float4 _UvTileDiscardRow1;
float4 _UvTileDiscardRow2;
float4 _UvTileDiscardRow3;

// Detail Mask......................................................................................

#define MASK_TYPE_MAP_RED 0
#define MASK_TYPE_VERTEX_COLOR_RED 1
#define MASK_TYPE_VERTEX_COLOR_GREEN 2
#define MASK_TYPE_VERTEX_COLOR_BLUE 3
#define MASK_TYPE_VERTEX_COLOR_ALPHA 4

float GetDetailMask(FragmentInput i, int maskType, float2 uv)
{
    switch (maskType)
    {
        default:
        case MASK_TYPE_MAP_RED: return UNITY_SAMPLE_TEX2D(_DetailMask, uv).r;
        case MASK_TYPE_VERTEX_COLOR_RED: return i.color0.r;
        case MASK_TYPE_VERTEX_COLOR_GREEN: return i.color0.g;
        case MASK_TYPE_VERTEX_COLOR_BLUE: return i.color0.b;
        case MASK_TYPE_VERTEX_COLOR_ALPHA: return i.color0.a;
    }
}

// UV Tile Discard..................................................................................

float DiscardUv(VertexInput v, int index)
{
    int2 uv = (int2) SelectUv(v, index);
    switch (uv.y)
    {
    case 0:
        switch (uv.x)
        {
            case 0: return _UvTileDiscardRow0.x;
            case 1: return _UvTileDiscardRow0.y;
            case 2: return _UvTileDiscardRow0.z;
            case 3: return _UvTileDiscardRow0.w;
            default: return 0.0;
        }
    case 1:
        switch (uv.x)
        {
            case 0: return _UvTileDiscardRow1.x;
            case 1: return _UvTileDiscardRow1.y;
            case 2: return _UvTileDiscardRow1.z;
            case 3: return _UvTileDiscardRow1.w;
            default: return 0.0;
        }
    case 2:
        switch (uv.x)
        {
            case 0: return _UvTileDiscardRow2.x;
            case 1: return _UvTileDiscardRow2.y;
            case 2: return _UvTileDiscardRow2.z;
            case 3: return _UvTileDiscardRow2.w;
            default: return 0.0;
        }
    case 3:
        switch (uv.x)
        {
            case 0: return _UvTileDiscardRow3.x;
            case 1: return _UvTileDiscardRow3.y;
            case 2: return _UvTileDiscardRow3.z;
            case 3: return _UvTileDiscardRow3.w;
            default: return 0.0;
        }
    default: return 0.0;
    }
}

// Dithering........................................................................................

// This is PS1 style dithering.
// Copyright 2019 Jazz Mickle licensed under MIT.
// https://github.com/jmickle66666666/PSX-Dither-Shader

float ChannelError(float col, float colMin, float colMax)
{
    return abs(col - colMin) / abs(colMin - colMax);
}

float DitheredChannel(float error, float2 ditherBlockUV, float ditherSteps)
{
    float errorStep = floor(error * ditherSteps) / ditherSteps;
    float2 ditherUV = float2(errorStep, 0);
    ditherUV.x += ditherBlockUV.x;
    ditherUV.y = ditherBlockUV.y;
    return UNITY_SAMPLE_TEX2D(_DitherPattern, ditherUV).x;
}

float4 RgbToYuv(float4 rgba)
{
    float4 yuva;
    yuva.r = rgba.r * 0.2126 + 0.7152 * rgba.g + 0.0722 * rgba.b;
    yuva.g = (rgba.b - yuva.r) / 1.8556;
    yuva.b = (rgba.r - yuva.r) / 1.5748;
    yuva.a = rgba.a;
                
    // Adjust to work on GPU
    yuva.gb += 0.5;
                
    return yuva;
}

float4 YuvToRgb(float4 yuva)
{
    yuva.gb -= 0.5;
    return float4(
        yuva.r * 1 + yuva.g * 0 + yuva.b * 1.5748,
        yuva.r * 1 + yuva.g * -0.187324 + yuva.b * -0.468124,
        yuva.r * 1 + yuva.g * 1.8556 + yuva.b * 0,
        yuva.a);
}

float4 Dither(float4 color, float2 ditherUv, float2 ditherUvScale)
{
    fixed4 yuv = RgbToYuv(color);

    // Clamp the YUV color to specified color depth (default: 32, 5 bits per channel, as per playstation hardware)
    float4 col1 = floor(yuv * _DitherColorDepth) / _DitherColorDepth;
    float4 col2 = ceil(yuv * _DitherColorDepth) / _DitherColorDepth;

    // Calculate dither texture UV based on the input texture
    float ditherSize = _DitherPattern_TexelSize.w;
    float ditherSteps = _DitherPattern_TexelSize.z/ditherSize;

    float2 ditherBlockUV = ditherUv;
    ditherBlockUV.x %= (ditherSize / ditherUvScale.x);
    ditherBlockUV.x /= (ditherSize / ditherUvScale.x);
    ditherBlockUV.y %= (ditherSize / ditherUvScale.y);
    ditherBlockUV.y /= (ditherSize / ditherUvScale.y);
    ditherBlockUV.x /= ditherSteps;

    // Dither each channel individually
    yuv.x = lerp(col1.x, col2.x, DitheredChannel(ChannelError(yuv.x, col1.x, col2.x), ditherBlockUV, ditherSteps));
    yuv.y = lerp(col1.y, col2.y, DitheredChannel(ChannelError(yuv.y, col1.y, col2.y), ditherBlockUV, ditherSteps));
    yuv.z = lerp(col1.z, col2.z, DitheredChannel(ChannelError(yuv.z, col1.z, col2.z), ditherBlockUV, ditherSteps));

    return YuvToRgb(yuv);
}

float4 DitherWithUv(FragmentInput i, float4 color)
{
    switch (_DitherUvSet)
    {
        default:
        case 0:
            return Dither(color, 10.0 * i.uv0.xy / _DitherScale, _MainTex_TexelSize.zw);
        case 4:
            return Dither(color, i.screenUv.xy / i.positionCs.w / _DitherScale, _ScreenParams.xy);
    }
}

// Programs.........................................................................................

FragmentInput VertexProgram(VertexInput v)
{
    FragmentInput i;
    UNITY_INITIALIZE_OUTPUT(FragmentInput, i);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(i);
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, i);

    float3 positionWs = mul(unity_ObjectToWorld, v.vertex).xyz;
    float3 normalWs = UnityObjectToWorldNormal(v.normal);
    float3 viewDirectionWs = positionWs.xyz - _WorldSpaceCameraPos;

    // float3 tangentWs = UnityObjectToWorldDir(v.tangent.xyz);
    // float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWs.xyz, tangentWs, v.tangent.w);

    float3 lightDirectionWs;
    float attenuation;

#if defined(UNITY_PASS_FORWARDBASE) && defined(FIXED_LIGHT_ON)
    i.ambientColor.rgb = _FixedAmbientColor.rgb;
    float3 lightColor = _FixedLightColor.rgb;
    lightDirectionWs = -normalize(mul((float3x3) UNITY_MATRIX_I_V, _FixedLightDirection));
    attenuation = 1.0; // no attenuation
#else
    #ifdef UNITY_PASS_FORWARDBASE
        #ifdef LIGHTMAP_ON
            i.lightmapTexcoord.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
            i.lightmapTexcoord.zw = 0;
            #if _VRCLV_MODE_VERTEX
                float3 l0;
                float3 l1r;
                float3 l1g;
                float3 l1b;
                LightVolumeAdditiveSH(positionWs, l0, l1r, l1g, l1b);
                i.ambientColor.rgb = LightVolumeEvaluate(normalWs, l0, l1r, l1g, l1b);
            #endif
        #elif UNITY_SHOULD_SAMPLE_SH
            half3 ambientColor = 0;
            #ifdef VERTEXLIGHT_ON
                // Approximated illumination from non-important point lights
                ambientColor.rgb = Shade4PointLights(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    unity_4LightAtten0, positionWs, normalWs);
            #endif
            #if _VRCLV_MODE_VERTEX
                float3 l0;
                float3 l1r;
                float3 l1g;
                float3 l1b;
                LightVolumeSH(positionWs, l0, l1r, l1g, l1b);
                i.ambientColor.rgb = LightVolumeEvaluate(normalWs, l0, l1r, l1g, l1b);
            #else
            i.ambientColor.rgb = ShadeSHPerVertex(normalWs, ambientColor);
            #endif
            #ifdef USE_GAMMA_SPACE
                i.ambientColor.rgb = LinearToGammaSpace(i.ambientColor.rgb);
            #endif
        #endif
    #endif
    
    float3 lightColor = _LightColor0.rgb;
    float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - _WorldSpaceLightPos0.w * positionWs;
    lightDirectionWs = normalize(vertexToLightSource);
    
    #ifdef USING_DIRECTIONAL_LIGHT
        attenuation = 1.0; // no attenuation
    #else
        attenuation = 1.0 / length(vertexToLightSource); // linear attenuation
    #endif
#endif

    #ifdef USE_GAMMA_SPACE
    lightColor = LinearToGammaSpace(lightColor);
    #endif

    half lightIntensity = max(0.0, dot(normalWs, lightDirectionWs));
    // TODO: Add Shadow Ramp to the brightness here?
    half3 brightness = min(1, lightIntensity + _ShadowBoost);

    float3 specularReflection;
    if (dot(normalWs, lightDirectionWs) < 0.0)
    {
        // light source on the wrong side?
        specularReflection = float3(0.0, 0.0, 0.0);
    }
    else
    {
        // light source on the right side
        specularReflection = attenuation * lightColor * _SpecColor.rgb * pow(max(0.0, dot(reflect(lightDirectionWs, normalWs), normalize(viewDirectionWs))), _Shininess);
    }

    OSP_COMPUTE_LIGHT_COORDS(i, float4(positionWs, 1));
    
    #if POLYGON_JITTER_ON && defined(USING_STEREO_MATRICES)
    i.positionCs = UnityWorldToClipPos(float4(RoundVertex(positionWs, _PolygonJitter), 1));
    #else
    i.positionCs = UnityObjectToClipPos(float4(v.vertex.xyz, 1));
    #endif
    
    i.directDiffuse = brightness;
    i.directLightColor = lightColor * OSP_LIGHT_ATTENUATION(i);
    i.specularReflection = float4(specularReflection, 1.0);
    i.uv0.xy = TRANSFORM_TEX(v.uv0, _MainTex);
    i.uv0.zw = TRANSFORM_TEX(SelectUv(v, _DetailUvSet), _DetailMap);
    i.color0 = v.color0;

    #ifdef UV_TILE_DISCARD_ON
    if (DiscardUv(v, _TileDiscardUvSet) > 0.0)
    {
        i.positionCs = asfloat(-1);
        return i;
    }
    #endif

    #if POLYGON_JITTER_ON && !defined(USING_STEREO_MATRICES)
    i.positionCs = JitterVertex(i.positionCs, _PolygonJitter);
    #endif
    
    #if AFFINE_MAPPING_ON && !defined(USING_STEREO_MATRICES)
    // True affine mapping distorts to an extreme when the camera
    // gets close. PS1 games tessellate polygons that are close to
    // the camera, to compensate. But this tesselation is tough to
    // simulate. So instead use adjustable affine distortion that
    // reduces when close.
    //
    // Also uncomfortable in VR, so disable it!
    float distance = length(i.positionCs);
    float counterCorrection = distance + (i.positionCs.w * _AffineDistortion) / distance / 2.0;
    counterCorrection = lerp(1, counterCorrection, 0.125 * _AffineDistortion);
    i.uv0 *= counterCorrection;
    i.screenUv.z = counterCorrection;
    #endif

    #if DITHER_ON
    i.screenUv.xy = ComputeGrabScreenPos(i.positionCs).xy;
    #endif

    UNITY_TRANSFER_FOG(i, i.positionCs);
    
    return i;
}

fixed4 FragmentProgram(FragmentInput i): SV_Target
{
    #if AFFINE_MAPPING_ON && !defined(USING_STEREO_MATRICES)
    i.uv0 /= i.screenUv.z;
    #endif

    float4 adjustedUv0 = i.uv0;
    
    #ifdef PIXEL_SHARPEN_ON
    adjustedUv0.xy = SharpenPixelUv(adjustedUv0.xy, _MainTex_TexelSize);
        #ifdef DETAIL_MAP_ON
        adjustedUv0.zw = SharpenPixelUv(adjustedUv0.zw, _DetailMap_TexelSize);
        #endif
    #endif
    
    fixed4 baseColor = _Color * UNITY_SAMPLE_TEX2D(_MainTex, adjustedUv0.xy);
    #ifdef USE_GAMMA_SPACE
    baseColor.rgb = LinearToGammaSpace(baseColor.rgb);
    #endif

    #ifdef DETAIL_MAP_ON
    fixed4 detailColor = _DetailMapTint * UNITY_SAMPLE_TEX2D(_DetailMap, adjustedUv0.zw);
    float detailMask = GetDetailMask(i, _DetailMaskType, adjustedUv0);
        #ifdef USE_GAMMA_SPACE
        detailColor.rgb = LinearToGammaSpace(detailColor.rgb);
        #endif
    baseColor = lerp(baseColor, BlendColor(detailColor, baseColor, _DetailMapBlendMode), _DetailMapBlend * detailMask);
    #endif

    #if DITHER_ON
    baseColor = DitherWithUv(i, baseColor);
    #endif

    #ifdef ALPHA_TEST_ON
    clip(baseColor.a - _Cutoff);
    #endif
    
    fixed3 albedo = baseColor.rgb;
    albedo = BlendVertexColor(i.color0.rgb, albedo, _VertexColorBlendMode);
    
    half3 diffuseLight = i.directLightColor * lerp(albedo.rgb * _ShadowAlbedo, 1, i.directDiffuse);
    #if UNITY_PASS_FORWARDBASE
        #if defined(LIGHTMAP_ON)
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapTexcoord.xy);
        diffuseLight += DecodeLightmap(bakedColorTex);
            #if _VRCLV_MODE_VERTEX
            diffuseLight += i.ambientColor.rgb;
            #endif
        #elif UNITY_SHOULD_SAMPLE_SH
        diffuseLight += i.ambientColor.rgb;
        #endif
    diffuseLight = max(_FinalLightingMultiplier * diffuseLight, _FinalLightingMinBrightness);
    #endif
    
    diffuseLight = lerp(1, diffuseLight, _LightingBlend);

    fixed4 color = fixed4(albedo * diffuseLight + _LightingBlend * i.specularReflection, baseColor.a);

    #ifdef USE_GAMMA_SPACE
    color.rgb = GammaToLinearSpace(color.rgb);
    #endif

    UNITY_APPLY_FOG(i.fogCoord, color);

    return color;
}

#endif // VERTEX_LIT_CGINC_
