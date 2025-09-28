extends RigidBody2D

# Random pickup that can either heal or damage the player
# Only dropped by the Fridge boss, once per defeat

var effect_applied: bool = false

func _ready() -> void:
	# Setup visual appearance - distinctive purple color to differentiate from healing pickups
	var sprite = ColorRect.new()
	sprite.size = Vector2(20, 20)
	sprite.color = Color.PURPLE  # Purple to distinguish from green healing pickups
	add_child(sprite)
	
	# Setup collision for physics
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision.shape = shape
	add_child(collision)
	
	# Setup Area2D for player detection
	var area = Area2D.new()
	var area_collision = CollisionShape2D.new()
	var area_shape = RectangleShape2D.new()
	area_shape.size = Vector2(20, 20)
	area_collision.shape = area_shape
	area.add_child(area_collision)
	add_child(area)
	
	# Connect signal for player detection
	area.body_entered.connect(_on_player_entered)
	
	print("Random pickup created!")

func _on_player_entered(body: Node2D) -> void:
	if effect_applied:
		return
		
	if body.name == "Player" and body.has_method('take_damage') and body.has_method('heal'):
		effect_applied = true
		
		# Generate random effect: 50% chance to heal, 50% chance to damage
		var is_healing = randf() < 0.5
		var amount = randi_range(10, 40)  # Random amount between 10-40
		
		if is_healing:
			# Healing effect
			body.heal(amount)
			print("Random pickup healed player for ", amount, " HP!")
		else:
			# Damage effect
			body.take_damage(amount)
			print("Random pickup damaged player for ", amount, " HP!")
		
		# Remove the pickup after use
		queue_free()
		print("Random pickup consumed!")
