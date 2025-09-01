extends Node3D

@onready var player = get_node_or_null("../Rob")
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

@export var spawn_offset: Vector3 = Vector3(0, 0, 3)
@export var move_speed: float = 5.0

func _ready() -> void:
	if player and nav_agent:
		nav_agent.target_position = player.global_position + spawn_offset
	else:
		push_warning("Missing player or nav agent!")

func _process(delta: float) -> void:
	if player and nav_agent:
		nav_agent.target_position = player.global_position + spawn_offset

		# Move towards the next point in the path
		if nav_agent.is_navigation_finished() == false:
			var next_position = nav_agent.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			global_position += direction * move_speed * delta
