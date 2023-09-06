#ifndef OSP_MINIMAL_CGINC_
#define OSP_MINIMAL_CGINC_

#include "UnityCG.cginc"

// Blending.....................................................................

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

#define BLEND_BY_STRENGTH 0
#define BLEND_BY_VERTEX_COLOR_RED 1
#define BLEND_BY_VERTEX_COLOR_ALPHA 2

float GetBlendAmount(float strength, float4 vertexColor, float blendBy)
{
    switch (blendBy)
    {
    case BLEND_BY_STRENGTH: return strength;
    case BLEND_BY_VERTEX_COLOR_RED: return vertexColor.r;
    case BLEND_BY_VERTEX_COLOR_ALPHA: return vertexColor.a;
    default: return 0;
    }
}

// Matcap.......................................................................

float2 GetMatcapTexcoord(half3 viewDirection, half3 viewNormal)
{
    float3 r = reflect(viewDirection, viewNormal);
    float m = 2.0 * sqrt(pow(r.x, 2.0) + pow(r.y, 2.0) + pow(r.z + 1.0, 2.0));
    float2 uv = r.xy / m + 0.5;
    return uv;
}

// Flipbooks....................................................................

// The index in the z component of the result is non-integral so that the
// fractional part can be used for smoothing, if that's enabled.
float4 GetFlipbookTexcoord(Texture2DArray flipbook, float2 texcoord, float framesPerSecond, float useManualFrame, int manualFrame)
{
    float width, height;
    uint elementCount;
    flipbook.GetDimensions(width, height, elementCount);
    float frame = _Time.y * framesPerSecond / elementCount;
    uint index = frac(frame) * elementCount;
    index = lerp(index, useManualFrame, manualFrame);
    uint nextIndex = (index + 1) % elementCount;
    float4 flipbookTexcoord = float4(texcoord, index + frac(frame), nextIndex);
    return flipbookTexcoord;
}

// Lightmapping.................................................................

half4 SampleLightmap(float2 lightmapTexcoord)
{
    fixed4 lightmapSample = UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapTexcoord);
    half4 bakedColor = half4(DecodeLightmap(lightmapSample), 1.0);
    return bakedColor;
}

float4 DecodeBakeryVertexLightmap(float4 lightmap)
{
    // Decode baked HDR vertex color (RGBM)
    float4 color = lightmap;
    color.rgb *= lightmap.a * 8.0;
    color.rgb *= color.rgb;
    return color;
}

// Color Spaces.................................................................

half3 AdjustToShadingColorSpace(half3 col)
{
#if defined(UNITY_COLORSPACE_GAMMA) || !defined(USE_GAMMA_COLORSPACE)
    return col;
#else
    return GammaToLinearSpace(col);
#endif
}

half3 AdjustFromShadingColorSpace(half3 col)
{
#if defined(UNITY_COLORSPACE_GAMMA) || !defined(USE_GAMMA_COLORSPACE)
    return col;
#else
    return LinearToGammaSpace(col);
#endif
}

// Fog..........................................................................

#define USING_FOG (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))

// This transfers fog using radial distance so that it works in mirrors.
fixed TransferFog(float4 clipPosition)
{
    float3 viewPosition = UnityObjectToViewPos(clipPosition);
    float fogCoord = length(viewPosition.xyz);
    UNITY_CALC_FOG_FACTOR_RAW(fogCoord);
    return saturate(unityFogFactor);
}

#if USING_FOG
#define OSP_APPLY_FOG(col, input) col.rgb = lerp(unity_FogColor.rgb, col.rgb, input.fog);
#define OSP_FOG_COORDS(texcoordNumber) fixed fog : TEXCOORD##texcoordNumber;
#define OSP_TRANSFER_FOG(clipPosition, output) output.fog = TransferFog(clipPosition);
#else
#define OSP_APPLY_FOG(col, input)
#define OSP_FOG_COORDS(texcoordNumber)
#define OSP_TRANSFER_FOG(clipPosition, output)
#endif // USING_FOG

// Polygon Jitter...............................................................

// The vertex jitter on the PS1 and DS is due to the lack of subpixel
// rasterization. So, simulate this by snapping vertices to the nearest pixel.
// 
// However, because modern screens are much higher resolution, the jitter isn't
// as visible. So, the amount of jitter is adjustable to use a larger than 1-pixel
// grid, to exaggerate the effect.
float4 JitterVertex(float4 clipPosition, float jitter)
{
    float2 grid = (0.5 / jitter) * _ScreenParams.xy;
    float4 snapped = clipPosition;
    snapped.xyz = clipPosition.xyz / clipPosition.w;
    snapped.xy = floor(grid * snapped.xy) / grid;
    snapped.xyz *= snapped.w;
    return snapped;
}

#endif // OSP_MINIMAL_CGINC_
