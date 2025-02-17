extends Node3D

# Variables
@export var info_text: String = "Press 'E' to interact."  # Initial prompt
@export var interacted_text: String = "Interaction completed!"  # Post-interaction message
@export var interact_key: String = "ui_accept"  # Interaction key (default 'E')
var player_nearby: bool = false  # Tracks if the player is near

# References to nodes
@onready var ui_label: Label = $Area3D/Control/InfoLabel
@onready var area: Area3D = $Area3D

func _ready() -> void:
	# Hide the label initially
	ui_label.visible = false

	# Connect signals for the Area3D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

# Signal callback: Called when the player enters the area
func _on_body_entered(body: Node) -> void:
	if body.name == "RigidPlayer":  # Adjust for your player's name
		player_nearby = true
		ui_label.text = info_text
		ui_label.visible = true

# Signal callback: Called when the player exits the area
func _on_body_exited(body: Node) -> void:
	if body.name == "RigidPlayer":
		player_nearby = false
		ui_label.visible = false

# Detect interaction key press
func _process(delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed(interact_key):
		interact()

# Function to handle interaction
func interact() -> void:
	print("Interaction triggered!")
	ui_label.text = interacted_text  # Update the label text
