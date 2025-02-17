extends Node3D


var do_greet: bool = false
var do_vow: bool = false
var walking: bool = true
var walking_speed: float = 1.0
var direction: Vector3 = Vector3(0, 0, 1) 
var change_direction_interval: float = 3.0 
var time_since_last_change: float = 0.0
var animation_timer: float = 0.0
var current_animation: String = "walk"
var playAnimation : String = "dwarf-idle"

func _ready() -> void:
	randomize() # Ensure different random results each time
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$TextEdit.gui_input.connect(_on_text_edit_gui_input)

func _process(delta: float) -> void:
	time_since_last_change += delta
	animation_timer += delta
	
	# Change direction at intervals
	if time_since_last_change >= change_direction_interval:
		time_since_last_change = 0.0
		randomize_direction()
	if animation_timer > 10: 
		animation_timer = 0
		switch_animations()
	if walking:
		if current_animation == 'walk':
			position += direction * (walking_speed * delta)
			rotate_to_direction()
		$AnimationPlayer.play(current_animation)
	else :
		$AnimationPlayer.play(playAnimation)

# Generate a new random direction
func randomize_direction() -> void:
	var angle: float = randf() * TAU 
	direction = Vector3(cos(angle), 0.0, sin(angle)).normalized()

# Rotate the player to face the direction of movement
func rotate_to_direction() -> void:
	if direction.length() > 0.01:
		var target_rotation: Vector3 = Vector3(0, atan2(direction.x, direction.z), 0)
		rotation.y = lerp_angle(rotation.y, target_rotation.y, 0.1) 

func switch_animations() -> void:
	var animations : Array = ["walk", "looking"]
	current_animation = animations[randi() % animations.size()]
	#print("Switched animation to: ", current_animation)

func _on_area_3d_body_entered(body: Node3D) -> void:
	$Label3D.visible = true
	print("you've entered the bot's area..")
	playAnimation = 'bow'
	walking = false

func _on_area_3d_body_exited(body: Node3D) -> void:
	print("you've left the bot's area..")
	$Label3D.visible = false
	$TextEdit.visible = false
	$RichTextLabel.visible = false
	playAnimation = "dwarf-idle"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ask"):
		print('q button pressed')
		if $Label3D.visible:
			$Label3D.visible = false
			$TextEdit.visible = true
			$TextEdit.grab_focus()
			Global.is_typing = true
			playAnimation = 'dwarf-idle'
			
			
		if event.is_action_pressed('exit-chat'):
			print('exit-chat has been pressed')
			Global.is_typing = false
			$TextEdit.text = ""
			$TextEdit.visible = false

func _on_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			print('chat submitted while typing')
			handle_submit()

func handle_submit() -> void:
	print('the enter button from handle clicked')
	$RichTextLabel.visible = true
	$TextEdit.visible = false
	getAnswer(str($TextEdit.text))
	$TextEdit.text = ""
	
func getAnswer(text: String) -> void:
	# Prepare request data (no authorization required)
	var url: String = "https://flowise-2-0.onrender.com/api/v1/prediction/9f1781bd-ad88-42a8-8baf-554a0e7b1ac9"
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	var body: Dictionary = {
		"question": text
	}
	if text == "can you dance?":
		playAnimation = 'hip-hop'
		$RichTextLabel.text = ''
		return 
	else:
		# Send the HTTP request
		$HTTPRequest.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		playAnimation = 'think'
		var response_str: String = body.get_string_from_utf8()
		var response_data: Variant = JSON.parse_string(response_str)
		if response_data is Dictionary and response_data.has("text"):
			var ai_response: String = response_data["text"]
			$RichTextLabel.text = ai_response
		else:
			# Show error message in case of failure
			$RichTextLabel.push_color(Color.DARK_RED)
			$RichTextLabel.append_text("\n\n---\n\n[u]Error:[/u] Failed to parse response.")
			$RichTextLabel.pop()
		$TextEdit.visible = true
		$TextEdit.grab_focus()

func _on_greeting_area_body_entered(body: Node3D) -> void:
	playAnimation = 'over-here'
	walking = false

func _on_greeting_area_body_exited(body: Node3D) -> void:
	playAnimation = 'looking'
	walking = true
