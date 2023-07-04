extends Holdable

@onready var audio_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

func _secondary_interact(_player: Player) -> void:
	audio_player.play()
