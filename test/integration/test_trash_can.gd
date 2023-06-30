extends TestingUtils

var TrashCanScene = load("res://Scenes/holders/simple_trash_can.tscn")
var PlayerScene = load("res://Scenes/player.tscn")
var FoodScene = load("res://Scenes/foods/patty.tscn")
var DrinkScene = load("res://Scenes/cup.tscn")

var _trash_can : TrashCan = null
var _player : Player = null

func before_each() -> void:
	_trash_can = TrashCanScene.instantiate()
	_player = PlayerScene.instantiate()
	add_child_autoqfree(_trash_can)
	add_child_autoqfree(_player)

func test_player_can_throw_away_food() -> void:
	var food = FoodScene.instantiate()
	_player.holder.hold_item(food)
	
	assert_eq(_player.holder.is_holding_item(), true)
	_trash_can.interact(_player)
	await wait_frames(1)
	assert_eq(_player.holder.is_holding_item(), false)
	assert_null(food)

func test_player_can_empty_drink() -> void:
	var drink : Drink = DrinkScene.instantiate()
	drink.fill_amount = 1.0
	_player.holder.hold_item(drink)
	
	assert_eq(_player.holder.is_holding_item(), true)
	_trash_can.interact(_player)
	await wait_frames(1)
	assert_eq(_player.holder.is_holding_item(), true)
	assert_eq(_player.holder.get_held_item().fill_amount, 0.0)
	assert_not_null(drink)

func test_player_can_throw_away_combined_food() -> void:
	var combined_food = create_combined_food([NetworkedIds.Scene.PATTY, NetworkedIds.Scene.ONION])
	_player.holder.hold_item(combined_food)
	
	assert_eq(_player.holder.is_holding_item(), true)
	_trash_can.interact(_player)
	await wait_frames(1)
	assert_eq(_player.holder.is_holding_item(), false)
	assert_null(combined_food)

func test_player_can_throw_away_food_and_drink_on_plate() -> void:
	var multiholder = create_multiholder(3)
	_player.holder.hold_item(multiholder)
	
	var combined_food = create_combined_food([NetworkedIds.Scene.PATTY, NetworkedIds.Scene.ONION])
	var food = FoodScene.instantiate()
	var drink : Drink = DrinkScene.instantiate()
	multiholder.hold_item(combined_food)
	multiholder.hold_item(food)
	multiholder.hold_item(drink)
	drink.fill_amount = 1.0
	
	assert_eq(_player.holder.is_holding_item(), true)
	assert_eq(multiholder.get_held_items().size(), 3)
	_trash_can.interact(_player)
	await wait_frames(1)
	assert_eq(_player.holder.is_holding_item(), true)
	assert_not_null(multiholder)
	assert_not_null(drink)
	assert_null(combined_food)
	assert_null(food)
	assert_eq(drink.fill_amount, 0.0)

