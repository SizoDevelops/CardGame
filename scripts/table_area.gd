extends Area2D



var area_id = ""
signal  id_set(id, node, value, slider)
var stack_size = 0

func _ready():
	$HSlider.connect("value_changed", Callable(self, "_on_HSlider_value_changed"))
	$Label.text = str($HSlider.min_value)
	# Create an instance of the RandomNumberGenerator
	var rng = RandomNumberGenerator.new()
	
	# Seed the generator with the system's entropy for more unpredictability
	rng.randomize()
	area_id = generate_random_id(rng)
	
	# Generate a random ID
# Function to generate a random ID string
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

func _on_HSlider_value_changed(value):
	# Update the label with the current value of the slider
	$Label.text = str(value)
	stack_size = value

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("id_set", area_id, $Area, stack_size, $HSlider)
			
