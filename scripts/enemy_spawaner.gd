extends Node3D

@export var entity_scene: PackedScene
@export var player_path: NodePath 
@export var spawn_offset: Vector3 = Vector3(0, 0, 50) 
@export var no_of_trains_spawned_needed := 10
var last_entity: Node3D = null 
var last_player_z := 0.0
var last_spawn_dir := 0
func _ready():
	var parent = get_parent().get_node("TrainSpawners")
	
	if parent:
		print("Connected to parent signal")
		parent.connect("number_of_trains", Callable(self, "_on_trigger_spawn"))
		
	else:
		push_error("TrainSpawners not found!")
func _process(delta: float) -> void:
	pass
	
func _on_trigger_spawn(train_count: int, _spawn_pos: Vector3):
	print("Train count:", train_count)
	if train_count == no_of_trains_spawned_needed:
		spawn_near_player()

func spawn_near_player():
	if last_entity and is_instance_valid(last_entity):
		last_entity.queue_free()
	var player = get_node_or_null(player_path)
	var player_z = player.global_position.z
	var dir = sign(player_z - last_player_z)

	if dir != 0 and dir != last_spawn_dir:
		handle_direction_change(dir)
	last_spawn_dir = dir
	last_player_z = player_z

	if not player:
		push_error("Player node not found!")
		return
	if not entity_scene:
		push_error("Entity scene not assigned!")
		return
	var spawn_pos = player.global_position + spawn_offset
	var entity = entity_scene.instantiate()
	get_tree().current_scene.add_child(entity)
	entity.global_position = spawn_pos
	last_entity = entity
	

func handle_direction_change(dir :int):
	if dir == -1:
		spawn_offset = Vector3(0,0,50)

	elif dir == 1:
		spawn_offset = Vector3(0,0,-50)
