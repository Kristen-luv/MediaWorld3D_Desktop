extends Control

# Declare the UI nodes
var button: Button
var text_edit: TextEdit
var rich_text_label: RichTextLabel
var http_request: HTTPRequest
var chat_history = []
var system_prompt = "Your name is Godot Buddy, you are a master coder and game designer. You only use the Godot 4 Engine. You carefully follow all instructions you are given and avoid giving lengthy explanations of why or how something works. You always follow DRY and SOLID principles in all code you write. You always write self-describing code with full names for all variables and functions. Always fully document code and functions with documentation comments using hashtags that completely explain all params and variables. You always use tabs for indentation. You always follow Godot 4 gdscript style guidelines. You always utilize getter and setter functions. You always statically type all variables and focus on maximizing performance. Instead of writing code in markdown tags you write them in bbcode [code][/code] tags. Use BBCode to make your messages look prettier."
var session_id = ""  # Store session ID from the response

func _ready():
	# Set up the UI elements in your 3D scene
	button = $VBoxContainer/AISubmission/Button
	text_edit = $VBoxContainer/AIPromptEditor/TextEdit
	rich_text_label = $VBoxContainer/AIChatResponse/RichTextLabel
	http_request = $VBoxContainer/HTTPRequest
	
	# Connect button signal
	button.connect("pressed", Callable(self, "_on_button_pressed"))
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
	
	# No API key loading since it’s no longer needed

func _on_button_pressed():
	var text = text_edit.text
	
	# Check for @filename.gd pattern and replace with file contents
	var pattern: String = r"@([a-zA-Z0-9_/]+(\.gd|\.tscn|\.godot|\.asset))"
	var regex = RegEx.new()
	regex.compile(pattern)
	var matches = regex.search_all(text)
	for match in matches:
		var file_path = match.get_string(1)
		var file_contents = read_file_contents(file_path)
		text = text.replace("@" + file_path, file_path + ":\n\n" + file_contents)
	
	# Append user message to the chat history
	chat_history.append({"role": "user", "content": text})
	
	rich_text_label.append_text("\n\n---\n\n[u]User:[/u] " + text)
	
	# Prepare request data (no authorization required)
	var url = "https://flowise-2-0.onrender.com/api/v1/prediction/9f1781bd-ad88-42a8-8baf-554a0e7b1ac9"
	var headers = ["Content-Type: application/json"]  # Removed Authorization header
	var body = {
		"question": text
	}
	
	# Send the HTTP request
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	text_edit.text = ""  # Clear the input field after sending

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var response_str = body.get_string_from_utf8()
		var response_data = JSON.parse_string(response_str)
		if typeof(response_data) == TYPE_DICTIONARY and response_data.has("text"):
			var ai_response = response_data["text"]
			
			# Show AI response in rich text label
			rich_text_label.push_color(Color.DARK_SEA_GREEN)
			rich_text_label.append_text("\n\n---\n\n[u]AI:[/u] " + ai_response)
			rich_text_label.pop()
			
			# Append AI's response to chat history
			chat_history.append({"role": "assistant", "content": ai_response})
			
			# Update session ID for continuity in the chat
			session_id = response_data["sessionId"]
		else:
			# Show error message in case of failure
			rich_text_label.push_color(Color.DARK_RED)
			rich_text_label.append_text("\n\n---\n\n[u]Error:[/u] Failed to parse response.")
			rich_text_label.pop()
	else:
		# Show error if request fails
		rich_text_label.push_color(Color.DARK_RED)
		rich_text_label.append_text("\n\n---\n\n[u]Error:[/u] Request failed with code " + str(response_code))
		rich_text_label.pop()

func read_file_contents(file_name: String) -> String:
	var root_dir = "res://"
	var file_path = _find_file(root_dir, file_name)
	if file_path != "":
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var contents = file.get_as_text()
			file.close()
			return contents
	return ""

func _find_file(dir: String, file_name: String) -> String:
	var dir_access = DirAccess.open(dir)
	if dir_access:
		dir_access.list_dir_begin()
		var file_or_dir = dir_access.get_next()
		while file_or_dir != "":
			if dir_access.current_is_dir():
				var sub_dir = dir + "/" + file_or_dir
				var result = _find_file(sub_dir, file_name)
				if result != "":
					return result
			elif file_or_dir == file_name:
				return dir + "/" + file_or_dir
			file_or_dir = dir_access.get_next()
	return ""
