extends Node2D

@export var stack_scale = Vector2(0.9, 0.9)
@onready var stack = $Stack

func _ready():
	scale = stack_scale
	
