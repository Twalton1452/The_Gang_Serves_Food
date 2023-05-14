# The_Gang_Serves_Food
 Coop Networked Multiplayer game where people try to make and serve food to customers

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
