extends GutTest

var WallScene = load("res://Scenes/walls/wall.tscn")
var PlayerScene = load("res://Scenes/player.tscn")

var _to_paint_mesh : MeshInstance3D = null

func before_each():
	_to_paint_mesh = MeshInstance3D.new()
	_to_paint_mesh.mesh = BoxMesh.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	_to_paint_mesh.mesh.surface_set_material(0, material)
	add_child_autoqfree(_to_paint_mesh)

func test_can_paint_wall():
	assert_eq(_to_paint_mesh.get_active_material(0).albedo_color, Color.WHITE)
	Painter.paint(_to_paint_mesh, 0, Color.RED)
	assert_eq(_to_paint_mesh.get_active_material(0).albedo_color, Color.RED)
