extends Node3D

signal foot_step

@export var gobot_model: MeshInstance3D
@export var blink: bool = true : set = set_blink
@export var left_eye_mat_override: String
@export var right_eye_mat_override: String
@export var open_eye: CompressedTexture2D
@export var close_eye: CompressedTexture2D

@export var roam_area: Vector3 = Vector3(10, 0, 10)  # Size of the roaming area
@export var move_speed: float = 2.0  # Movement speed
@export var idle_time_range: Vector2 = Vector2(2.0, 5.0)  # Random idle time between movements

var current_move_speed: float = 0.0 : set = set_move_speed

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var move_blend_path: String = "parameters/StateMachine/Move/blend_position"
@onready var flip_shot_path: String = "parameters/FlipShot/request"
@onready var hurt_shot_path: String = "parameters/HurtShot/request"

@onready var blink_timer: Timer = $BlinkTimer
@onready var closed_eyes_timer: Timer = $ClosedEyesTimer
@onready var left_eye_mat: StandardMaterial3D = null
@onready var right_eye_mat: StandardMaterial3D = null

# Roaming variables
var target_position: Vector3 = Vector3.ZERO  # The next position to move toward
var is_moving: bool = false  # To track if the bot is moving
var idle_timer: Timer = null  # Timer for idle duration

func _ready() -> void:
	# Ensure the gobot_model is valid
	if gobot_model:
		left_eye_mat = gobot_model.get(left_eye_mat_override)
		right_eye_mat = gobot_model.get(right_eye_mat_override)
	else:
		push_error("Gobot model is not assigned or is null!")

	# Ensure timers are valid before connecting
	if blink_timer:
		blink_timer.connect("timeout", self._on_blink_timeout)
	else:
		push_error("BlinkTimer is not properly initialized!")

	if closed_eyes_timer:
		closed_eyes_timer.connect("timeout", self._on_closed_eyes_timeout)
	else:
		push_error("ClosedEyesTimer is not properly initialized!")

	# Initialize idle timer
	idle_timer = Timer.new()
	add_child(idle_timer)
	idle_timer.connect("timeout", self._on_idle_timeout)

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
	move()

func _on_idle_timeout() -> void:
	# After idle time, pick a new target
	choose_new_target()

func _on_blink_timeout() -> void:
	if left_eye_mat and right_eye_mat:
		# Close eyes
		left_eye_mat.albedo_texture = close_eye
		right_eye_mat.albedo_texture = close_eye
		if closed_eyes_timer:
			closed_eyes_timer.start(0.2)

func _on_closed_eyes_timeout() -> void:
	if left_eye_mat and right_eye_mat:
		# Open eyes
		left_eye_mat.albedo_texture = open_eye
		right_eye_mat.albedo_texture = open_eye
		if blink_timer:
			blink_timer.start(randf_range(1.0, 8.0))

func set_blink(state: bool) -> void:
	if blink == state:
		return
	blink = state
	if blink:
		if blink_timer:
			blink_timer.start(0.2)
	else:
		if blink_timer:
			blink_timer.stop()
		if closed_eyes_timer:
			closed_eyes_timer.stop()

func set_move_speed(value: float) -> void:
	current_move_speed = clamp(value, 0.0, 1.0)
	animation_tree.set(move_blend_path, current_move_speed)

# Animation control functions
func idle() -> void:
	state_machine.travel("Idle")

func move() -> void:
	state_machine.travel("Move")

func fall() -> void:
	state_machine.travel("Fall")

func jump() -> void:
	state_machine.travel("Jump")

func edge_grab() -> void:
	state_machine.travel("EdgeGrab")

func wall_slide() -> void:
	state_machine.travel("WallSlide")

func flip() -> void:
	animation_tree.set(flip_shot_path, true)

func victory_sign() -> void:
	state_machine.travel("VictorySign")

func hurt() -> void:
	animation_tree.set(hurt_shot_path, true)
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.2)
