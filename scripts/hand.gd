extends Node2D

@onready var deck = $"../Deck"


var hand = []
var card_path = "res://PNG/"
var card_width
var table_card_pos = Vector2.ZERO
@export var card_scale = Vector2(0.6, 0.6)
var index = 0
var rng
var stack = []

func _ready():
	# Create an instance of the RandomNumberGenerator
	rng = RandomNumberGenerator.new()
	
	# Seed the generator with the system's entropy for more unpredictability
	rng.randomize()

func draw_cards(card):
	hand += deck.give_cards(card)
	initialize_cards()
	place_cards()

func initialize_cards():
	var firstpart
	var secondpart
	var fullpart
	for i in hand.size():
		hand[i].cardscale = card_scale

		fullpart = ""
		if hand[i].cardsuit == "S":
			firstpart = str(hand[i].cardvalue)
		elif hand[i].cardsuit == "D":
			firstpart = str(hand[i].cardvalue)
		elif hand[i].cardsuit == "C":
			firstpart = str(hand[i].cardvalue)
		elif hand[i].cardsuit == "H":
			firstpart = str(hand[i].cardvalue)
		if hand[i].cardsuit == "S" and hand[i].cardvalue == 1:
			firstpart = ""
			secondpart = "AS.png"
		elif hand[i].cardsuit == "D" and hand[i].cardvalue == 1:
			firstpart = ""
			secondpart = "AD.png"
		elif hand[i].cardsuit == "C" and hand[i].cardvalue == 1:
			firstpart = ""
			secondpart = "AC.png"
		elif hand[i].cardsuit == "H" and hand[i].cardvalue == 1:
			firstpart = ""
			secondpart = "AH.png"
		else:
			secondpart = str(hand[i].cardsuit) + ".png"
			
		fullpart = firstpart + secondpart
		
		hand[i].change_sprite(card_path+fullpart)
		if not hand[i].is_connected("active_card", Callable(self, "_active_card")):
			hand[i].connect("active_card", Callable(self, "_active_card"))
		if not hand[i].is_connected("card_selected", Callable(self, "_card_selected")):
			hand[i].connect("card_selected", Callable(self, "_card_selected"))
		if not hand[i].is_connected("add_to_stack", Callable(self, "_add_to_stack")):
			hand[i].connect("add_to_stack", Callable(self, "_add_to_stack"))
		if not hand[i].is_connected("remove_from_stack", Callable(self, "_remove_from_stack")):
			hand[i].connect("remove_from_stack", Callable(self, "_remove_from_stack"))

func place_cards():
	var path_length = $Path2D.curve.get_baked_length()
	var space
	var ideal_cardwidth
	var hand_width

	# Calculate ideal card width and hand width
	if hand.size() == 0:
		print("No cards in hand.")
		return
		
	card_width = hand[0].card_width()  # Assuming all cards have the same width
	ideal_cardwidth = card_width * 0.6
	hand_width = ideal_cardwidth * hand.size()

	# Ensure cards are not already added
	for card in hand:
		if card.get_parent() != self:
			add_child(card)

	# Calculate space and positioning
	space = path_length
	$Path2D/PathFollow2D.progress = 0.0
	
	if hand_width < path_length:
		$Path2D/PathFollow2D.progress = (space - hand_width) / 2
		print("Ideal card width space: " + str(ideal_cardwidth))
	else:
		ideal_cardwidth = space / hand.size()
		print("Ideal card width crowded: " + str(ideal_cardwidth))
	
	for i in range(hand.size()):
		var card = hand[i]
		if !card.dealt:
			card.position = $DeckLocation.position
		
		card.handposition = $Path2D/PathFollow2D/DeckSpawner.get_global_position()
		card.handrotation = $Path2D/PathFollow2D/DeckSpawner.get_global_transform().get_rotation()
		
		card.move_card(card.handposition, card.handrotation)
		
		card.dealt = true
		
		$Path2D/PathFollow2D.progress += ideal_cardwidth

	$Path2D/PathFollow2D.progress = 0.0

func reset_hand():
	for i in hand.size():
		hand[i].kill_card()
	hand = []


func remove_card(card):
	hand.erase(card)
	place_cards()
	
var table_holder = []
var selected_card = null
var selected = false

func _active_card(card):
	for i in hand.size():
		hand[i].make_active(card)
		
	for cards in table_holder:
		for c in cards["stack"]:
			c.table_card(card)
	selected_card = card

