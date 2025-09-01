extends CharacterBody3D
@onready var head: Node3D = $Head
@onready var standing_collision_shape: CollisionShape3D = $Standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $Crouching_collision_shape
@onready var above_head: RayCast3D = $Above_head
@onready var eyes: Node3D = $Head/Eyes
@onready var camera_3d: Camera3D = $Head/Eyes/Camera3D
@onready var pickup_ray: RayCast3D = $Head/Eyes/PickupRay
@onready var hold_point: Node3D = $Head/Eyes/HoldPoint

#rough
@onready var hand: Node3D = $Hand

@export var invert_y    : bool  = false 
var torch_model_positive_deg_y = 60;
var torch_model_negative_deg_y = 120;
var held_object: Node3D = null


@export var WALKING_SPEED = 5.0
@export var SPRINITING_SPEED = 7.0
@export var CROUCHIN_SPEED = 3.0
@export var JUMP_VELOCITY = 4.5
@export var mouse_sens = 0.4

#head bcal pitch offset
var keys  := 1

const head_bobing_walking_speed = 14.0
const head_bobing_sprinting_speed = 22.0
const head_bobing_crouching_speed = 10

const head_bobing_walking_intensity = 0.1
const head_bobing_crouching_intensity = 0.05
const head_bobing_sprinting_intensity = 0.2

var head_bobing_vector = Vector2.ZERO
var head_bobing_index = 0.0
var head_bobing_curr_intensity = 0.0
var head_y_axis := 0.0
var camera_x_axis := 0.0
var yaw_deg   : float = 0.0   
var pitch_deg : float = 0.0   

var tlook = true;
var current_speed = 5.0
var direction := Vector3.ZERO

var lerp_speed := 10.0
var crouching_depth = -0.5

# State
var sprinting = false
var walking = false
var crouching = false
var is_in_menu = true
signal signal_keys(key :int)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_deg   -= event.relative.x * mouse_sens
		pitch_deg += ( 1 if invert_y else -1) * event.relative.y * mouse_sens
		pitch_deg  = clamp(pitch_deg, -90, 90)  
	
		
		rotate_y(deg_to_rad(-event.relative.x*mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y*mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-50),deg_to_rad(78))
	if event is InputEventKey \
	and event.keycode == 4194305 \
	and event.pressed\
	and not event.echo:          
		tlook = !tlook

func _physics_process(delta: float) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if tlook else Input.MOUSE_MODE_VISIBLE 

	if Input.is_action_pressed("crouch"):
		current_speed = CROUCHIN_SPEED
		head.position.y = lerp(head.position.y,crouching_depth+1.4,delta*lerp_speed)
		crouching_collision_shape.disabled = false
		standing_collision_shape.disabled = true
		walking = false
		sprinting = false
		crouching = true
	elif !above_head.is_colliding():
		crouching_collision_shape.disabled = true
		standing_collision_shape.disabled = false
		head.position.y = lerp(head.position.y,1.4,delta*lerp_speed)
		if Input.is_action_pressed("sprint"):
			current_speed = SPRINITING_SPEED
			sprinting = true
			walking = false
			crouching = false
		else:
			current_speed = WALKING_SPEED
			sprinting = false
			walking = true
			crouching = false	
		
		
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if sprinting:
		head_bobing_curr_intensity = head_bobing_sprinting_intensity
		head_bobing_index += head_bobing_sprinting_speed*delta
	elif  walking :
		head_bobing_curr_intensity = head_bobing_walking_intensity
		head_bobing_index += head_bobing_walking_speed*delta
	elif crouching:
		head_bobing_curr_intensity = head_bobing_crouching_intensity
		head_bobing_index += head_bobing_crouching_speed*delta
		
	if is_on_floor() && input_dir != Vector2.ZERO:
		head_bobing_vector.y = sin(head_bobing_index)
		head_bobing_vector.x = sin(head_bobing_index/2)+0.5
		eyes.position.y = lerp(eyes.position.y,head_bobing_vector.y*(head_bobing_curr_intensity/2),delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,head_bobing_vector.x*head_bobing_curr_intensity,delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y,0.0,delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,0.0,delta*lerp_speed)

	if Input.is_action_pressed("back"):
		tlook = !tlook

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	if Input.is_action_just_pressed("interact"):
		if held_object:
			drop_object()
		else:
			try_pickup()
	move_and_slide()
	
func try_pickup():
	if pickup_ray.is_colliding():
		print("picable item")
		var collider = pickup_ray.get_collider()
		if collider is RigidBody3D and collider.is_in_group("pickable"):
			print("Picked up:", collider)
			held_object = collider
			held_object.freeze = true
			held_object.collision_layer = 2  # optional: move to a different layer
			held_object.get_parent().remove_child(held_object)
			hold_point.add_child(held_object)
			held_object.global_position = hold_point.global_position

func drop_object():
	if held_object:
		print("Dropped:", held_object)
		held_object.get_parent().remove_child(held_object)
		get_tree().root.add_child(held_object)
		held_object.global_position = hold_point.global_position
		held_object.freeze = false
		held_object.collision_layer = 1  # restore layer if needed
		held_object.queue_free()
		emit_signal("signal_keys",keys)
		var throw_dir = -pickup_ray.global_transform.basis.z.normalized()
		held_object.linear_velocity = throw_dir * 5.0
		keys += 1
		print(keys)
		
		held_object = null
