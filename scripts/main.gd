extends Node2D

@onready var player = $Controller/PlayerHand
@onready var enemy_hand = $Controller/EnemyHand
@onready var deck = $Controller/Deck

var table_areas = []
var positions = [
	Vector2(216,137),
	Vector2(330, 137),
	Vector2(443,137),
	Vector2(555,137),
	Vector2(666,137),
	
	Vector2(268, 250),
	Vector2(382,250),
	Vector2(495,250),
	Vector2(607,250),
	Vector2(718,250)
]
var rand = RandomNumberGenerator.new()
var area_ids = []
var total = 0
var table_holder = []
var stack_holder = []
var selected = false
var slider_shown = false
var slider_id = ""
var table_card_pos = Vector2.ZERO
var store_position = Vector2.ZERO
var player_store = []
var selected_stack = ""
var hand_card_played = false
var pile_store_positions = [
	Vector2(77, 361),
	Vector2(855, 153),
	Vector2(78, 153),
	Vector2(856, 361)
]
var players = []
var stacks_to_capture = []
var piles = []
var player_hand
var enemy
var current_turn = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	players = [player.player_id, enemy_hand.player_id]
	player_hand = player
	enemy = enemy_hand
	for i in range(10):
		rand.randomize()
		area_ids.append(generate_random_id(rand))
	set_table_areas()
	player_piles()
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	get_tree().call_group("players", "draw_cards", 2)
	await get_tree().create_timer(.5).timeout
	connect_hand(player.hand)
	connect_hand(enemy_hand.hand)
	for card in enemy_hand.hand:
		card.touchable = false

func connect_hand(hand):
	
	for i in hand.size():
		if not hand[i].is_connected("active_card", Callable(self, "_active_card")):
			hand[i].connect("active_card", Callable(self, "_active_card"))
		if not hand[i].is_connected("card_selected", Callable(self, "_card_selected")):
			hand[i].connect("card_selected", Callable(self, "_card_selected"))
		if not hand[i].is_connected("add_to_stack", Callable(self, "_add_to_stack")):
			hand[i].connect("add_to_stack", Callable(self, "_add_to_stack"))
		if not hand[i].is_connected("remove_from_stack", Callable(self, "_remove_from_stack")):
			hand[i].connect("remove_from_stack", Callable(self, "_remove_from_stack"))

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

#Set up table areas
func set_table_areas():
	var table_area = load("res://scenes/table_area.tscn")
	var area
	
	for a in range(positions.size()):
		area = table_area.instantiate()
		area.position = positions[a]
		area.area_id = area_ids[a]
		table_areas.append(area)
		area.connect("id_set", Callable(self, "_on_table_area_id_set"))
		$Controller/TableAreas.add_child(area)

func player_piles():
	var pile_scene = load("res://scenes/player_store.tscn")
	var pile
	
	for pla in players.size():
		pile = pile_scene.instantiate()
		pile.position = pile_store_positions[pla]
		pile.area_id = players[pla]
		pile.connect("id_set", Callable(self, "_on_player_store_id_set"))
		piles.append({"pos": pile.position, "id": pile.area_id, "stack": pile})
		$Controller/Stores.add_child(pile)
	
	
func _on_table_area_id_set(id, node, slider, label):
	play_hand(id, node, slider, label)
	

func _process(_delta):
	
	for pi in table_areas:
		for stack in table_holder:
			if stack_holder.size() > 0:
				pi.visible = true
			
			elif stack["stack"].size() > 1 and stack["id"] == pi.area_id:
				pi.visible = true
				pi.stack.visible = true
				break
			elif stack["stack"].size() > 1 and stack_holder.size() > 0 and stack["id"] == pi.area_id:
				pi.stack.visible = true
				break
			else:
				pi.visible = false
				pi.stack.visible = false
		if table_holder.size() == 0:
			pi.stack.visible = false

			
			
	for card in enemy.player_pile["cards"]:
		if enemy.player_pile["cards"].find(card) != enemy.player_pile["cards"].size() - 1:
			card.visible = false
		else:
			card.visible = true
			
	for card in player_hand.player_pile["cards"]:
		card.touchable = false
	for card in enemy.player_pile["cards"]:
		card.touchable = true
			
	for pile in piles:
		if pile["id"] == player_hand.player_id:
			if player_hand.player_pile["cards"].size() < 1:
				pile["stack"].stack.visible = false
			else: 
				pile["stack"].stack.visible = true

