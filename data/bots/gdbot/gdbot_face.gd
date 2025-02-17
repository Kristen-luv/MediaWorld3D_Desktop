extends Node2D

var _blinking: bool = false : set = _set_blinking  # Explicitly typed as bool
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _blinking_timer: Timer = $BlinkTimer
@onready var _closed_eyes_timer: Timer = $ClosedTimer
@onready var _left_eye: Sprite2D = $LeftEye
@onready var _right_eye: Sprite2D = $RightEye

var eyes_textures: Dictionary = {  # Explicitly typed as Dictionary
	"open": preload("./texture/parts/eye_open.png"),
	"closed": preload("./texture/parts/eye_close.png")
}

var current_face: String = "" : set = _set_face  # Explicitly typed as String

func _ready() -> void:  # Static return type added
	_blinking_timer.connect("timeout", _on_blink_timer_timeout)
	_set_blinking(true)
	current_face = "default"

func _set_blinking(value: bool) -> void:  # Static return type and parameter type added
	_blinking = value
	if _blinking:
		_blinking_timer.start()
	else:
		_blinking_timer.stop()

func _on_blink_timer_timeout() -> void:  # Static return type added
	# Play secondary action rather than blink
	if randf_range(0.0, 1.0) > 0.9:
		_animation_player.play("look_around")
		await _animation_player.animation_finished
	else:
		# Close eyes
		_set_eyes("closed")
		_closed_eyes_timer.start(randf_range(0.1, 0.25))
		await _closed_eyes_timer.timeout
	# Return to current eyes
	_set_eyes("open")
	if randf_range(0.0, 1.0) > 0.8:
		_blinking_timer.wait_time = randf_range(0.1, 0.15)
	else:
		_blinking_timer.wait_time = randf_range(1.0, 4.0)
	_blinking_timer.start()

func _set_eyes(eyes_name: String) -> void:  # Static return type and parameter type added
	_left_eye.texture = eyes_textures[eyes_name]
	_right_eye.texture = eyes_textures[eyes_name]

func _set_face(face_name: String) -> void:  # Static return type and parameter type added
	if current_face == face_name:
		return
	current_face = face_name
	_animation_player.play("RESET")
	_animation_player.seek(0.0, true)
	if face_name == "default":
		_set_blinking(true)
		return
	_set_blinking(false)
	if !_animation_player.has_animation(face_name as StringName):  # Convert face_name to StringName
		push_error("Can't set GDBot's face to: '" + face_name + "'")
		return
	_animation_player.play(face_name)
