extends Node2D

@onready var player = $Controller/PlayerHand
@onready var deck = $Controller/Deck
@onready var deck_stack = $Deck
@onready var change_turn_btn = $Controller/ChangeTurn

var table_areas = []
var last_capture = ""
var positions = [
	Vector2(216,147),
	Vector2(330, 147),
	Vector2(443,147),
	Vector2(555,147),
	Vector2(666,147),
	
	Vector2(258, 280),
	Vector2(372,280),
	Vector2(485,280),
	Vector2(597,280),
	Vector2(708,280)
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
	Vector2(67, 361),
	Vector2(865, 153),
	Vector2(67, 153),
	Vector2(865, 361)
]
var enemies = [
	{
		"pos": Vector2(-182, -153),
		"rot": 0.0
	},
	
	{
		"pos": Vector2(152, -456),
		"rot": deg_to_rad(90)
	},
	
	{
		"pos": Vector2(1085, -456),
		"rot": deg_to_rad(90)
	},
	
]
var players = []
var player_hands = []
var stacks_to_capture = []
var piles = []
var players_ = {}
var current_player
var current_turn = 0
var game_round = 1
var captured = false
var number_of_players = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	current_player = player
	for i in range(10):
		rand.randomize()
		area_ids.append(generate_random_id(rand))
	set_table_areas()
	connect_players()
	initialize_round()
	player_piles()

func connect_players():
	players = [player.player_id]
	player_hands = [player]
	var enemy_player = load("res://scenes/enemy_hand.tscn")
	for i in range(number_of_players):
		var enmy = enemy_player.instantiate()
		enmy.position = Vector2.ZERO
		var child = enmy.get_node("Path2D")
		var deck_location = enmy.get_node("DeckLocation")
		child.position = enemies[i]["pos"]
		child.rotation = enemies[i]["rot"]
		deck_location.position = Vector2(191, 54)
		player_hands.append(enmy)
		
		
	for i in player_hands.slice(1):
		$Controller.add_child(i)
		
		players.append(i.player_id)
		
	
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
		
		if pile.area_id == current_player.player_id:
			pile.label.text = "Capture" 
		else:
			pile.label.text = "Steal"
	
func _on_table_area_id_set(id, node, slider, _label):
	table_card_pos = node.get_global_position()
	two_player_hand(id, table_card_pos, slider)
	

func _process(_delta):

	is_stackable()
	hide_show_table_areas()
	hide_show_player_stacks()
	auto_steal()
	
	
	
	
func hide_show_table_areas():
	for pi in table_areas:
		pi.z_index = 0
		pi.visible = false
		for stack in table_holder:
			if stack["stack"].size() > 1 and stack["id"] == pi.area_id:
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
			
		if stack_holder.size() > 0:
				pi.visible = true
		
				
			
func hide_show_player_stacks():
	
	for pile in piles:
		if pile["id"] == current_player.player_id:
			if current_player.player_pile["cards"].is_empty():
				pile["stack"].stack.visible = false
			else: 
				pile["stack"].stack.visible = true

	for hnd in player_hands:
		if hnd.player_id != current_player.player_id:
			for card in hnd.player_pile["cards"]:
				card.touchable = true
		else:
			for card in hnd.player_pile["cards"]:
				card.touchable = false
		
	for hnd in player_hands:
		for i in hnd.player_pile["cards"].size():
			hnd.player_pile["cards"][i].z_index = i
			if i !=  hnd.player_pile["cards"].size() - 1:
				hnd.player_pile["cards"][i].touchable = false
					
func two_player_hand(id, pos,slider):
	
	
	# Place card on table id theres only one card selected  and that card or a card of the same value is not on the table
	if stack_holder.size() == 1  and !has_stack(total) and !card_in_pile(stack_holder) and build_count() < 1  and !is_position_occupied(pos) and build_count() < 2:
		slider.value = total
		#print(current_player.player_pile["cards"])
		stacks_to_capture.clear()
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value, pos)
	
# Place card if only one card selected and that card is onready on the table and you have the same value card on hand meaning stack
	elif stack_holder.size() == 1 and has_stack(total) and check_same_value(total, id) and can_steal(stack_holder, pos) and hand_has_card() and is_position_occupied((pos)):
		slider.value = total
		#print("Called")
		stacks_to_capture.clear()
		var store = []
		
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value, pos)
			
		
		
