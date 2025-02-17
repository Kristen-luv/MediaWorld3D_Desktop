extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Specify the type of the "astronaut" variable
	var astronaut: Node3D = $Path3D/PathFollow3D/Astronaut_BarbaraTheBee
	
	# Check if "astronaut" has the required properties or methods
	if astronaut.has_meta("moving"):
		astronaut.set("moving", true)  # Use the "set" function to set the property safely

	if astronaut.has_meta("move_speed"):
		astronaut.set("move_speed", 1.0)

func _physics_process(delta: float) -> void:
	const move_speed: float = 4.0
	$Path3D/PathFollow3D.progress += move_speed * delta
