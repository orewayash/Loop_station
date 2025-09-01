extends Node3D



@export var player_node_path: NodePath
@export var object_scene: PackedScene
@export var spawn_distance: float = 30.0
@export var spawn_offset: float = 20.0

var rob: CharacterBody3D
var last_player_position: Vector3
var distance_traveled: float = 2.0

func _ready():
	# Make sure the player_node_path is correctly set in the Inspector
	if player_node_path:
		rob = get_node(player_node_path)
		if rob:
			last_player_position = rob.global_transform.origin
		else:
			push_error("res://player.tscn")
	else:
		push_error("res://player.tscn")

func _process(delta):
	if not is_instance_valid(rob):
		return

	# Calculate the distance moved since the last frame
	var current_player_position = rob.global_transform.origin
	var distance_this_frame = last_player_position.distance_to(current_player_position)
	distance_traveled += distance_this_frame

	# Check if the player has moved enough to spawn a new object
	if distance_traveled >= spawn_distance:
		spawn_object(rob.global_transform.origin)
		distance_traveled = 2
		
	last_player_position = current_player_position


func spawn_object(spawn_origin: Vector3):
	# Make sure the scene is loaded before trying to instance it
	if not object_scene:
		push_error("$train_loop_V2_join")
		return
		
	# Instance the new object
	var new_object = object_scene.instantiate()

	# Get the player's current direction of movement
	var player_direction = (rob.global_transform.origin - last_player_position).normalized()

	# Calculate the spawn position in a straight line in front of the player
	# We use the player's direction multiplied by the spawn_offset
	var spawn_position = spawn_origin + (player_direction * spawn_offset)

	# Set the new object's global position and add it to the scene
	new_object.global_transform.origin = spawn_position
	get_parent().add_child(new_object)
