extends  Node3D
@export var Entity_scene: PackedScene
@export var pickable_scene: PackedScene
@export var spawn_offset: Vector3 = Vector3(0.9353, 1.529, 0.95)

var entities: Array[Node3D] = []

var keys = 0
var keys_spawned = 0
var can_spawn_key = false
var key_spawn_delay_counter = 0
var target_key_delay = 0
signal allkeys_complet

func _ready():
	var rob_signal = get_parent().get_node("Rob")
	if rob_signal:
		print("Connected to keys node signal")
		rob_signal.connect("signal_keys", Callable(self, "_on_keys_trigger"))
		
	var parent = get_parent().get_node("TrainSpawners")
	if parent:
		parent.connect("number_of_trains", Callable(self, "_on_trigger_spawn"))
	else:
		push_error("Parent not found!")

func _on_trigger_spawn(no_of_trains: int, spawn_pos: Vector3):
	if no_of_trains % 2 == 0:
		spawn_entity(spawn_pos)

func spawn_entity(spawn_pos: Vector3):
	if entities.size() >= 2:
		var oldest = entities.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var entity = Entity_scene.instantiate()
	add_child(entity)
	entity.global_position = spawn_pos + spawn_offset
	entity.global_rotation = Vector3.ZERO
	entities.append(entity)

	# Attempt to spawn key if allowed
	if can_spawn_key:
		key_spawn_delay_counter += 1
		if key_spawn_delay_counter >= target_key_delay and keys_spawned < 3:
			spawn_key_near_entity(entity)
			keys_spawned += 1
			can_spawn_key = false
			key_spawn_delay_counter = 0

func spawn_key_near_entity(entity: Node3D):
	var key = pickable_scene.instantiate()
	add_child(key)

	# Spawn near entity but slightly offset (randomize position)
	var offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	key.global_position = entity.global_position + offset
	print("Key spawned at: ", key.global_position)

func _on_keys_trigger(thekey: int):
	keys = thekey
	print("keys : ", keys)
	# Allow next key to spawn with random delay
	if keys < 3:
		can_spawn_key = true
		key_spawn_delay_counter = 0
		target_key_delay = randi_range(2, 5)
		print("Will spawn next key in ", target_key_delay, " train spawns.")
	else:
		emit_signal("allkeys_complet")
