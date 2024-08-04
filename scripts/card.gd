extends Area2D

var cardname
var cardvalue
var cardsuit
var dealt = false

@export() var cardsprite: Texture
@export var focus_move_on_y = 40
var cardscale: set = change_cardscale
var handposition = Vector2.ZERO
var handrotation = Vector2.ZERO
var dragging = false
var on_table = false 
var stacked = false
var selected_card = false
var drag_offset = Vector2()
@export var table_size = Rect2(Vector2(0, 0), Vector2(300, 180))
@onready var PlayerHand = "res://scenes/hand.tscn"


# Store original properties
var original_z_index
var original_rotation
var original_scale

func move_card(dest, _rotate = null, _scale = null):
		var tween = get_tree().create_tween()
		
		tween.tween_property(self, "position", dest, 0.5 ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _rotate != null:
			#tween.tween_property(self, "rotation", rotation, rotate, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.tween_property(self, "rotation", _rotate, 0.2 ).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			
		if _scale != null:
			#tween.tween_property(self, "scale", scale, _scale, 0.5, Tween.TRANS_BACK, Tween.EASE_OUT)
			tween.tween_property(self, "scale", _scale, 0.5 ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		original_z_index = z_index
		original_rotation = rotation
		original_scale = scale	
		


func change_sprite(res):
	$Sprite2D.texture = load(res)
	
func change_cardscale(_scale):
	scale = _scale

func card_width():
	var cardwidth = $Sprite2D.texture.get_width() * scale.x + 0.065
	return cardwidth

func kill_card():
	queue_free()

	


func stack_on_card(card):
	stacked = true
	# Adjust position to stack on top of the other card
	global_position = card.global_position
	z_index = card.z_index + 1

func set_on_table(value):
	on_table = value


func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			
			var position_shift = position
			position_shift.y -= focus_move_on_y
			if position == handposition:
				move_card(position_shift, 0.0)
			z_index = 2
			selected_card = true
			emit_signal("active_card", self)
		else:
			move_card(handposition, handrotation)
			z_index = 0
			selected_card = false


