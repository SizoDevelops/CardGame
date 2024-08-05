extends Node2D

@onready var player_hand = $Controller/PlayerHand

@onready var deck = $Controller/Deck



# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	player_hand.draw_cards(2)
	
