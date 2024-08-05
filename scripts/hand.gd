extends Node2D

@onready var deck = $"../Deck"


var hand = []
var card_path = "res://PNG/"
var card_width
var table_card_pos = Vector2.ZERO
@export var card_scale = Vector2(0.6, 0.6)
var index = 0
var rng

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
	

	selected_card = card

func give_hand():
	return hand
	


func is_position_occupied(position: Vector2) -> bool:
	
	for card in table_holder:
		
		if card.stack.size() > 0 and card.stack[card.stack.size() - 1].position.distance_to(position) < 50:  # Assuming card_size is a function or constant
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
	

func _on_table_area_id_set(id, event):
	table_card_pos = to_local(event.position)
	if selected_card and !is_position_occupied(table_card_pos) and selected_card.selected_card:
		selected_card.move_card(table_card_pos, 0.0)
		
		# Remove the card from any stack it currently belongs to
		for stack in table_holder:
			if selected_card in stack["stack"]:
				stack["stack"].erase(selected_card)
		
		# Add the card to the appropriate stack or create a new stack if it doesn't exist
		var found_stack = false
		
		for stack in table_holder:
			if stack["id"] == id:
				if not selected_card in stack["stack"]:
					stack["stack"].append(selected_card)
				found_stack = true
				break
		
		if not found_stack:
			table_holder.append({"stack": [selected_card], "id": id})
		
		# Remove any empty stacks
		table_holder = table_holder.filter(full)
		
		selected_card.handposition = table_card_pos
		selected_card.handrotation = 0.0
		selected_card.selected_card = false
		hand.erase(selected_card)
		selected_card = null
		
		place_cards()
		print(table_holder)
	else:
		print(id)



