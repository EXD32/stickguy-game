extends Label

# Reference to the fridge boss
var fridge_boss: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find the fridge boss in the scene
	fridge_boss = _find_fridge_boss()

func _find_fridge_boss() -> CharacterBody2D:
	# Search for CharacterBody2D with fridge boss characteristics
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D and node.has_method('take_damage') and not node.has_method('get_health_percentage'):
			# Check if it has boss-like health (more than regular enemies)
			if node.has_method('get') and node.get('health') != null and node.get('health') >= 150:
				return node
		# Check nested nodes
		var found = _find_fridge_recursive(node)
		if found:
			return found
	
	return null

func _find_fridge_recursive(node: Node) -> CharacterBody2D:
	for child in node.get_children():
		if child is CharacterBody2D and child.has_method('take_damage') and not child.has_method('get_health_percentage'):
			# Check if it has boss-like health
			if child.has_method('get') and child.get('health') != null and child.get('health') >= 150:
				return child
		var found = _find_fridge_recursive(child)
		if found:
			return found
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if fridge_boss and is_instance_valid(fridge_boss):
		# Display fridge health as "Fridge Boss: 180/200"
		var current_hp = fridge_boss.get('health')
		if current_hp != null:
			text = "Fridge Boss: " + str(current_hp) + "/200"
		else:
			text = "Fridge Boss: Health Unknown"
	else:
		# Try to find fridge again if not found initially
		if not fridge_boss or not is_instance_valid(fridge_boss):
			fridge_boss = _find_fridge_boss()
		
		# Fallback text if fridge not found
		if not fridge_boss:
			text = "Fridge Boss: Not Found"
