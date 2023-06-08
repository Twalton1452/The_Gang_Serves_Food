extends Node

## Autoloaded

## Class for mapping Ids to Resources to make transfer over the network easier

var PATHS = {}

## Lazy loads the resources, should avoid cyclic dependencies when loading
func match_id_to_resource(id: NetworkedIds.Resources) -> Resource:
	match id:
		NetworkedIds.Resources.WATER: return load("res://Resources/Beverages/Beverage_Water.tres")
		NetworkedIds.Resources.COLA: return load("res://Resources/Beverages/Beverage_Cola.tres")
		NetworkedIds.Resources.MYSTERY: return load("res://Resources/Beverages/Beverage_Mystery.tres")
		
	return null
	
func get_resource_by_id(id: NetworkedIds.Resources) -> Resource:
	if PATHS.has(id):
		return PATHS[id]
	var resource = match_id_to_resource(id)
	
	if resource == null:
		print_debug(id, " has not been added yet to NetworkedResources.gd")
		return
	
	PATHS[id] = resource
	return resource
