extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player = get_node("../Rob") # Replace with correct path
@onready var shaitan_noise_occasion: AudioStreamPlayer3D = $AudioStreamPlayer3D
signal vimal
@export var speed: float = 6.9
@export var update_distance: float = 1.0

var last_player_pos: Vector3

func _ready():
	last_player_pos = player.global_position
	nav_agent.target_position = last_player_pos
func _physics_process(delta: float) -> void:
	# Update target if player moved far enough
	if player.global_position.distance_to(last_player_pos) > update_distance:
		last_player_pos = player.global_position
		nav_agent.target_position = last_player_pos

	# Always face player
	rotate_toward_player()


	# --- Navigation Movement ---
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
	else:
		var destination = nav_agent.get_next_path_position()
		if global_position.distance_to(destination) > 0.1:
			var direction = (destination - global_position).normalized()
			velocity = direction * speed
		else:
			velocity = Vector3.ZERO
	
	move_and_slide()

func rotate_toward_player():
	var to_player = player.global_position - global_position
	to_player.y = 0 
	to_player = to_player.normalized()

	# Rotate 90° towards player direction
	var desired_angle = atan2(to_player.x, to_player.z)
	var current_angle = rotation.y
	var angle_diff = wrapf(desired_angle - current_angle, -PI, PI)
	
	# Snap rotation to 90° steps
	var snap_angle = PI /2
	var snapped_angle = round(desired_angle / snap_angle) * snap_angle

	rotation.y = snapped_angle


func _on_timer_timeout() -> void:
	shaitan_noise_occasion.play()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body and body.is_in_group('player'):
		get_tree().change_scene_to_file('res://boooo.tscn')
