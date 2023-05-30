## Class for mapping scenes to Ids to transfer over the network easily
class_name SceneIds

enum SCENES {
	NETWORKED = 0,
	PATTY = 1,
	BOTTOM_BUN = 2,
	TOP_BUN = 3,
	TOMATO = 4,
	
	PLATE = 50,
	
#	HOLDER = 100,
#	HOLDABLE = 101,
#	COOKABLE = 102,
#	ROTATABLE = 103,
	FOOD_COMBINER = 1000,
	
	CUSTOMER = 2000,
	CUSTOMER_PARTY = 2001,
}

const PATHS = {
	SCENES.PATTY: "res://Scenes/foods/patty.tscn",
	SCENES.BOTTOM_BUN: "res://Scenes/foods/bottom_bun.tscn",
	SCENES.TOP_BUN: "res://Scenes/foods/top_bun.tscn",
	SCENES.TOMATO: "res://Scenes/foods/tomato.tscn",
	
	SCENES.PLATE: "res://Scenes/holders/plate_components.tscn",
	
	SCENES.FOOD_COMBINER: "res://Scenes/components/food_combiner.tscn",
	
	SCENES.CUSTOMER: "res://Scenes/customer.tscn",
	SCENES.CUSTOMER_PARTY: "res://Scenes/components/party.tscn",
}


static func get_scene_from_id(id: SCENES) -> PackedScene:
	return load(PATHS[id]) if PATHS.has(id) else null
