extends Node3D

const TRAIN_SCENE = preload("res://train.tscn")

@onready var player: Node3D = null

var train_length: float = 20.0
var max_trains: int = 3
var trains: Array[Node3D] = []
var base_x: float
var base_y: float


func _ready():
	base_x = player.global_position.x
	base_y = player.global_position.y
	spawn_train_at(player.global_position.z)

	player = get_parent().get_node_or_null("Rob")
	if player == null:
		push_error("Player node 'Rob' not found. Check your scene tree!")
		return

	# Start with one train at player position
	spawn_train_at(player.global_position.z)

func _process(delta):
	if player == null or trains.is_empty():
		return

	var player_z = player.global_position.z
	var first_train_z = trains[0].global_position.z
	var last_train_z = trains[-1].global_position.z

	# Spawn train ahead if player crosses front train’s midpoint
	if player_z < last_train_z - (train_length / 2) and trains.size() < max_trains:
		spawn_train_after()

	# Spawn train behind if player crosses back train’s midpoint
	elif player_z > first_train_z + (train_length / 2) and trains.size() < max_trains:
		spawn_train_before()

	# Keep train count within limit
	while trains.size() > max_trains:
		remove_farthest_train()

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
