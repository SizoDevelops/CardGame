extends Node2D

@export var table_size = Rect2(Vector2(0, 0), Vector2(300, 180))
var cards = []

func add_card(card):
	cards.append(card)
	add_child(card)
	card.connect("area_entered", card, "_on_area_entered")
	card.set_on_table(true)  # Mark the card as on the table

func remove_card(card):
	if card in cards:
		cards.erase(card)
		card.queue_free()

func _process(delta):
	for card in cards:
		if card.stacked:
			# Ensure stacked cards stay in place
			card.global_position = card.get_parent().global_position
