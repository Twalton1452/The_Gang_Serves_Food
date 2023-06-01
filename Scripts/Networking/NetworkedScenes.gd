extends Node

## Autoloaded

## Class for mapping scenes to Ids to transfer over the network easily
var PATHS = {}

func _ready():
	PATHS = {
		NetworkedIds.Scene.PATTY: preload("res://Scenes/foods/patty.tscn"),
		NetworkedIds.Scene.BOTTOM_BUN: preload("res://Scenes/foods/bottom_bun.tscn"),
		NetworkedIds.Scene.TOP_BUN: preload("res://Scenes/foods/top_bun.tscn"),
		NetworkedIds.Scene.TOMATO: preload("res://Scenes/foods/tomato.tscn"),

		NetworkedIds.Scene.PLATE: preload("res://Scenes/holders/plate_components.tscn"),

		NetworkedIds.Scene.FOOD_COMBINER: preload("res://Scenes/components/food_combiner.tscn"),

		NetworkedIds.Scene.CUSTOMER: preload("res://Scenes/customer.tscn"),
		NetworkedIds.Scene.CUSTOMER_PARTY: preload("res://Scenes/components/party.tscn"),
	}
	print(PATHS[NetworkedIds.Scene.PATTY].resource_path.get_basename())
