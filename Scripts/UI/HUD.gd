extends Control
class_name HUD

@onready var notification_label = $NotificationLabel

func display_notification(text: String) -> void:
	notification_label.text = text
	notification_label.show()

func hide_notification() -> void:
	notification_label.hide()
