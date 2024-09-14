extends Node2D
class_name PlayerHand
@onready var deck = $"../Deck"


var hand = []
var card_path = "res://PNG/"
var card_width
@export var card_scale = Vector2(0.6, 0.6)
var selected_card = null
var player_id = ""
var player_pile = {"id": "", "cards": []}

signal hand_empty

func _ready():
	# Create an instance of the RandomNumberGenerator
	var rand = RandomNumberGenerator.new()
	
	# Seed the generator with the system's entropy for more unpredictability
	rand.randomize()
	player_id = generate_random_id(rand)
	player_pile["id"] = player_id
	# Generate a random ID
# Function to generate a random ID string
func generate_random_id(rng):
	# Length of the ID
	var length = 16
	
	# Characters to use in the ID
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var id = ""
	
	for i in range(length):
		# Pick a random character from the chars string
		var character = chars[rng.randi_range(0, chars.length() - 1)]
		id += character
	
	return id


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
		hand[i].front = card_path+fullpart
		hand[i].change_sprite(card_path+fullpart)



	



func place_cards():
	var path_length = $Path2D.curve.get_baked_length()
	var space
	var ideal_cardwidth
	var hand_width

	# Calculate ideal card width and hand width
	if hand.size() == 0:
		emit_signal("hand_empty")
		return
		
	card_width = hand[0].card_width()  # Assuming all cards have the same width
	ideal_cardwidth = card_width * 0.5
	hand_width = ideal_cardwidth * hand.size()

	# Ensure cards are not already added
	for card in sorted_hand():
		if card.get_parent() != self:
			add_child(card)

	# Calculate space and positioning
	space = path_length
	$Path2D/PathFollow2D.progress = 0.0
	
	if hand_width < path_length:
		$Path2D/PathFollow2D.progress = (space - hand_width) / 2
	
	else:
		ideal_cardwidth = space / hand.size()
	
	
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
	
func give_hand():
	return hand
	


func sorted_hand():
	hand.sort_custom(func(a, b): return a.cardvalue > b.cardvalue)
	return hand
