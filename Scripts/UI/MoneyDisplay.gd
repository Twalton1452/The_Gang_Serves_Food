extends Control

@onready var money_label = $Container/Label

func _ready():
	GameState.money_changed.connect(_on_money_changed)

func _on_money_changed(amount: float):
	money_label.text = str(amount)
