shader_type spatial;

instance uniform vec4 color : source_color = vec4(1.0);
uniform float flow_speed = 10.0;
uniform float calm_factor = 15.0;

void vertex() {
	
	//VERTEX.x += smoothstep(-0.4, 0.4, sin(VERTEX.y + TIME) - 1.0) / aggressiveness;
	VERTEX.x += sin(VERTEX.y + TIME * flow_speed) / calm_factor;
	//VERTEX.x -= smoothstep(0.2,0.7,sin(VERTEX.x+TIME)); //sin(VERTEX.x);
	//VERTEX.z += sin(TIME * flow_speed) / calm_factor;
}

void fragment() {
	ALBEDO = color.rgb;
}
