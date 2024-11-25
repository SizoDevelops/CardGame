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
var selectable = true
var touchable = true
var front
var  speed = .5
signal active_card(node)
signal card_selected(node)
signal add_to_stack(node)
signal remove_from_stack(node)


func set_selectable(val):
	selectable = val




func _ready():
	if not is_connected("input_event", Callable(self, "_on_input_event")):
		connect("input_event", Callable(self, "_on_input_event"))	

func move_card(dest, _rotate = null, _scale = null):
		var tween = get_tree().create_tween()
		tween.tween_property(self, "position", dest, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _scale != null:
			#tween.tween_property(self, "scale", scale, _scale, 0.5, Tween.TRANS_BACK, Tween.EASE_OUT)
			tween.tween_property(self, "scale", _scale, 0.2 ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if _rotate != null:
			tween.tween_property(self, "rotation", _rotate, 0.1 ).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			
		

		


func change_sprite(res):
	$Sprite2D.texture = load(res)
	
func change_cardscale(_scale):
	scale = _scale

func card_width():
	var cardwidth = $Sprite2D.texture.get_width() * scale.x
	return cardwidth

func kill_card():
	queue_free()




func stack_on_card():
	stacked = true
	# Adjust position to stack on top of the other card
	global_position = self.global_position
	z_index = self.z_index + 1

func set_on_table(value):
	on_table = value


func make_focus(player):
	if selectable:
		var position_shift = position
		position_shift.y -= focus_move_on_y
		if position == handposition and player == "player":
			move_card(position_shift, 0.0)

		selected_card = true
		emit_signal("active_card", self)
		emit_signal("add_to_stack", self)


func off_focus():
	if selectable:
		
		move_card(handposition, handrotation)
		emit_signal("remove_from_stack", self)
		selected_card = false
		
		

func make_active(card):
	if card != self:
		off_focus()
	else:
		card.change_sprite(card.front)
		
func table_card(card):
	if card == self:
		emit_signal("add_to_stack", self)
	
	
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton || event is InputEventScreenTouch:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed || event.is_pressed():			
			select_card("player")



func select_card(player):
	if touchable:
		if selected_card:
			
			off_focus()
			emit_signal("remove_from_stack", self)
			selected_card = false
				
		elif !selected_card:
			
			selected_card = true
			make_focus(player)

#
#func _on_input_event(viewport, event, shape_idx):
	#if event is InputEventMouseButton:
	#
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#z_index = 1
		#
			#var position_shift = position
			#position_shift.y -= focus_move_on_y
			#if position == handposition:
				#move_card(position_shift, 0.0)
			#
			#selected_card = true
			#emit_signal("card_selected", self)
			#
		#else:
			#z_index = 0
			#move_card(handposition, handrotation)
			#selected_card = false
#

