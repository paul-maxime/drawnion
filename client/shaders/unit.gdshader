shader_type canvas_item;

uniform vec4 line_color: source_color = vec4(1.0);
uniform vec3 inside_color: source_color = vec3(0.0, 1.0, 0.9);
uniform float width: hint_range(0,10)  = 0.4;

const vec2 OFFSETS[8] = {
	vec2(-2,-2), vec2(-2,0), vec2(-2,1), vec2(0,-2),
	vec2(0,1), vec2(1,-2), vec2(1,0), vec2(1,1)
};

uniform float timeScaleFactor = .04;

// Make sure to use a seamless noise texture
uniform sampler2D noise_texture: repeat_enable, filter_linear;
uniform bool intense = false;

float localTime() {
	return TIME * timeScaleFactor;
}

mat2 makem2(float theta) {
	float c = cos(theta);
	float s = sin(theta);
	return mat2(vec2(c, -s), vec2(s, c));
}

float noise(vec2 x) {
	return texture(noise_texture, x * .01).x;
}

vec2 gradn(vec2 p) {
	float ep = .09;
	float gradx = noise(vec2(p.x, p.y)) - noise(vec2(p.x, p.y));
	float grady = noise(vec2(p.x, p.y + ep)) - noise(vec2(p.x, p.y - ep));
	return vec2(gradx, grady);
}

float flow(vec2 p) {
	float z = 2.;
	float rz = 0.;
	vec2 bp = p;
	
	for(float i = 1.; i < 7.; ++i) {
		p += localTime() * .6;
		bp += localTime() * 1.9;
		vec2 gr = gradn(i * p * .34 + localTime() * 1.);
		gr *= makem2(localTime() * 6. - (.05 * p.x + 0.03 * p.y) * 40.);
		p += gr * .5;
		rz += (sin(noise(p) * 7.) *.5 + .5) / z;
		p = mix(bp, p, .77);
		z *= 1.4;
		p *= 2.;
		bp *= 1.9;
	}
	return rz;
}

void vertex(){
	// start with adding margin to the original sprite
	// this will scale up the sprite, will scale down later in fragment()
	VERTEX += (UV * 2.0 - 1.0) * width ;
}

void fragment(){
	// note that TEXTURE_PIXEL_SIZE is actually 1.0/vec2(WIDTH_OF_TEXTURE, HEIGHT_OF_TEXTURE)
	// so 1.0 / TEXTURE_PIXEL_SIZE is vec2(WIDTH, HEIGHT)
	vec2 real_texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// This is texture size when add margin equal to 
	// width of the outline*2 (left and right / top and down)
	vec2 added_margin_texture_pixel_size = 1.0 / (real_texture_size + (width*4.0));
	
	// width in range (0,1), respected to the new texture size
	vec2 width_size = added_margin_texture_pixel_size * width;
	// shift the original uv bottom-right for 'width' unit 
	// Calculate how much bigger is the new size compared to the old one
	vec2 shifted_uv = UV - width_size;
	// Then scale the uv down to that ratio
	vec2 ratio = TEXTURE_PIXEL_SIZE / added_margin_texture_pixel_size;
	vec2 scaled_shifted_uv = shifted_uv * ratio;
	
	// sample the original texture with new uv to scale it down
	// to the original size
	vec4 inputColor;
	inputColor = texture(TEXTURE, scaled_shifted_uv);

	vec2 resolution = 0.1 / SCREEN_PIXEL_SIZE;
	vec2 fragCoord = FRAGCOORD.xy;
	fragCoord = vec2(fragCoord.x, resolution.y - fragCoord.y);
	vec2 p = fragCoord / resolution - 0.5;
	
	p.x *= resolution.x / resolution.y;
	p *= 3.;
	
	float rz = flow(p);
	vec3 col = vec3(line_color.r, line_color.g, line_color.b) / rz;
	if (intense) {
		col = pow(col, vec3(1.4));
	}

	// This if is to remove artifacts outside the boundary of sprites
	if (scaled_shifted_uv != clamp(scaled_shifted_uv, vec2(0.0), vec2(1.0))) {
		inputColor.a = 0.0;
	}
	
	if (inputColor.a != 0.0)  {
		inputColor = vec4(inside_color, 1.0);
	}
	
	float outline = 0.0;
	for (int i=0; i<OFFSETS.length(); i++){
		outline += texture(TEXTURE, scaled_shifted_uv + OFFSETS[i]*width_size).a;
	}
	outline = min(outline, 1.0);
	vec4 border = vec4(col, line_color.a);
	COLOR = mix(inputColor, border, outline - inputColor.a);
}