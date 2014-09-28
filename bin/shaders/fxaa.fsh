#version 110

uniform sampler2D texture;
uniform vec2 inverseVP; // vec2(1.0 / width, 1.0 / height);

varying vec2 fragTexcoord;

#define FXAA_REDUCE_MIN (1.0/ 64.0)
#define FXAA_REDUCE_MUL (1.0 / 8.0)
#define FXAA_SPAN_MAX 8.0

vec4 applyFXAA(vec2 fragCoord, sampler2D tex)
{
	vec4 color = texture2D(tex, fragCoord);
	vec3 rgbNW = texture2D(tex, fragCoord + vec2(-1.0, -1.0) * inverseVP).xyz;
	vec3 rgbNE = texture2D(tex, fragCoord + vec2(1.0, -1.0) * inverseVP).xyz;
	vec3 rgbSW = texture2D(tex, fragCoord + vec2(-1.0, 1.0) * inverseVP).xyz;
	vec3 rgbSE = texture2D(tex, fragCoord + vec2(1.0, 1.0) * inverseVP).xyz;
	vec3 rgbM  = color.xyz;
	vec3 luma = vec3(0.299, 0.587, 0.114);
	float lumaNW = dot(rgbNW, luma);
	float lumaNE = dot(rgbNE, luma);
	float lumaSW = dot(rgbSW, luma);
	float lumaSE = dot(rgbSE, luma);
	float lumaM  = dot(rgbM,  luma);
	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
	
	vec2 dir;
	dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
	
	float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
						  (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
	
	float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
	dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
			  max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
			  dir * rcpDirMin)) * inverseVP;
	  
	vec3 rgbA = 0.5 * (
		texture2D(tex, fragCoord + dir * (1.0 / 3.0 - 0.5)).xyz +
		texture2D(tex, fragCoord + dir * (2.0 / 3.0 - 0.5)).xyz);
	vec3 rgbB = rgbA * 0.5 + 0.25 * (
		texture2D(tex, fragCoord + dir * -0.5).xyz +
		texture2D(tex, fragCoord + dir * 0.5).xyz);

	float lumaB = dot(rgbB, luma);
	if ((lumaB < lumaMin) || (lumaB > lumaMax))
		color = vec4(rgbA, color.a);
	else
		color = vec4(rgbB, color.a);
	return color;
}

void main()
{
	gl_FragColor = applyFXAA(fragTexcoord, texture);
}
