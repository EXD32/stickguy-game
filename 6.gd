extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("Teleporter detected body: ", body.name, " Type: ", body.get_class())
	
	if body.name == "Player" or _is_kai(body):
		print("Valid character detected for teleportation!")
		
		# Heal to full HP before teleportation (following teleporter standard)
		_heal_character_to_full(body)
		
		# Teleport the character
		body.global_position = $tp.global_position
		
		if body.name == "Player":
			print("Player teleported and healed to full HP!")
		else:
			print("Kai teleported and healed to full HP! Following player.")
	else:
		print("Body not recognized as valid teleporter user")

func _is_kai(body: Node2D) -> bool:
	# Check if this is Kai companion - multiple detection methods
	if body == null:
		return false
	
	# Method 1: Check group membership
	if body.is_in_group("kai"):
		return true
	
	# Method 2: Check name
	if body.name.to_lower().contains("kai"):
		return true
	
	# Method 3: Check specific health value (150 max health)
	if body.has_method('get') and body.get('max_health') == 150:
		return true
	
	# Method 4: Check if it's a CharacterBody2D with companion-like properties
	if body is CharacterBody2D and body.has_method('heal'):
		if body.has_method('get') and body.get('attack_damage') == 30:
			return true
	
	return false

func _heal_character_to_full(character: Node2D) -> void:
	# Heal character to full HP (following teleporter healing standard)
	if character.has_method('heal') and character.has_method('get'):
		var current_health = character.get('health')
		var max_health = character.get('max_health')
		
		if current_health != null and max_health != null:
			if current_health < max_health:
				var heal_amount = max_health - current_health
				character.heal(heal_amount)
				print("Teleporter healed ", character.name if character.name != "" else "character", " for ", heal_amount, " HP!")
			else:
				print("Character already at full health.")
