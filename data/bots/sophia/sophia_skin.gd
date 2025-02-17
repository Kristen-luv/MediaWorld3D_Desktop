extends Node3D

@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _main_state_machine: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback

func _ready() -> void:
	# Set the animation state to idle
	idle()

func idle() -> void:
	_main_state_machine.travel("Idle")
