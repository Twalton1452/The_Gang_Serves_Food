extends Control

@onready var money_label = $Container/Label

var MONEY_FORMAT = "$%1.2f"

func _ready():
	GameState.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)

func _on_money_changed(amount: float):
	money_label.text = MONEY_FORMAT % amount
