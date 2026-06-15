extends Panel

signal hero_clicked

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		hero_clicked.emit()