# Add all the same value cards to from the hand to a temp store
		for cards in current_player.hand:
			for stc in table_holder:
				if stc["owner"] == current_player.player_id:
						if cards.cardvalue == stc["value"]:
								store.append(cards)
				
# Check if player has the cards value in hand if not then the player is force to capture
		
		auto_capture(store, id)
		
# Prevents creating multiple identical stack
	elif stack_holder.size() > 1  and hand_has_card() and can_steal(stack_holder, pos) and !has_stack(total) and has_permission(pos) and !is_position_occupied(pos) and build_count() <= 1:
		slider.value = total
		#print("Called")
		stacks_to_capture.clear()
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value, pos)
			
	elif stack_holder.size() > 1 and hand_has_card() and can_steal(stack_holder, pos) and has_stack(total) and is_position_occupied(pos) and has_permission(pos) and is_owner() and build_count() <= 1:
		slider.value = total
		stacks_to_capture.clear()
		#print("Here")
		for card in sorted_stack(stack_holder):
			add_card(card, id, slider.value, pos)	
			
	else:
		for card in current_player.hand:
			card.off_focus()	
		for card in table_holder:
			for cd in card["stack"]:
				cd.off_focus()
				
	for hnd in player_hands:
		if hnd.player_id != current_player.player_id:
			for card in hnd.player_pile["cards"]:
				card.off_focus()
	
	for card in stack_holder:
		remove_from_pile(card)
		stack_holder.erase(card)
	
	
	
# Check if theres a pile or stack of the same value
func has_stack(tot):
	for stack in table_holder:
		if stack["value"] == tot:
			return true
	return false
	
func remove_from_pile(card):
	for hnd in player_hands:
		if hnd.player_id != current_player.player_id:
			for card_ in hnd.player_pile["cards"]:
				if card_ == card:
					hnd.player_pile["cards"].erase(card)
					
#Check if player has a build on the table
func build_count():
	var count = 0
	for stack in table_holder:
		if stack["owner"] == current_player.player_id:
			count += 1
	return count

func is_owner():
	for builds in table_holder:
		if builds["owner"] == current_player.player_id || builds["owner"] == "":
			return true
	return false
	
func check_same_value(tot, id):
	for card in table_holder:
		if card["value"] == tot and card["id"] == id:
			return true
	return false
	
func has_permission(pos):
	for card in stack_holder:
		for hnd in player_hands:
			if hnd.player_id != current_player.player_id:
				if card in hnd.player_pile["cards"] and is_position_occupied(pos):
					return true
				if card not in hnd.player_pile["cards"]:
					return true
				if card in hnd.player_pile["cards"] and !is_position_occupied(pos):
					return false
	return false

func card_in_pile(cards):
	for card in cards:
		for hnd in player_hands:
			if hnd.player_id != current_player.player_id:
				if card in hnd.player_pile["cards"]:
					return true
	return false

func auto_capture(store, id):
	if store.size() > 0 :
		for sta in table_holder:
			
			if (sta["owner"] != current_player.player_id || build_count() > 1)  and sta["id"] == id:
				stacks_to_capture.append(sta)
				
				move_to_pile(current_player.player_id, find_object_by_id(current_player.player_id)["pos"])
				captured = true
				
				change_turn()
				
			elif sta["id"] == id and build_count() <= 1:
				stacks_to_capture.append(sta)
	else: 
		for sta in table_holder:
			
			if sta["id"] == id:
				stacks_to_capture.append(sta)
				
			
			move_to_pile(current_player.player_id, find_object_by_id(current_player.player_id)["pos"])
			captured = true
			
		change_turn()
	

func can_steal(cards, pos):
	for stack in table_holder:
		if card_in_pile(cards) and is_position_occupied(pos):
			return true
		elif !card_in_pile(cards):
			return true
	return false

			

func find_object_by_id(target_id):
	for obj in piles:
		if obj["id"] == target_id:
			return obj  # Return the found object
	return {}  # Return null if not found
	
	
#Check if player has card in hand
func hand_has_card():
	for card in current_player.hand:
		if card.cardvalue == total:
			return true
	return false

func player_build():
	for stacks in table_holder:
		if stacks["owner"] == current_player.player_id:
			return stacks["value"]
	return null
	
func player_build_id():
	for stacks in table_holder:
		if stacks["owner"] == current_player.player_id:
			return stacks["id"]
	return null
