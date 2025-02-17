extends Interactor  # Inherits from Interactor

var cached_closest: Interactable

func _ready() -> void:
	if controller == null:
		print("Warning: No controller assigned.")
		# Optionally assign a default controller here or leave it empty for modularity.

func _physics_process(_delta: float) -> void:
	var new_closest: Interactable = get_closest_interactable()
	if new_closest != cached_closest:
		if is_instance_valid(cached_closest):
			unfocus(cached_closest)
		if new_closest:
			focus(new_closest)

		cached_closest = new_closest

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_instance_valid(cached_closest):
			interact(cached_closest)

func _on_area_exited(area: Interactable) -> void:
	if cached_closest == area:
		unfocus(area)
