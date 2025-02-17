extends Control

# For running server commands.
@onready var scroll_box : ScrollContainer = $VBoxContainer/ScrollContainer
@onready var chat_list : Control = $VBoxContainer/ScrollContainer/ChatList
@onready var line_edit : LineEdit = $VBoxContainer/LineEdit
@onready var chat_entry : PackedScene = preload("res://data/scene/ui/ChatEntry.tscn")
@onready var godot_buddy_scene : PackedScene = preload("res://addons/godotbuddy/scene/GodotBuddyScene.tscn")
var tween : Tween = null
var chat_last_opened_time : int = 0
var godot_buddy_instance : Node = null

# State variables for mode tracking
var is_chat_mode : bool = true
var is_ai_mode : bool = false

# Timer to reset mouse mode
var reset_mouse_timer : Timer = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_edit.connect("text_submitted", _on_chat_submitted)
	line_edit.connect("focus_entered", _on_line_edit_focus_entered)
	line_edit.connect("focus_exited", _on_line_edit_focus_exited)
	CommandHandler.connect("command_response", _on_command_response)

	# Initialize timer for resetting mouse mode
	reset_mouse_timer = Timer.new()
	add_child(reset_mouse_timer)
	reset_mouse_timer.one_shot = true
	reset_mouse_timer.wait_time = 5.0 # Adjust the timeout duration as needed
	reset_mouse_timer.connect("timeout", _reset_mouse_mode)

# Check if we are in chat mode
func is_in_chat_mode() -> bool:
	return is_chat_mode

# Check if we are in AI mode
func is_in_ai_mode() -> bool:
	return is_ai_mode

# Show chat when the LineEdit gets focus
func _on_line_edit_focus_entered() -> void:
	chat_last_opened_time = Time.get_ticks_msec()
	if Global.get_player() != null:
		Global.get_player().locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if tween:
		tween.kill()
		tween = null
	for entry in chat_list.get_children():
		entry.visible = true
	await get_tree().create_timer(0.1).timeout
	scroll_box.scroll_vertical = scroll_box.get_v_scroll_bar().max_value
	reset_mouse_timer.start() # Start the timer for resetting mouse mode

# Hide chat when the LineEdit loses focus
func _on_line_edit_focus_exited() -> void:
	if Global.get_player() != null:
		Global.get_player().locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	for entry in chat_list.get_children():
		if Time.get_ticks_msec() - entry.age > entry.hide_age:
			entry.visible = false
	await get_tree().create_timer(0.1).timeout
	scroll_box.scroll_vertical = scroll_box.get_v_scroll_bar().max_value

# Handle the Tab key press to open the chat
func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		if is_chat_mode:
			_close_chat_mode()
		else:
			_open_chat_mode()

# Handle text submission for chat
func _on_chat_submitted(text : String) -> void:
	if text.strip_edges() == "?ai":
		_switch_to_ai_mode()
		line_edit.clear()
		line_edit.release_focus()
		await get_tree().create_timer(0.1).timeout
		scroll_box.scroll_vertical = scroll_box.get_v_scroll_bar().max_value
	elif text.strip_edges() == "?close":
		_switch_to_chat_mode()
		line_edit.clear()
		line_edit.release_focus()
		await get_tree().create_timer(0.1).timeout
		scroll_box.scroll_vertical = scroll_box.get_v_scroll_bar().max_value
	else:
		CommandHandler.submit_command.rpc(Global.display_name, text)
		line_edit.clear()

# Handle command response and display in chat
func _on_command_response(sender : String, text : String, timeout : int = 10) -> void:
	var entry : Control = chat_entry.instantiate()
	chat_list.add_child(entry)
	entry.age = Time.get_ticks_msec()
	entry.hide_age = timeout * 1000
	entry.get_node("Margin/HBoxContainer/ChatLabel").text = str(text)
	entry.get_node("Margin/HBoxContainer/PlayerLabel").text = str(sender)
	get_tree().create_timer(timeout).connect("timeout", _on_entry_timeout.bind(entry))
	await get_tree().process_frame
	scroll_box.scroll_vertical = scroll_box.get_v_scroll_bar().max_value

# Timeout for hiding old chat entries
func _on_entry_timeout(entry : Node) -> void:
	if line_edit.has_focus():
		return
	entry.visible = false

# Switch to AI mode and display the AI window
func _switch_to_ai_mode() -> void:
	is_chat_mode = true
	is_ai_mode = true
	_show_godot_buddy_scene()

	# Ensure chat entries are still visible in AI mode
	scroll_box.visible = true
	chat_list.visible = true
	line_edit.visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Switch back to chat mode and reset everything
func _switch_to_chat_mode() -> void:
	is_chat_mode = true
	is_ai_mode = false
	_reset_to_initial_state()

# Show the GodotBuddyScene and manage visibility
func _show_godot_buddy_scene() -> void:
	scroll_box.visible = true
	chat_list.visible = true
	line_edit.visible = true

	godot_buddy_instance = godot_buddy_scene.instantiate()
	get_tree().current_scene.add_child(godot_buddy_instance)
	godot_buddy_instance.visible = true

	if Global.get_player() != null:
		Global.get_player().locked = true

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Reset everything to the initial state
func _reset_to_initial_state() -> void:
	if godot_buddy_instance:
		godot_buddy_instance.queue_free()
		godot_buddy_instance = null
	scroll_box.visible = true
	line_edit.text = ""
	line_edit.grab_focus()
	if Global.get_player() != null:
		Global.get_player().locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Reset mouse mode after a timeout
func _reset_mouse_mode() -> void:
	if not line_edit.has_focus():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if Global.get_player() != null:
			Global.get_player().locked = false

# Function to check if we're in AI mode or not
func check_mode() -> String:
	if is_in_chat_mode():
		return "Chat Mode"
	elif is_in_ai_mode():
		return "AI Mode"
	else:
		return "Unknown Mode"

func _open_chat_mode() -> void:
	is_chat_mode = true
	line_edit.grab_focus()
	scroll_box.visible = true
	chat_list.visible = true
	line_edit.visible = true
	if Global.get_player() != null:
		Global.get_player().locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_chat_mode() -> void:
	is_chat_mode = false
	line_edit.release_focus()
	scroll_box.visible = false
	chat_list.visible = true
	line_edit.visible = true
	
	if godot_buddy_instance and godot_buddy_instance.visible:
		godot_buddy_instance.visible = false
	
	if Global.get_player() != null:
		Global.get_player().locked = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
