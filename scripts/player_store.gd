extends Area2D

@onready var stack = $Stack

var area_id = ""
signal  id_set(id, node)


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("id_set", area_id, $StorePosition)