func play_hand(id, node,slider, label):
	show_slider(slider, id)
	table_card_pos = node.get_global_position()
	
	# Place card on table id theres only one card selected  and that card or a card of the same value is not on the table
	if stack_holder.size() == 1  and !has_stack() and !card_in_pile(stack_holder[0]) and !has_build() and !is_position_occupied(table_card_pos):
		slider.value = total
		#print(player_hand.player_pile["cards"])
		stacks_to_capture.clear()
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value)
	
# Place card if only one card selected and that card is onready on the table and you have the same value card on hand meaning stack
	elif stack_holder.size() == 1 and has_stack() and can_steal(stack_holder[0], id) and hand_has_card() and is_position_occupied((table_card_pos)):
		slider.value = total
		#print("Called")
		stacks_to_capture.clear()
		var store = []
		
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value)
			
# Add all the same value cards to from the hand to a temp store
		for cards in player_hand.hand:
			if cards.cardvalue == player_hand.selected_card.cardvalue:
				store.append(cards)
				
# Check if player has the cards value in hand if not then the player is force to capture
		auto_capture(store, id)
		
# Prevents creating multiple identical stack
	elif stack_holder.size() > 1  and hand_has_card() and !has_stack():
		slider.value = total
		print("Called")
		stacks_to_capture.clear()
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value)
			
	elif stack_holder.size() > 1 and hand_has_card() and has_stack() and is_position_occupied(table_card_pos):
		slider.value = total
		stacks_to_capture.clear()
		#print("Here")
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value)	
			
	else:
		for card in player_hand.hand:
			card.off_focus()	
		for card in table_holder:
			for cd in card["stack"]:
				cd.off_focus()
		for card in enemy.player_pile["cards"]:
			card.off_focus()
	
	for card in table_holder:
		if build_type(id, slider.value) == "augumented" and card["id"] == id:
			for i in card["stack"]:
				i.touchable = false
	stack_holder.clear()

	player_hand.selected_card = null
	
# Check if theres a pile or stack of the same value
func has_stack():
	for stack in table_holder:
		if stack["value"] == total:
			return true
	return false
	
#Check if player has build on the table

func has_build():
	for stack in table_holder:
		if stack["owner"] == player_hand.player_id:
			return true
	return false
func has_permission():
	#TO add partner check
# Check if it's own build
	pass

func card_in_pile(card):
	if card in enemy.player_pile["cards"]:
		return true
	return false

func auto_capture(store, id):
	if store.size()>0:
		for sta in table_holder:
			if sta["owner"] == enemy.player_id and sta["id"] == id:
				
				stacks_to_capture.append(sta)
				move_to_pile(player_hand.player_id, find_object_by_id(player_hand.player_id)["pos"])
			elif sta["id"] == id:
				stacks_to_capture.append(sta)
	else: 
		for sta in table_holder:
			if sta["id"] == id:
				stacks_to_capture.append(sta)
		
		move_to_pile(player_hand.player_id, find_object_by_id(player_hand.player_id)["pos"])

func can_steal(card, stack_id):
	for stack in table_holder:
		if card_in_pile(card) and stack["id"] == stack_id and stack["value"] == card.cardvalue:
			return true
		elif !card_in_pile(card):
			return true
	return false

			

func find_object_by_id(target_id):
	for obj in piles:
		if obj["id"] == target_id:
			return obj  # Return the found object
	return null  # Return null if not found
	
	
#Check if player has card in hand
func hand_has_card():
	for card in player_hand.hand:
		if card.cardvalue == total:
			return true
	return false



# Add and move card to the table
func add_card(card, id, value):
#Move a card that's onlready on the table
	for stack in table_holder:
		if card in stack["stack"]:
			stack["stack"].erase(card)
	
# Add the card to the appropriate stack or create a new stack if it doesn't exist
	var found_stack = false
	for stack in table_holder:
		if stack["id"] == id:
			if not card in stack["stack"]:
# This now a pile meaning more than one card on top of another
				stack["stack"].append(card)
				stack["last_played"] = Time.get_unix_time_from_system()
				if stack["owner"] == "":
					stack["owner"] = player_hand.player_id
				
			found_stack = true
			break

	if not found_stack:
		table_holder.append({"stack": [card], "id": id, "value": value, "owner": "", "last_played": float()})
	
	# Remove any empty stacks
	
	table_holder = table_holder.filter(full)
	
	for stacks in table_holder:
		for cards in stacks["stack"]:
			cards.z_index = stacks["stack"].find(cards)
	
	for areas in table_areas:
		for stack in table_holder:
			if stack["id"] == areas.area_id and stack["stack"].size() > 0:
				areas.h_slider.value = stack["value"]
				break
			else:
				areas.h_slider.value = 0