# Add and move card to the table
func add_card(card, id, value, pos):
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
				stack["pos"] = pos
				if stack["owner"] == "":
					stack["owner"] = current_player.player_id
			if augument_builds(stack) == "augumented":
				stack["build"] = "augumented"
			found_stack = true
			break

	if not found_stack:
		table_holder.append({"stack": [card], "id": id, "value": value, "owner": "", "pos": pos, "build": "single"})
	
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
	
	card.change_sprite(card.front)
	card.move_card(pos, 0.0, Vector2(0.6, 0.6))

	
	
# Update the position of the card in case a move is invalid
	card.handposition = pos
	card.handrotation = 0.0
# Unselect the card
	card.selected_card = false
	if card in current_player.hand:
		play_card(card)
	
	for hnd in player_hands:
		if hnd.player_id != current_player.player_id:
			for cd in hnd.player_pile["cards"]:
				if cd == card:
					hnd.player_pile["cards"].erase(card)
		
	if hand_card_played:
		for cards in current_player.hand:
			cards.touchable = false
			

	for hnd in player_hands:
		if hnd.player_id != current_player.player_id:
			if hnd.player_pile["cards"].size()> 0 and card in hnd.player_pile["cards"]:
				hnd.player_pile["cards"].erase(card)
# Re-place the card on the hand
	current_player.place_cards()


#Triggered when you click on the captured piles 
func _on_player_store_id_set(id, node):
	store_position  = node.get_global_position()
	
	move_to_pile(id, store_position)
	captured = true
func auto_steal():
	for hand in player_hands:
		if hand.player_id != current_player.player_id:
			for stack in table_holder:
				if stack["owner"] == current_player.player_id:
					for cards in hand.player_pile["cards"]:
						if hand.player_pile["cards"].find(cards) == hand.player_pile["cards"].size() - 1 and cards.cardvalue == stack["value"]:
							add_card(cards, stack["id"],stack["value"], stack["pos"])
					break
func move_to_pile(id, store):
	
	last_capture = id
	if stacks_to_capture.size() == 1 and id == current_player.player_id:
		for sta in table_holder:
			if sta["id"] == stacks_to_capture[0]["id"]:
				table_holder.erase(sta)
				
		for cards in stacks_to_capture[0]["stack"]:
			cards.move_card(store)
			
		var count = 0
		for ca in stacks_to_capture[0]["stack"]:
					ca.handposition = store
					count += 1
		if count >= len(stacks_to_capture[0]["stack"]):
			for cards in stacks_to_capture[0]["stack"]:
				current_player.player_pile["cards"].append(cards)

		stacks_to_capture.clear()

		
	# Prevent Consercutive steals
	for hnd in player_hands:
		if hnd.player_id != current_player.player_id:
			for cards in hnd.player_pile["cards"]:
				cards.touchable = false
				
	

	

func is_stackable():
	for builds in table_holder:
		if builds["stack"].size() > 1 and builds["owner"] == current_player.player_id:
			for card in builds["stack"]:
				card.touchable = false
		elif builds["build"] == "augumented":
			for card in builds["stack"]:
				card.touchable = false
		else:
			for card in builds["stack"]:
				card.touchable = true




#Builds
func augument_builds(cards):
	var acc = 0
	var tot = 0
	
	for card in cards["stack"]:
		tot += card.cardvalue
		if tot == cards["value"]:
			acc += 1
			tot = 0

		
	if acc < 2 :
		return "single"
	else: 
		return "augumented"
		
	
	
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
	
	if !slider.visible  and !current_player.selected_card and !has_card and table_holder.size() > 0 and !slider_shown and (slider_id != id || slider_id == ""):
		slider.visible = true
		slider_shown = true
		slider_id = id
		
	elif slider_id == id: 
		slider.visible = false
		slider_shown = false
		slider_id = ""

	# Sort By Value
func play_card(card):
	if card in current_player.hand:
		current_player.hand.erase(card)
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
	current_player.selected_card = null


func _active_card(card):
	for i in current_player.hand.size():
		current_player.hand[i].make_active(card)
		
	for cards in table_holder:
		for c in cards["stack"]:
			c.table_card(card)
			
	current_player.selected_card = card
	

func sorted_stack(stack):
	stack.sort_custom(func(a, b): return a.cardvalue > b.cardvalue)

	return stack

func _on_change_turn_change_turn():
	change_turn()
	
