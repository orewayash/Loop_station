extends Node3D

const TRAIN_SCENE = preload("res://scene/train.tscn")

@onready var player: Node3D = null

var train_length: float = 40.0
var max_trains: int = 3
var trains: Array[Node3D] = []
var base_x: float
var base_y: float
var last_player_z := 0.0
var last_spawn_dir := 0  # 1 = forward, -1 = back, 0 = idle

func _ready():

	player = get_parent().get_node_or_null("Rob")
	if player == null:
		push_error("Player node 'Rob' not found. Check your scene tree!")
		return
	base_x = player.global_position.x + 2
	base_y = player.global_position.y -1.402
	# Start with one train at player position
	spawn_train_at(player.global_position.z)

func _process(delta):
	if player == null or trains.is_empty():
		return

	var player_z = player.global_position.z
	var first_train_z = trains[0].global_position.z
	var last_train_z = trains[-1].global_position.z
	var dir = sign(player_z - last_player_z)

	if dir != 0 and dir != last_spawn_dir:
		handle_direction_change(dir)

	last_spawn_dir = dir
	last_player_z = player_z
	# Spawn train ahead if player crosses front train’s midpoint
	if player_z < last_train_z - (train_length *0.2) and trains.size() < max_trains:
		spawn_train_after()

	# Spawn train behind if player crosses back train’s midpoint
	elif player_z > first_train_z + (train_length *0.2) and trains.size() < max_trains:
		spawn_train_before()

	
	if trains.size() >= max_trains:
		if player_z < last_train_z:      
			var removed = trains.pop_front()
			removed.queue_free()
		else:
			var removed = trains.pop_back()
			removed.queue_free()

func spawn_train_after():
	var last_train = trains[-1]
	var new_z = last_train.global_position.z - train_length
	spawn_train_at(new_z, true)

func spawn_train_before():
	var first_train = trains[0]
	var new_z = first_train.global_position.z + train_length
	spawn_train_at(new_z, false)

func spawn_train_at(z_pos: float, append_to_end := true):
	var train = TRAIN_SCENE.instantiate()
	get_parent().add_child(train)

	# Fixed X/Y, only Z changes
	var spawn_pos = Vector3(base_x, base_y, z_pos)
	train.global_position = spawn_pos

	if append_to_end:
		trains.append(train)
	else:
		trains.insert(0, train)

func remove_farthest_train():
	var player_z = player.global_position.z
	var first_train = trains[0]
	var last_train = trains[-1]

	if abs(player_z - first_train.global_position.z) > abs(player_z - last_train.global_position.z):
		var removed = trains.pop_front()
		removed.queue_free()
	else:
		var removed = trains.pop_back()
		removed.queue_free()
func handle_direction_change(dir: int):
	if dir == -1:
		var first_train_z = trains[0].global_position.z
		if player.global_position.z > first_train_z + train_length:
			spawn_train_before()

	elif dir == 1:
		var last_train_z = trains[-1].global_position.z
		if player.global_position.z < last_train_z - train_length:
			spawn_train_after()
