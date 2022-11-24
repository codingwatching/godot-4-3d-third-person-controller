extends RigidBody3D

const COIN_SCENE := preload("res://Coin/Coin.tscn")

@export var coins_count := 5
@export var stopping_distance := 0.0

@onready var _reaction_animation_player: AnimationPlayer = $ReactionLabel/AnimationPlayer
@onready var _detection_area: Area3D = $PlayerDetectionArea
@onready var _beetle_skin: Node3D = $BeetleRoot
@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _death_collision_shape: CollisionShape3D = $DeathCollisionShape

@onready var _target: Node3D = null
@onready var _alive: bool = true


func _ready() -> void:
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)
	_beetle_skin.play_idle()


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	
	if _target != null:
		_beetle_skin.play_walk()
		look_at(Vector3(_target.global_position.x, global_position.y, _target.global_position.z))
		
		_navigation_agent.set_target_location(_target.global_position)
		
		var next_location := _navigation_agent.get_next_location()
		
		if not _navigation_agent.is_target_reached():
			var direction := (next_location - global_position)
			direction.y = 0
			direction = direction.normalized()
			
			var collision := move_and_collide(direction * delta * 3)
			if collision:
				var collider := collision.get_collider()
				if collider is Player:
					var impact_point: Vector3 = global_position - collider.global_position
					var force := -impact_point
					# Throws player up a little bit
					force.y = 0.5
					force *= 10.0
					collider.damage(impact_point, force)
					_beetle_skin.play_attack()
	else:
		_beetle_skin.play_idle()


func damage(impact_point: Vector3, force: Vector3) -> void:
	lock_rotation = false
	force = force.limit_length(3.0)
	apply_impulse(force, impact_point)

	if not _alive:
		return
	
	_alive = false
	_beetle_skin.play_poweroff()
	
	for i in range(coins_count):
		var coin := COIN_SCENE.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
		coin.spawn()
	_detection_area.body_entered.disconnect(_on_body_entered)
	_detection_area.body_exited.disconnect(_on_body_exited)
	_target = null
	_death_collision_shape.set_deferred("disabled", false)
	
	set_deferred("collision_layer", 2)
	set_deferred("collision_mask", 2)
	
	axis_lock_angular_x = false
	axis_lock_angular_y = false
	axis_lock_angular_z = false
	
	gravity_scale = 1.0


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		_target = body
		_reaction_animation_player.play("found_player")


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		_target = null
		_reaction_animation_player.play("lost_player")
