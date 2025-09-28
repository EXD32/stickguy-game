extends CharacterBody2D

# NPC Properties
var has_interacted: bool = false
var is_floating: bool = false
var float_speed: float = 100.0

func _ready() -> void:
	print("Joe NPC ready - waiting for player interaction")

func _process(delta: float) -> void:
	if is_floating:
		# Float upward to infinity
		global_position.y -= float_speed * delta
		print("Joe floating upward at Y position: ", global_position.y)
	else:
		# Check for player interaction when not floating
		_check_for_player()

func _check_for_player() -> void:
	# Find the player in the scene
	var player = _find_player()
	if player and is_instance_valid(player):
		# Check distance to player
		var distance = global_position.distance_to(player.global_position)
		if distance <= 30.0:  # Close enough to interact
			_on_player_entered(player)

func _find_player() -> CharacterBody2D:
	# Search for the player in the scene
	for node in get_tree().current_scene.get_children():
		if node.name == "Player" or (node is CharacterBody2D and node.has_method('take_damage')):
			return node
	return null

func _on_player_entered(body: Node2D) -> void:
	if has_interacted:
		return
	
	if body.name == "Player":
		has_interacted = true
		print("Joe encountered the player!")
		
		# Just greet the player and start floating
		print("Joe says: Hello there!")
		
		# Start floating upward to infinity
		is_floating = true
		print("Joe is now floating upward to infinity!")