func change_turn():
	
	if current_turn < len(player_hands) and hand_card_played:
		current_turn += 1
		
	if current_turn == len(player_hands) and hand_card_played:
		if current_player.hand.is_empty():
			initialize_round()
			
		current_turn = 0
		
		change_turn_btn.visible = true
		
	
	
	
	if hand_card_played:
		current_player = player_hands[current_turn]
		hand_card_played = false
		
		for hnd in player_hands:
			if hnd.player_id != current_player.player_id:
				for card in hnd.hand:
					card.touchable = false
			else:
				for card in hnd.hand:
					card.touchable = true

			if current_player.player_id != player.player_id:
				change_turn_btn.visible = false
				await get_tree().create_timer(.5).timeout
				play_ai_move()
				
			
				
	captured = false
	
#AI Logic

func initialize_round():
	if game_round <= 2 :
		deck_stack.visible = true

		for i in range(5):
			get_tree().call_group("players", "draw_cards", 2)
			await get_tree().create_timer(.5).timeout
		
		for hand in player_hands:
			connect_hand(hand.hand)
		
		deck_stack.visible = false
		for hand in player_hands:
			if hand.player_id != players[0]:
				for card in hand.hand:
					card.touchable = false
		game_round += 1
		
	else:
		for hand in player_hands:
			connect_hand(hand.hand)
			
		await get_tree().create_timer(.5).timeout
		
		if last_capture != "":
			for ply in player_hands:
				if last_capture == ply.player_id:
					current_player = ply
					
			while !table_holder.is_empty():		
				for stacks in table_holder:
					auto_capture([], stacks["id"])
				
			
		$Message.alert.text = "Game Over"
		$Message.animation_player.play("message")
		return

func play_ai_move():
# Check valid moves
	ai_valid_moves()

func ai_valid_moves():
	
	while current_turn != 0:
		await get_tree().create_timer(.2).timeout
		var priority_moves = []
		var card_total = 0
		
		for i in current_player.hand.size():
			card_total = 0
			var card = current_player.hand[i]
			for cards in current_player.hand:
				if card.cardvalue == cards.cardvalue:
					card_total += 1
					
			if card_total > 1 and card.cardvalue not in priority_moves:
				priority_moves.append(card.cardvalue)
		
	# pick cards that make up the largest priority move
		var hold_values = []
		for values in table_holder:
			if values["owner"] != current_player.player_id and values["build"] == "single" and values["value"] < 10:
				hold_values.append({"value": values["value"], "stack":values["stack"]})
		
		var highest = 0
		if current_player.sorted_hand().size() > 0 and priority_moves.size() > 0 and  highest < priority_moves.max() and !player_build() and priority_moves.max() >= current_player.sorted_hand()[0].cardvalue:
			highest = priority_moves.max()
			
		elif player_build():
			highest = player_build()
		elif current_player.sorted_hand().size() > 0:
			highest = current_player.sorted_hand()[0].cardvalue
		for stacks in table_holder:
			for hnd in player_hands:
				if hnd.player_id != current_player.player_id:
					if stacks["value"] == highest and stacks["owner"] == hnd.player_id:
						highest = 0
						break	
		for hnd in player_hands:
			if hnd.player_id != current_player.player_id:
				if hnd.player_pile["cards"].size() > 0 and has_stack(highest):
					hold_values.append({"value": hnd.player_pile["cards"][hnd.player_pile["cards"].size() - 1].cardvalue, "stack": [hnd.player_pile["cards"][hnd.player_pile["cards"].size() - 1]]})	
		var r = find_combinations_with_most_numbers(hold_values, highest)
		
		#print(r, "    ", highest, " ------  ", priority_moves)
		if current_turn == 0 or (current_player.player_id != players[0] and current_player.hand.is_empty()):
			return
			
		check_better_stack(r, current_player.hand, highest)
		
		
		
func find_combinations_with_most_numbers(arr, max_sum):
	arr.sort_custom(_compare_values)  # Sort the array based on the "value"
	var all_combinations = {}

	for target_sum in range(max_sum, 0, -1):
		var result = []
		_backtrack(arr, 0, [], target_sum, result)
		if result.size() > 0:
			all_combinations[target_sum] = result
	return all_combinations

func _backtrack(arr, start, path, target, result):
	if target == 0:
		result.append(path.duplicate())  # Add a copy of the current path to the result
		return
	
	for i in range(start, arr.size()):
		if arr[i]["value"] > target:
			break
		# Recursively build the combination, ensuring each object is used only once
		path.append(arr[i]["stack"])
		_backtrack(arr, i + 1, path, target - arr[i]["value"], result)  # Move to the next index
		path.pop_back()  # Remove the last element to backtrack

