extends Node

## Autoloaded

## Class for mapping scenes to Ids to transfer over the network easily

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

var PATHS = {
	SCENES.PATTY: preload("res://Scenes/foods/patty.tscn"),
	SCENES.BOTTOM_BUN: preload("res://Scenes/foods/bottom_bun.tscn"),
	SCENES.TOP_BUN: preload("res://Scenes/foods/top_bun.tscn"),
	SCENES.TOMATO: preload("res://Scenes/foods/tomato.tscn"),
	
	SCENES.PLATE: preload("res://Scenes/holders/plate_components.tscn"),
	
	SCENES.FOOD_COMBINER: preload("res://Scenes/components/food_combiner.tscn"),
	
	SCENES.CUSTOMER: preload("res://Scenes/customer.tscn"),
	SCENES.CUSTOMER_PARTY: preload("res://Scenes/components/party.tscn"),
}
