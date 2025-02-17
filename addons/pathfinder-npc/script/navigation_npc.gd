extends CharacterBody3D

@export var NPC_SPEED: float = 1.0
@export var gravity: float = -9.8  # Gravity constant
@onready var navigation_agent_3d = $NavigationAgent3D
@onready var animation_tree = $Skeleton_Minion/AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var label_3d = $Skeleton_Minion/Label

# Variables for detecting if NPC is stuck
var last_position: Vector3
var stuck_timer: float = 0.0
var animation_timer: float = 0.0
var animation_delay: float = 5.0  # Delay between animations (5 seconds)
var stuck_threshold: float = 0.1  # Minimum distance to consider movement

func _ready() -> void:
	# Initialize AnimationTree and variables
	animation_tree.active = true
	animation_state.travel("idle")
	label_3d.visible = false  # Ensure the label is hidden initially
	last_position = global_position
	select_new_destination()

func _physics_process(delta: float) -> void:
	# Update timers
	stuck_timer += delta
	animation_timer += delta

	# Check if stuck
	if stuck_timer > 3.0:
		check_if_stuck()

	# Skip movement logic if animation delay is active
	if animation_timer < animation_delay:
		return

	# Movement logic
	var destination = navigation_agent_3d.get_next_path_position()
	var direction_to_destination = destination - global_position

	if direction_to_destination.length() > 0.1:
		var direction = direction_to_destination.normalized()
		velocity = direction * NPC_SPEED

		# Apply gravity
		if is_on_floor():
			velocity.y = 0  # Reset the vertical velocity when on the floor
		else:
			velocity.y += gravity * delta  # Apply gravity when in the air

		move_and_slide()  # Move the character and use the up vector for gravity

		# Smooth rotation
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

		# Play walk animation
		animation_state.travel("walk")
	else:
		# Idle animation when not moving
		animation_state.travel("idle")

	# Update last position after movement
	if global_position.distance_to(last_position) > stuck_threshold:
		last_position = global_position
		stuck_timer = 0.0  # Reset stuck timer if moved

func select_new_destination():
	# Select a random position as the new target
	var random_position = Vector3(randf_range(-25.0, 25.0), 0.0, randf_range(-25.0, 25.0))
	navigation_agent_3d.set_target_position(random_position)

func check_if_stuck():
	# Check if the NPC has moved significantly
	if global_position.distance_to(last_position) < stuck_threshold:
		#print("NPC is stuck. Changing direction...")
		velocity = Vector3.ZERO  # Stop movement
		animation_state.travel("idle")  # Play idle animation
		select_new_destination()  # Pick a new destination
		stuck_timer = 0.0  # Reset the stuck timer
	#else:
		#print("NPC is not stuck. Continuing...")

func _on_interactable_interacted(interactor: Node) -> void:
	animation_timer = 0.0
	animation_state.travel("interact")
	select_new_destination()

func _on_interactable_focused(interactor: Node) -> void:
	velocity = Vector3.ZERO
	animation_timer = 0.0
	animation_state.travel("taunt")
	
	# Show the label
	label_3d.visible = true

	# Rotate NPC to face the interactor
	var direction_to_interactor = (interactor.global_position - global_position).normalized()
	var target_rotation = atan2(direction_to_interactor.x, direction_to_interactor.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, 0.2)

func _on_interactable_unfocused(interactor: Node) -> void:
	select_new_destination()
	animation_timer = 0.0
	animation_state.travel("idle")
	
	# Hide the label
	label_3d.visible = false
