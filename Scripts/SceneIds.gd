## Class for mapping scenes to Ids to transfer over the network easily
## Also allows for easy groupings
## Ex: Each Patty is added to group str(SCENES.PATTY)
##     Retrieve all Patties with get_tree().get_nodes_in_group(str(SCENES.PATTY))
class_name SceneIds

enum SCENES {
	NETWORKED = 0,
	PATTY = 1,
	
	HOLDER = 100,
	HOLDABLE = 101,
	COOKABLE = 102,
}

const PATHS = {
	SCENES.PATTY: preload("res://Scenes/patty.tscn")
}
