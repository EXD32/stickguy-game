extends CharacterBody2D

# Fireball projectile properties
var direction: Vector2 = Vector2.ZERO
var speed: float = 300.0
var damage: int = 20
var lifetime: float = 5.0
var has_hit: bool = false

func _ready() -> void:
	# Set up visual appearance
	var sprite: ColorRect = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.color = Color(1.0, 0.4, 0.0)  # Orange fireball color
	add_child(sprite)
	
	# Set up collision
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	add_child(collision)
	
	# Add metadata to identify as enemy bullet
	set_meta("bullet_type", "enemy")
	set_meta("damage", damage)
	
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)
	
	print("Fireball projectile created!")

func set_direction_and_speed(dir: Vector2, spd: float = 300.0) -> void:
	direction = dir.normalized()
	speed = spd

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	
	# Move in the set direction
	velocity = direction * speed
	
	# Check for collisions before moving
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider and collider.has_method('take_damage') and collider.name == "Player":
			has_hit = true
			collider.take_damage(damage)
			print("Fireball hit player for ", damage, " damage!")
			queue_free()
		else:
			# Hit something else (wall, etc.)
			print("Fireball hit obstacle")
			queue_free()

func _on_lifetime_expired() -> void:
	if is_instance_valid(self):
		print("Fireball expired after ", lifetime, " seconds")
		queue_free()
