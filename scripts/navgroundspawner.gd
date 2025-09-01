
extends  Node3D
@export var Entity_scene: PackedScene
@export var pickable_scene : PackedScene
@export var spawn_offset: Vector3 = Vector3(0.9353, 0, 0.95)
var entities: Array[Node3D] = []  # Holds up to 3 spawned entities
var keys
func _ready():
	var parent = get_parent().get_node("TrainSpawners")
	if parent:
		parent.connect("number_of_trains", Callable(self, "_on_trigger_spawn"))
	else:
		push_error("Parent not found!")

func _on_trigger_spawn(no_of_trains: int, spawn_pos: Vector3):
	if no_of_trains % 1 == 0:
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
	
