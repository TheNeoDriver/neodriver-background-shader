// Fill the black borders caused by the diferents
// screen resolutions with a background image.
// Created by TheNeoDriver merging BigBlur and imgborder shaders.
// MIT License.

#pragma parameter aspect_x "Aspect Ratio Numerator" 64.0 1.0 256.0 1.0
#pragma parameter aspect_y "Aspect Ratio Denominator" 49.0 1.0 256.0 1.0
#pragma parameter integer_scale "Force Integer Scaling" 0.0 0.0 1.0 1.0
#pragma parameter overscale "Integer Overscale" 0.0 0.0 1.0 1.0
#pragma parameter BRIGHTNESS "Border Brightness Mod" 0.0 -1.0 1.0 0.05
#ifndef PARAMETER_UNIFORM
#define aspect_x 64.0
#define aspect_y 49.0
#define integer_scale 0.0
#define overscale 0.0
#define BRIGHTNESS 0.0
#endif

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_ATTRIBUTE vec4 LUTTexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float aspect_x;
uniform COMPAT_PRECISION float aspect_y;
uniform COMPAT_PRECISION float integer_scale;
uniform COMPAT_PRECISION float overscale;
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
	vec2 corrected_size = InputSize * vec2(aspect_x / aspect_y, 1.0)
		 * vec2(InputSize.y / InputSize.x, 1.0);

	float full_scale = (integer_scale > 0.5) ? floor(OutputSize.y /
		InputSize.y) + overscale : OutputSize.y / InputSize.y;

	vec2 scale = (OutputSize / corrected_size) / full_scale;
	vec2 middle = vec2(0.49999, 0.49999) * InputSize / TextureSize;
	vec2 diff = TexCoord.xy - middle;

    TEX0.xy = middle + diff * scale;
	TEX1.xy = LUTTexCoord.xy;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D Background;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 TEX1;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BRIGHTNESS;
#endif

vec4 border(sampler2D source, vec2 tex_coord, sampler2D background, vec2 border_coord)
{
	vec4 effect = COMPAT_TEXTURE(background, border_coord);
	effect += vec4(vec3(BRIGHTNESS), effect.w);

	vec4 frame = COMPAT_TEXTURE(source, tex_coord);

	vec2 frag_coord = (tex_coord.xy * (TextureSize.xy/InputSize.xy));
	if (frag_coord.x < 1.0 && frag_coord.x > 0.0 && frag_coord.y < 1.0 && frag_coord.y > 0.0)
		return frame;
	
	else return effect;
}

void main()
{
    FragColor = border(Texture, TEX0.xy, Background, TEX1.xy);
} 
#endif