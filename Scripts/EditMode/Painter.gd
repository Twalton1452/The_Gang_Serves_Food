class_name Painter

static func paint(mesh_instance: MeshInstance3D, material_index: int, color: Color) -> void:
	mesh_instance.get_active_material(material_index).albedo_color = color