# Create an unsorted copy of the stack to check if it's augumented or not

# Move card to the correct position
	card.move_card(table_card_pos, 0.0, Vector2(0.6, 0.6))

	
	
# Update the position of the card in case a move is invalid
	card.handposition = table_card_pos
	card.handrotation = 0.0
# Unselect the card
	card.selected_card = false
	if card in player_hand.hand:
		play_card(card)
	if card in enemy.player_pile["cards"]:
		enemy.player_pile["cards"].erase(card)
		
	if hand_card_played:
		for cards in player_hand.hand:
			cards.touchable = false
		
	if enemy.player_pile["cards"].size()> 0 and card in enemy.player_pile["cards"]:
		enemy.player_pile["cards"].erase(card)
# Re-place the card on the hand
	player_hand.place_cards()
	print(enemy.player_pile["cards"])

#Triggered when you click on the captured piles 
func _on_player_store_id_set(id, node):
	store_position  = node.get_global_position()
	move_to_pile(id, store_position)
	
	if enemy.player_pile["cards"].size() > 0 and id != player_hand.player_id:
		enemy.player_pile["cards"][enemy.player_pile["cards"].size() - 1].touchable = true
		enemy.player_pile["cards"][enemy.player_pile["cards"].size() - 1].select_card()


func move_to_pile(id, store):
	
	if stacks_to_capture.size() == 1 and id == player_hand.player_id:
		for ca in stacks_to_capture[0]["stack"]:
					player_hand.player_pile["cards"].append(ca)
					ca.handposition = store
					
					
		for sta in table_holder:
			if sta["id"] == stacks_to_capture[0]["id"]:
				table_holder.erase(sta)
				
		for cards in stacks_to_capture[0]["stack"]:
			cards.move_card(store)

		stacks_to_capture.clear()
		


#Builds
func build_type(id, value):
	var type = "single"
	var acc = 0
	var tot = 0
	
	for cards in table_holder:
		if cards["id"] == id:
			for card in cards["stack"]:
				tot += card.cardvalue
				if tot == value:
					acc += 1
					tot = 0
					continue
	if acc < 2 :
		type = "single"
	else: 
		type = "augumented"
		
	return type
	
	
#Check if position in table is occupied
func is_position_occupied(pos):
	
	for cards in table_holder:
		if (cards.stack.size() > 0 and cards.stack[cards.stack.size() - 1].position.distance_to(pos) < 50) :  # Assuming card_size is a function or constant
			return true
	return false

#Used as a filter for empty stacks
func full(elem):
	return elem.stack.size() > 0

#Show slider on the table
func show_slider(slider, id):
	var has_card = false

	for card in table_holder:
		if card["id"] == id and card["stack"].size() > 0:
			has_card = true
	
	if !slider.visible  and !player_hand.selected_card and !has_card and table_holder.size() > 0 and !slider_shown and (slider_id != id || slider_id == ""):
		slider.visible = true
		slider_shown = true
		slider_id = id
		
	elif slider_id == id: 
		slider.visible = false
		slider_shown = false
		slider_id = ""

	# Sort By Value
func play_card(card):
	if card in player_hand.hand:
		player_hand.hand.erase(card)
		hand_card_played = true
	else:
		hand_card_played = false
	
func _add_to_stack(card):
	if not stack_holder.has(card):
		stack_holder.append(card)
	var temp = 0
	for i in stack_holder:
		temp += i.cardvalue
	total = temp

func _remove_from_stack(card):
	stack_holder.erase(card)
	var temp = 0
	for i in stack_holder:
		temp += i.cardvalue
	total = temp
	player_hand.selected_card = null

func _active_card(card):
	for i in player_hand.hand.size():
		player_hand.hand[i].make_active(card)
	
	for cards in table_holder:
		for c in cards["stack"]:
			c.table_card(card)
	player_hand.selected_card = card

func sorted_stack(stack):
	stack.sort_custom(func(a, b): return a.cardvalue > b.cardvalue)

	return stack

func _on_change_turn_change_turn():
	change_turn()
	
func change_turn():
	if current_turn == 2 and hand_card_played:
		player_hand = player
		enemy = enemy_hand
		hand_card_played = false
		for card in enemy_hand.hand:
			card.touchable = false
		for card in player.hand:
			card.touchable = true
		
		current_turn = 1
	
	
	elif current_turn == 1 and hand_card_played:
		player_hand = enemy_hand
		enemy = player
		hand_card_played = false
		for card in player.hand:
			card.touchable = false
		for card in enemy_hand.hand:
			card.touchable = true
		
		current_turn = 2
