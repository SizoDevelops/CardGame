extends PlayerHand

@onready var path = $Path2D

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
		hand[i].change_sprite("res://PNG/blue_back.png")
		#hand[i].change_sprite(card_path+fullpart)
		

		
func play_enemy_hand(card):
	print(card.front)
	card.change_sprite(card.front)

		
