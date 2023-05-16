# The_Gang_Serves_Food
 Coop Networked Multiplayer game where people try to make and serve food to customers

![Stylized Image of a KitchenStove from a 45 degree angle](./kitchenStove_SE.png)

## Issues to check in on sometimes
- Watched Properties being added to Synchronizer: https://github.com/godotengine/godot/pull/75467
	- Could tell a Synchronizer to only send updates to clients if the property changed
- Getting spammed with this Error when bringing Patties into the scene:
	- "servers/rendering/renderer_rd/storage_rd/material_storage.cpp:2849 - Condition "!material" is true."
	- Seems to be caused by setting the material Local to Scene
	- https://github.com/godotengine/godot/issues/67144
	- https://github.com/godotengine/godot/issues/59912#issuecomment-1128091714

## Useful keybinds not to forget
- Multi-row editing: Ctrl + Shift + Up/Down Arrow

# Structure
## Networking
- Authority
	- Players currently have authority over themselves
		- [ ] `MultiplayerSynchronizer` syncs only Input from the Player
	- Everything else the server has authority
- `MultiplayerSpawner` uses
	- Spawns Levels
	- Spawns Players
- `MultiplayerSynchronizer` uses
	- Player to sync their position/rotations

### NetworkedNode3D.gd
Used for sync'ing state between players when a Player joins midsession. Any reference to `sync_state` is because of this Node.
We can sync initial state by using a `PackedByteArray` and shoving any type of information in there, the onus is on the receiver to decode it in the correct format.
- Use
	- Set the `Scene Id` in the editor to the Scene mapping from `SceneIds.gd`. \
		If your Scene doesn't exist in there then when a Player joins midsession and that object hasn't generated for them yet, it will look to that file path to create it
	- Inherit this component and in `_ready` call `super` to setup the Networking
		- Gives this Node a `net_id` and adds it to a `SceneIds.SCENES.NETWORKED` group
	- Override set_sync_state and get_sync_state in the child component
		- Call `super()` to get where you left off in get_sync_state or set_sync_state
		- These are writing bytes to the Array so you need to know the sizes of the things you are writing which can be found [here](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html)

## Components

### InteractableComponent.gd
Core Component, allows easy communication through signals between other components
- Use:
	- Add this from `res://Scenes/Components/InteractableComponent.tscn` to a scene and a `CollisionShape3D` to trigger Interactable events

### HolderComponent.gd
- `extends NetworkedNode3D`
Reparents Nodes when interacted with through the InteractableComponent "interacted" signal and "secondary_interacted" signal
- Use 1 of 2 ways: 
	 1. Add this Scene `res://Scenes/Components/HolderComponent.tscn` and an `InteractableComponent.tscn` as a child
	 2. Add this Scene `res://Scenes/Components/HolderComponent.tscn` and an `InteractableComponent.tscn` on the same level beneath a parent

### IngredientComponent.gd
- `extends HolderComponent
Used for holding a bunch of "stuff", like Holdables or Holders
- Use:
	- Add this Scene `res://Scenes/Components/IngredientComponent.tscn` as a child of the Top Level Node in the Scene
	- Add an `InteractableComponent.tscn` as a sibling and setup the `CollisionShape3D` as a child
	- The `IngredientComponent` will accept anything it's given unless you set the `IngredientScene` in the editor
- Ex:
	- Burger Patty box where you can pull Patty's on and off the stack
	- Plate Stack where you can pull plates on and off the stack

### MultiHolderComponent.gd
- `extends HolderComponent`
Used for things that can have multiple `HolderComponent`'s inside a single Scene
When `hold_item(item)` is called on this it will delegate that to its child Holder's
- Use:
	- Assign this script to the Top Level Node of the Scene
	- Add this Scene `res://Scenes/Components/HolderComponent.tscn` as a child
	- Add an InteractableComponent Scene `res://Scenes/Components/InteractableComponent.tscn` as a child of the newly created Holder child and setup the `CollisionShape3D` as a child of the InteractableComponent
- Ex:
	- Plates

### HoldableComponent.gd
- `extends NetworkedNode3D`
Dummy node that is mostly used to sync state without directly assigning `NetworkedNode3D` scripts to nodes.
Also helps distinguish when a child of a Holder is truly Holdable or some other Component
- Use:
	- Assign this script to the Top-Level Node of the Scene
