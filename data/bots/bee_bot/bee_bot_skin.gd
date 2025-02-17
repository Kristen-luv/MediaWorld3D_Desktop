extends Node3D

# Set loop on some animation
@export var _force_loop : PackedStringArray
@export var roam_area: Vector3 = Vector3(10, 0, 10)  # Size of the roaming area
@export var move_speed: float = 2.0  # Movement speed

@onready var _animation_tree : AnimationTree = $AnimationTree
@onready var _main_state_machine : AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/StateMachine/playback")
@onready var _secondary_action_timer : Timer = $SecondaryActionTimer

var target_position: Vector3  # The next position to move toward
var is_moving: bool = false  # To track the movement state

func _ready() -> void:
	# Set loop for specific animations
	for animation_name in _force_loop:
		var anim : Animation = $bee_bot/AnimationPlayer.get_animation(animation_name)
		anim.loop_mode = Animation.LOOP_LINEAR

	# Set the initial target position
	choose_new_target()
	idle()

func _physics_process(delta: float) -> void:
	# Move toward the target position
	if is_moving:
		var direction: Vector3 = (target_position - global_transform.origin).normalized()
		global_transform.origin += direction * move_speed * delta

		# Check if the bot is close to the target position
		if global_transform.origin.distance_to(target_position) < 0.5:
			is_moving = false
			idle()
			choose_new_target()

func choose_new_target() -> void:
	# Choose a random position within the roam area
	target_position = Vector3(
		randf() * roam_area.x * 2 - roam_area.x,
		global_transform.origin.y,  # Keep the Y-axis constant
		randf() * roam_area.z * 2 - roam_area.z
	)
	is_moving = true
	#walk()

func _on_secondary_action_timer_timeout() -> void:
	# Trigger a secondary action only if in Idle state
	if _main_state_machine.get_current_node() != "Idle": return
	_main_state_machine.travel("HeadMovement")
	_secondary_action_timer.start(randf_range(3.0, 8.0))

# Animation control functions
func idle() -> void:
	_main_state_machine.travel("Idle")
	_secondary_action_timer.start()
#
#func walk() -> void:
	#_main_state_machine.travel("Walk")

func attack() -> void:
	_main_state_machine.travel("Attack")

func power_off() -> void:
	_main_state_machine.travel("PowerOff")
	_secondary_action_timer.stop()
