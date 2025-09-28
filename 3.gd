extends Area2D

# Reference to the fridge boss
var fridge_boss: CharacterBody2D

func _ready() -> void:
	# Find the fridge boss when teleporter is ready
	fridge_boss = _find_fridge_boss()

func _find_fridge_boss() -> CharacterBody2D:
	# Search for fridge boss in the scene
	for node in get_tree().current_scene.get_children():
		if node is CharacterBody2D and node.has_method('take_damage') and not node.has_method('get_health_percentage'):
			# Check if it has boss-level health (200 HP)
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
			if child.has_method('get') and child.get('health') != null and child.get('health') >= 150:
				return child
		var found = _find_fridge_recursive(child)
		if found:
			return found
	return null

func _on_body_entered(body: Node2D) -> void:
	print("Teleporter detected body: ", body.name, " Type: ", body.get_class())
	
	if body.name == "Player" or _is_kai(body):
		print("Valid character detected for teleportation!")
		# Check if fridge boss is dead before allowing teleportation
		if _is_fridge_dead():
			# Heal to full HP before teleportation (following teleporter standard)
			_heal_character_to_full(body)
			
			# Teleport the character
			body.global_position = $tp.global_position
			
			if body.name == "Player":
				print("Player teleported and healed to full HP! Fridge boss defeated.")
			else:
				print("Kai teleported and healed to full HP! Following player.")
		else:
			if body.name == "Player":
				print("Teleporter locked! Defeat the Fridge boss first.")
			else:
				print("Kai cannot use teleporter yet! Fridge boss must be defeated first.")
	else:
		print("Body not recognized as valid teleporter user")

func _is_fridge_dead() -> bool:
	# If we never found a fridge, consider it "dead" (allows teleport)
	if not fridge_boss:
		return true
	
	# If fridge reference is no longer valid, it's dead
	if not is_instance_valid(fridge_boss):
		return true
	
	# If fridge health is 0 or below, it's dead
	if fridge_boss.has_method('get') and fridge_boss.get('health') != null:
		return fridge_boss.get('health') <= 0
	
	# Default to locked if we can't determine health
	return false

func _is_kai(body: Node2D) -> bool:
	# Check if this is Kai companion - multiple detection methods
	print("Checking if body is Kai: ", body.name)
	
	# Method 1: Check group membership
	if body.is_in_group("kai"):
		print("Kai detected by group membership")
		return true
	
	# Method 2: Check name
	if body.name.to_lower().contains("kai"):
		print("Kai detected by name")
		return true
	
	# Method 3: Check specific health value (150 max health)
	if body.has_method('get') and body.get('max_health') == 150:
		print("Kai detected by max health (150)")
		return true
	
	# Method 4: Check if it's a CharacterBody2D with companion-like properties
	if body is CharacterBody2D and body.has_method('heal') and body != null:
		# Check if it has typical companion properties
		if body.has_method('get') and body.get('attack_damage') == 30:
			print("Kai detected by companion properties")
			return true
	
	print("Body is not Kai")
	return false

func _heal_character_to_full(character: Node2D) -> void:
	# Heal character to full HP (following teleporter healing standard)
	if character.has_method('heal') and character.has_method('get'):
		var current_health = character.get('current_health')
		var max_health = character.get('max_health')
		
		if current_health != null and max_health != null:
			if current_health < max_health:
				var heal_amount = max_health - current_health
				character.heal(heal_amount)
				print("Teleporter healed ", character.name if character.name != "" else "character", " for ", heal_amount, " HP!")
			else:
				print("Character already at full health.")
