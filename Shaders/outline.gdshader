shader_type spatial;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_size = 0.05;

void fragment() {
    mat4 inv_camera_matrix = INV_VIEW_MATRIX;
    vec3 world_pos = (inv_camera_matrix * vec4(VERTEX, 1.0)).xyz;
    vec3 view_dir = normalize(world_pos - INV_VIEW_MATRIX[3].xyz);
    vec3 normal = normalize((inv_camera_matrix * vec4(NORMAL, 0.0)).xyz);
    float fresnel = max(0.0, 1.0 - dot(view_dir, normal));
    fresnel = 1.0 / pow(fresnel, 2.0);
    ALBEDO = mix(ALBEDO.rgb, outline_color.rgb, fresnel * outline_size);
}