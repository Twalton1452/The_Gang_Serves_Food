extends Node

## Autoloaded

## Class for mapping Ids to Scenes to make transfer over the network easier

var PATHS = {}

## Lazy loads the scenes, should avoid cyclic dependencies when loading
func match_id_to_scene(id: NetworkedIds.Scene) -> Resource:
	match id:
		NetworkedIds.Scene.PATTY: return load("res://Scenes/foods/patty.tscn")
		NetworkedIds.Scene.BOTTOM_BUN: return load("res://Scenes/foods/bottom_bun.tscn")
		NetworkedIds.Scene.TOP_BUN: return load("res://Scenes/foods/top_bun.tscn")
		NetworkedIds.Scene.TOMATO: return load("res://Scenes/foods/tomato.tscn")
		NetworkedIds.Scene.ONION: return load("res://Scenes/foods/onion.tscn")

		NetworkedIds.Scene.PLATE: return load("res://Scenes/holders/plate_components.tscn")

		NetworkedIds.Scene.FOOD_COMBINER: return load("res://Scenes/components/food_combiner.tscn")
		NetworkedIds.Scene.ORDER: return load("res://Scenes/components/order.tscn")

		NetworkedIds.Scene.CUSTOMER: return load("res://Scenes/customer.tscn")
		NetworkedIds.Scene.CUSTOMER_PARTY: return load("res://Scenes/components/party.tscn")
	return null
	
func get_scene_by_id(id: NetworkedIds.Scene) -> Resource:
	if PATHS.has(id):
		return PATHS[id]
	var scene = match_id_to_scene(id)
	
	if scene == null:
		print_debug(id, " has not been added yet to NetworkedScenes.gd")
		return
	
	PATHS[id] = scene
	return scene