func _compare_values(a, b):
	return a["value"] - b["value"]

func _compare_array_length(a, b):
	return a.size() > b.size()
	
func check_better_stack(moves, hand, target):
	var hold = []
	
	if hold.size() == 0:
		
		for i in moves.keys().size():
			for combo in moves[moves.keys()[i]]:
# 10: [---[[@Area2D@19:<Area2D#31927043405>], [@Area2D@13:<Area2D#31390172461>]]]
				if combo.size() > 1:
					# 10: [---[---[@Area2D@19:<Area2D#31927043405>], [@Area2D@13:<Area2D#31390172461>]]]
					for stacks in combo:
						# 10: [---[---[---@Area2D@19:<Area2D#31927043405>], [@Area2D@13:<Area2D#31390172461>]]]
						for card in stacks:
							hold.append(card)
							
							break
					if hold.size() > 0:
						var sum = 0
						for cards in hold:
							sum += cards.cardvalue
						if sum == target:
							break
						else:
							if !hand_card_played:
								for card in hand:
									if card.cardvalue + sum == target:
										hold.append(card)
										break
						sum = 0	
						for cards in hold:
							sum += cards.cardvalue
						#print("SUM    ", sum)
						if sum != target:
							hold.clear()
							
				elif combo.size() == 1:
					 #[---[[@Area2D@19:<Area2D#31927043405>]]---]
					if !hand_card_played:
						for card in hand:
							if card.cardvalue + moves.keys()[i] == target:
								hold.append(card)
								#[---[---[@Area2D@19:<Area2D#31927043405>]---]---]
								for cards in combo[0]:
									hold.append(cards)
								break
							
			if !hold.is_empty():
				break

	for card in hold:
		card.select_card("enemy")
	#print("THIS IS THE INITIAL STACK", stack_holder)
	for i in hold.size():
		if hold[i] in hand and i == 0:
			hold[i].select_card("enemy")
			
			break
			
	
		
	#print(stack_holder, ".....................", hold)
	
	var o = []
	for card in hold:
		o.append(card.cardvalue)
	
	
	var s = []
	for card in stack_holder:
		s.append(card.cardvalue)
		
	print("STACK  ", s, " HOLD  ", o)
	var sum1 = 0
	for i in s:
		sum1 += i

	if sum1 > target:
		stack_holder.clear()


	if !stack_holder.is_empty():
		
		for area in table_areas:	
			var ar = table_areas.pick_random()
			for a in table_holder:
				if a["owner"] == current_player.player_id or a["owner"] == "" and a["value"] == total:
					two_player_hand(a["id"], a["pos"], area.h_slider)
					break
				elif a["value"] == total and a["owner"] != "":
					two_player_hand(a["id"], a["pos"], area.h_slider)
					break
				
			
			if !stack_holder.is_empty():
				two_player_hand(ar.area_id, ar.position, ar.h_slider)
				break
			
				
	else:
		var card = null
		for i in  moves.keys().size():
			for cards in hand:
				if cards.cardvalue == moves.keys()[i] and moves[moves.keys()[i]][0].size() == 1:
					for stacks in table_holder:
						if stacks["value"] == cards.cardvalue:
							card = cards
							break
				if card:
					break
			if card:
				break
					
		if table_holder.size() > 0 and !card:
			for cards in table_holder:
				if cards["owner"] != current_player.player_id:
					for cd in hand:
						if cd.cardvalue == cards["value"]:
							card = cd
							break
				if card:
					break
			
				
					
		if build_count() == 1 and !card:
			for cards in hand:
				if cards.cardvalue == player_build():
					card = cards
					break
					
		if !card:
			card = hand.pick_random()
			
		if card:
			card.select_card("enemy")
			

		for area in table_areas:
			var ar = table_areas.pick_random()	
			for a in table_holder:
				if a["owner"] == current_player.player_id and a["value"] == card.cardvalue:
					two_player_hand(a["id"], a["pos"], ar.h_slider)
				
					break
				elif a["value"] == total:
					two_player_hand(a["id"], a["pos"], ar.h_slider)
					
					break
		
			if !hand_card_played:
				two_player_hand(ar.area_id, ar.position, ar.h_slider)
				
				break
														 
			if is_position_occupied(ar.position):
				ar = table_areas.pick_random()
			if captured:
				hold.clear()


	

	if moves.keys().is_empty() and hand_card_played:
		change_turn()

	if hold.is_empty() and hand_card_played:
		change_turn()
	hold.clear()

	
