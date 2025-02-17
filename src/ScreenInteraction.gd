extends Node3D

@export var screen_scene: PackedScene = preload("res://addons/godotbuddy/scene/GodotBuddyScene.tscn")
@onready var interactable_area: Area3D = $Area3D  # The interactable area

var screen_instance: Node = null
var is_screen_open: bool = false
var can_interact: bool = false


func _process(delta: float) -> void:
	if can_interact and Input.is_action_just_pressed("interact"):  # 'E' key or custom action
		interact()

# When the area is focused, the player or other body is in the interactable area
func _on_area_entered(area: Area3D) -> void:
	# If you need additional checks, you can do it here. This triggers when something enters the Area3D.
	can_interact = true

# When the area is unfocused, the player or other body exits the interactable area
func _on_area_exited(area: Area3D) -> void:
	can_interact = false

# Interact with the screen based on its current state (open/close)
func interact() -> void:
	if is_screen_open:
		close_screen()
	else:
		open_screen()

# Open the screen by instantiating the scene and adding it as a child
func open_screen() -> void:
	if not screen_scene:
		print("Error: No `screen_scene` assigned.")
		return
	screen_instance = screen_scene.instantiate()
	add_child(screen_instance)
	is_screen_open = true
	print("Screen opened.")

# Close the screen and free the instance
func close_screen() -> void:
	if screen_instance:
		screen_instance.queue_free()
		screen_instance = null
		is_screen_open = false
		print("Screen closed.")
