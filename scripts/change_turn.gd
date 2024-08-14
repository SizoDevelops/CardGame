extends Area2D

signal change_turn(current_turn)

@export var turn := 1


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if turn == 1:
				turn = 2
			else: 
				turn = 1
			emit_signal("change_turn", turn)
			print("Turn Changed  -  ", turn)
