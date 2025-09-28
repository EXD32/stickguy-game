extends AnimatedSprite2D

# Health monitoring variables
var fboss_node: CharacterBody2D = null
var has_disappeared: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find fboss on scene load
	fboss_node = _find_fboss()
	if fboss_node:
		print("Kai2.0 found fboss and is monitoring its health")
	else:
		print("Kai2.0 could not find fboss")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Monitor fboss health every frame
	if not has_disappeared:
		_check_fboss_health()

func _find_fboss() -> CharacterBody2D:
	# Search for fboss in the scene (400 HP floating boss)
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D:
			# Use method presence check to identify fboss reliably
			if node.has_method('get_health_percentage'):
				# Check if it has high health (likely a boss)
				if node.has_method('get') and node.get('max_health') == 400:
					return node
		# Check nested nodes
		var found = _find_fboss_recursive(node)
		if found:
			return found
	return null

func _find_fboss_recursive(node: Node) -> CharacterBody2D:
	for child in node.get_children():
		if child is CharacterBody2D:
			if child.has_method('get_health_percentage'):
				if child.has_method('get') and child.get('max_health') == 400:
					return child
		var found = _find_fboss_recursive(child)
		if found:
			return found
	return null

func _check_fboss_health() -> void:
	# Try to find fboss if we don't have one or it's invalid
	if not fboss_node or not is_instance_valid(fboss_node):
		fboss_node = _find_fboss()
		if not fboss_node:
			return
	
	# Check fboss health using reliable method
	if fboss_node.has_method('get') and fboss_node.get('health') != null:
		var fboss_health = fboss_node.get('health')
		
		# Make sprite disappear when fboss health drops below 50
		if fboss_health < 50:
			print("FBOSS HEALTH BELOW 50! Kai2.0 sprite disappearing! Fboss health: ", fboss_health)
			_disappear_sprite()

func _disappear_sprite() -> void:
	if has_disappeared:
		return  # Already disappeared
	
	has_disappeared = true
	
	# Make the sprite invisible
	visible = false
	
	# Optional: Add fade out effect
	var tween = create_tween()
	modulate.a = 1.0
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	print("Kai2.0 sprite has disappeared!")
