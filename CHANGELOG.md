# Changelog

## v0.2.0

Released September 5, 2023.

- Adds Unlit Opaque, Unlit Transparent, and Unlit Transparent Cutout shaders. These are easier to use and have faster build time than Unlit Fancy.
- Adds flipbook support.
- Adds matcap support.
- Adds detail blending based on vertex color.
- Adds smoothing to billboards. This blends between frames for animations like water or smoke.
- Adds a "stay upright" option to billboards. This is like Wolfenstein or Doom sprites, which face the camera but do not tilt depending on camera height. One downside is that it makes billboards not as visible at- high angles. But an upside is that it's much more comfortable in VR.
- Adds scale support to billboards.
- Fixes billboards being invisible in mirrors.

## v0.1.0

Released August 30, 2023.

- Adds vertex lit, lightmapped, and billboard shaders.
