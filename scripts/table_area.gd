
extends Area2D



var area_id = ""
@onready var position_node = $Area
@onready var h_slider = $HSlider
@onready var label = $Label



signal  id_set(id, node, slider)
var stack_size = 0

func _ready():
	h_slider.connect("value_changed", Callable(self, "_on_HSlider_value_changed"))
	label.text = str(h_slider.min_value)


func _on_HSlider_value_changed(value):
	# Update the label with the current value of the slider
	label.text = str(value)
	stack_size = value

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_player_area()
			

func select_player_area():
	emit_signal("id_set", area_id, position_node, h_slider)
