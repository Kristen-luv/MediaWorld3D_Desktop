extends Area3D

class_name Interactable

# Emitted when an Interactor starts looking at me.
signal focused(interactor: Interactor)
# Emitted when an Interactor stops looking at me.
signal unfocused(interactor: Interactor)
# Emitted when an Interactor interacts with me.
signal interacted(interactor: Interactor)

var is_interactable: bool = true  # Ensure the chest remains interactable even after interaction

# Function to handle interaction with the chest
func interact(interactor: Interactor) -> void:
	if is_interactable:
		# If the chest is interactable, perform the interaction
		emit_signal("interacted", interactor)
		# Logic for opening the chest or performing some other actions (e.g., animating the chest, etc.)
		# You can define what happens here when the chest is opened, without disabling interactability
		# Example logic for opening the chest:
		open_chest()
	
	# Ensure the chest remains interactable after interaction (do not disable is_interactable unless required)
	# is_interactable = true  # No need to reset unless you plan to disable interaction later

# Example function for opening the chest (modify as necessary)
func open_chest() -> void:
	# Your logic for opening the chest, such as playing an animation
	print("Chest opened!")
	# Optionally you can trigger other effects, such as unlocking loot, changing visuals, etc.
	# For example:
	# animation_player.play("open_animation")
