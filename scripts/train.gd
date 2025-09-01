extends Node3D

var TRAIN_SCENE = preload("res://scene/train.tscn")
var PICKABLE_SCENE = preload("res://scene/testScenes/pickable_test.tscn")
signal number_of_trains(no_of_trains: int, spawn_pos: Vector3)
@onready var player: Node3D = null
@export var train_length: float = 40.0
@export var max_trains: int = 3
var trains: Array[Node3D] = []
var base_x: float
var base_y: float
var last_player_z := 0.0
var last_spawn_dir := 0 # 1 = forward, -1 = back, 0 = idle 
var no_of_trains := 0 
var FINAL_TRAIN_SCENE = preload("res://scene/final_train_scene.tscn")
var special_train_pending := false


func _ready():
	var all_keys = get_parent().get_node_or_null("EntitySpawaner")
	if all_keys:
		all_keys.connect("allkeys_complet", Callable(self,"_all_keys_found"))
	else:
		push_error("❌ EntitySpawaner not found in parent!")

	player = get_parent().get_node_or_null("Rob")
	if player == null:
		push_error("Player node 'Rob' not found. Check your scene tree!")
		return
	base_x = player.global_position.x + 2
	base_y = player.global_position.y -1.402
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
	if player_z < last_train_z - (train_length *0.2) and trains.size() < max_trains:
		spawn_train_after()
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
	no_of_trains += 1
	var train: Node3D

	if special_train_pending:
		train = FINAL_TRAIN_SCENE.instantiate()
		special_train_pending = false
		print("🚂 Special train spawned!")
	else:
		train = TRAIN_SCENE.instantiate()
	get_parent().add_child(train)
	# Fixed X/Y, only Z changes
	var spawn_pos = Vector3(base_x, base_y, z_pos)
	train.global_position = spawn_pos
	emit_signal("number_of_trains", no_of_trains, spawn_pos)
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
			
func _all_keys_found():
	print("all keys found")
	special_train_pending = true
