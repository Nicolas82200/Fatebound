extends Panel

signal hero_clicked

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			hero_clicked.emit()
