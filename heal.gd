extends Area2D

# Healing properties
var heal_amount: int = 20
var is_consumed: bool = false

func _ready() -> void:
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	print("Heal pickup ready!")

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player and pickup hasn't been consumed
	if body.name == "Player" and not is_consumed:
		# Check if player has healing method and current health
		if body.has_method('heal') and body.has_method('get'):
			var current_hp = body.get('current_health')
			var max_hp = body.get('max_health')
			
			if current_hp != null and max_hp != null:
				# Only heal if player is not at full health
				if current_hp < max_hp:
					# Calculate actual heal amount (don't overheal)
					var actual_heal = min(heal_amount, max_hp - current_hp)
					body.heal(actual_heal)
					print("Player healed for ", actual_heal, " HP!")
					_consume_pickup()
				else:
					print("Player already at full health!")
			else:
				print("Could not access player health!")
		else:
			print("Player does not have heal method!")

func _consume_pickup() -> void:
	# Mark as consumed and remove from scene
	is_consumed = true
	print("Heal pickup consumed!")
	# Optional: Add visual/audio effect here before destroying
	queue_free()
