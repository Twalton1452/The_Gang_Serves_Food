extends GutTest

var PlayerScene = load("res://Scenes/player.tscn")

func before_each():
	GameState.players = {}
	GameState.hud = double(HUD, DOUBLE_STRATEGY.SCRIPT_ONLY).new()

func after_each():
	GameState.players = {}

func test_cant_switch_to_open_for_business_when_restaurant_not_operable():
	# Setup
	GameState.state = GameState.Phase.EDITING_RESTAURANT
	var restaurant = Restaurant.new()
	restaurant.tables_root = Node3D.new()
	restaurant.add_child(restaurant.tables_root)
	restaurant.menu = double(Menu, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	restaurant.add_child(restaurant.menu)
	add_child_autoqfree(restaurant)
	
	# Invalidate the Restaurant
	restaurant.tables = [] as Array[Table]
	
	# Try to switch states and make sure it doesn't
	GameState.state = GameState.Phase.OPEN_FOR_BUSINESS
	assert_eq(GameState.state, GameState.Phase.EDITING_RESTAURANT)

func test_cant_switch_to_open_for_business_when_player_holding_item():
	# Setup
#	var params = [true, false]
	GameState.state = GameState.Phase.EDITING_RESTAURANT
	var player = partial_double(PlayerScene, DOUBLE_STRATEGY.SCRIPT_ONLY).instantiate()
	add_child_autoqfree(player)
	var holdable = double(Holdable, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	
	player.name = "Player"
	GameState.add_player(player)
	
	# Player in invalid state
	player.holder.add_child(holdable)
	
	# Try to switch states and make sure it doesn't
	GameState.state = GameState.Phase.OPEN_FOR_BUSINESS
	assert_eq(GameState.state, GameState.Phase.EDITING_RESTAURANT)

func test_cant_switch_to_open_for_business_when_player_editing_item():
	GameState.state = GameState.Phase.EDITING_RESTAURANT
	var player = partial_double(PlayerScene, DOUBLE_STRATEGY.SCRIPT_ONLY).instantiate()
	add_child_autoqfree(player)
	var holdable = double(Holdable, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	add_child_autoqfree(holdable)
#	player.holder.add_child(holdable)
	player.name = "Player"
	GameState.add_player(player)
	
	# Player in invalid state
	player.edit_mode_ray_cast.remote_transform.remote_path = holdable.get_path()
	# Try to switch states and make sure it doesn't
	GameState.state = GameState.Phase.OPEN_FOR_BUSINESS
	assert_eq(GameState.state, GameState.Phase.EDITING_RESTAURANT)
