extends Node3D

var walk_run_blending: float = 0.0 : set = _set_walk_run_blending  # Blending for animations

# Roaming variables
@export var _force_loop: PackedStringArray
@export var roam_area: Vector3 = Vector3(10, 0, 10)  # Size of the roaming area
@export var move_speed: float = 2.0  # Movement speed
@export var idle_time_range: Vector2 = Vector2(2.0, 5.0)  # Random idle time between movements

# Node references
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _main_state_machine: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/StateMachine/playback")
@onready var _walk_run_blend_position: String = "parameters/StateMachine/Walk/blend_position"
@onready var face: Node = $SubViewport/GDbotFace  # Face node for expressions

# Roaming and state variables
var target_position: Vector3 = Vector3.ZERO  # Next position to move toward
var is_moving: bool = false  # Tracks if the bot is moving
var idle_timer: Timer = null  # Timer for idle duration

func _ready() -> void:
	# Initialize looping animations
	for animation_name in _force_loop:
		var anim: Animation = $gdbot/AnimationPlayer.get_animation(animation_name)
		anim.loop_mode = Animation.LOOP_LINEAR

	# Initialize idle timer
	idle_timer = Timer.new()
	add_child(idle_timer)
	idle_timer.connect("timeout", Callable(self, "_on_idle_timeout"))

	# Activate AnimationTree
	_animation_tree.active = true

	# Start roaming
	choose_new_target()

func _physics_process(delta: float) -> void:
	# Handle movement toward the target position
	if is_moving:
		var direction: Vector3 = (target_position - global_transform.origin).normalized()
		global_transform.origin += direction * move_speed * delta

		# Check if the bot has reached the target position
		if global_transform.origin.distance_to(target_position) < 0.5:
			is_moving = false
			idle()
			# Start the idle timer
			idle_timer.start(randf_range(idle_time_range.x, idle_time_range.y))

func choose_new_target() -> void:
	# Pick a random position within the roam area
	target_position = Vector3(
		randf() * roam_area.x * 2 - roam_area.x,
		global_transform.origin.y,  # Keep the Y-axis constant
		randf() * roam_area.z * 2 - roam_area.z
	)
	is_moving = true
	walk()

func _on_idle_timeout() -> void:
	# After idle time, pick a new target
	choose_new_target()

func _set_walk_run_blending(value: float) -> void:
	walk_run_blending = value
	_animation_tree.set(_walk_run_blend_position, walk_run_blending)

# Animation control functions
func idle() -> void:
	#print("Switching to Idle animation")
	_main_state_machine.travel("Idle")

func walk() -> void:
	#print("Switching to Walk animation")
	_main_state_machine.travel("Walk")

func jump() -> void:
	#print("Switching to Jump animation")
	_main_state_machine.travel("Jump")

func fall() -> void:
	#print("Switching to Fall animation")
	_main_state_machine.travel("Fall")

func set_face(face_name: String) -> void:
	if face.has_method("_set_face"):
		face._set_face(face_name)
	else:
		push_error("Face node does not have a method '_set_face'")
