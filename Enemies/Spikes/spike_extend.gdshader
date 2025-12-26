shader_type canvas_item;

uniform float extension : hint_range(0, 128) = 0.0; // How many pixels to extend

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    ivec2 tex_size = textureSize(TEXTURE, 0);
    float spike_height = float(tex_size.y);
    float y = UV.y * (spike_height + extension);

    if (y < spike_height) {
        // Normal spike
        COLOR = texture(TEXTURE, vec2(UV.x, y / spike_height));
    } else {
        // Extension: repeat bottom row
        float bottom_y = (spike_height - 1.0) / spike_height;
        COLOR = texture(TEXTURE, vec2(UV.x, bottom_y));
    }
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

