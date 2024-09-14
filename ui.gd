extends Control

@onready var start_game = $MarginContainer/HBoxContainer/VBoxContainer/StartGame
@onready var e_xit = $MarginContainer/HBoxContainer/VBoxContainer/EXit

@export var main_scene = preload("res://scenes/main.tscn") as PackedScene



func _on_start_game_button_down():
	get_tree().change_scene_to_packed(main_scene)


func _on_e_xit_button_down():
	get_tree().quit()
