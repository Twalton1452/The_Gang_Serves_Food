extends Control
class_name HUD

@onready var notification_label = $NotificationLabel

func display_notification(text: String, duration_seconds: float = -1.0) -> void:
	notification_label.text = text
	notification_label.show()
	if duration_seconds > 0:
		await get_tree().create_timer(duration_seconds, false).timeout
		hide_notification()

func hide_notification() -> void:
	notification_label.hide()
