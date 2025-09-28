extends Label

# Reference to the player character
var player: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find the player in the scene - try multiple methods
	player = _find_player()

func _find_player() -> CharacterBody2D:
	# Method 1: Try to find by group "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Method 2: Search for CharacterBody2D with health system in the current scene
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D and node.has_method('take_damage') and node.has_method('get_health_percentage'):
			return node
		# Check nested nodes too
		var found = _find_character_recursive(node)
		if found:
			return found
	
	return null

func _find_character_recursive(node: Node) -> CharacterBody2D:
	for child in node.get_children():
		if child is CharacterBody2D and child.has_method('take_damage') and child.has_method('get_health_percentage'):
			return child
		var found = _find_character_recursive(child)
		if found:
			return found
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player and is_instance_valid(player) and player.has_method("get_health_percentage"):
		# Display health as "Health: 80/100"
		text = "Health: " + str(player.current_health) + "/" + str(player.max_health)
	else:
		# Try to find player again if not found initially
		if not player or not is_instance_valid(player):
			player = _find_player()
		
		# Fallback text if player still not found
		if not player:
			text = "Health: Player not found"