var total = 0

func _add_to_stack(card):
	if not stack.has(card):
		stack.append(card)
	var temp = 0
	for i in stack:
		temp += i.cardvalue
	total = temp
	print("total  = ", total)

func _remove_from_stack(card):
	stack.erase(card)
	var temp = 0
	for i in stack:
		temp += i.cardvalue
	total = temp
	print("total  = ", total)

func give_hand():
	return hand
	


func card_stack(card):
	if card in stack and stack.size() > 1:
		return true
	return false

func is_position_occupied(position):
	
	for cards in table_holder:
		if (cards.stack.size() > 0 and cards.stack[cards.stack.size() - 1].position.distance_to(position) < 50) :  # Assuming card_size is a function or constant
			return true
	return false



func generate_random_id(rng: RandomNumberGenerator):
	# Length of the ID
	var length = 16
	
	# Characters to use in the ID
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var id = ""
	
	for i in range(length):
		# Pick a random character from the chars string
		var char = chars[rng.randi_range(0, chars.length() - 1)]
		id += char
	
	return id

var area_ids = []

func full(elem):
	return elem.stack.size() > 0
	
	
	
var slider_shown = false
var slider_id = ""
func show_slider(slider, id):
	var has_card = false
	
	for card in table_holder:
		if card["id"] == id and card["stack"].size() > 0:
			has_card = true
	
	if !slider.visible and !selected_card and !has_card and table_holder.size() > 0 and !slider_shown and (slider_id != id || slider_id == ""):
		slider.visible = true
		slider_shown = true
		slider_id = id
		
	elif slider_id == id: 
		slider.visible = false
		slider_shown = false
		slider_id = ""
		
		
		
		
func _on_table_area_id_set(id, node, value, slider):
	
	
	table_card_pos = node.get_global_position()
	show_slider(slider, id)
	
	if slider.value == 0 || total != slider.value:
		for card in stack:
			card.off_focus()
		
	
	var card_found = false
	for table_stack in table_holder:
			if selected_card in table_stack["stack"]:
				card_found = true
	
				
	if selected_card and !is_position_occupied(table_card_pos) and selected_card.selected_card and !card_found and !has_stack(selected_card ):
		
		slider.value = selected_card.cardvalue
		add_card(selected_card, id, slider.value)

		

		print(table_holder)
		selected_card = null
	else:
		

		
		if (stack.size() > 1 and total == value) and !card_on_table():
			for card in stack:
				add_card(card, id, value)
				
		elif stack.size() > 1 and total == value and card_on_table()  and is_position_occupied(table_card_pos) and has_stack(selected_card):
			for card in stack:
				add_card(card, id, value)
				
		for card in table_holder:
			if card["stack"].size() > 1:
				for i in card["stack"]:
					i.touchable = false
		stack.clear()
		selected_card = null
		print(table_holder)
		print(stack)

func has_stack(card):
	var has_stack = false
	for st in table_holder:
		if st["value"] == card.cardvalue || st["value"] == total:
			return true
	return false
func card_on_table():
	
	for stacks in table_holder:
		if stacks["stack"].size() == 1 and stacks["stack"][0].cardvalue == total:
			return true
	return false

func add_card(card, id, value):
	card.move_card(table_card_pos, 0.0)
			
	# Remove the card from any stack it currently belongs to
	for stack in table_holder:
		if card in stack["stack"]:
			stack["stack"].erase(card)
	
	# Add the card to the appropriate stack or create a new stack if it doesn't exist
	var found_stack = false
	
	for stack in table_holder:
		if stack["id"] == id:
			if not card in stack["stack"]:
				stack["stack"].append(card)
			found_stack = true
			break
	
	if not found_stack:
		table_holder.append({"stack": [card], "id": id, "value": value})
	
	# Remove any empty stacks
	table_holder = table_holder.filter(full)
	
	card.handposition = table_card_pos
	card.handrotation = 0.0
	card.selected_card = false
	if card in hand:
		hand.erase(card)
	
	
	
	place_cards()


func check_placer(id):
	var stack_total = 0
	for table in table_holder:
		if table['id'] == id:
			for card in table["stack"]:
				stack_total += card.cardvalue
	if total == stack_total or stack_total == 0:
		return true
	else: return false
	
