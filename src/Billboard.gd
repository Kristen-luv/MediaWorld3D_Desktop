extends CSGBox3D

@onready var player_labels: Array = [
	$Player1, $Player2, $Player3, $Player4, $Player5
]
@onready var score_labels: Array = [
	$Score1, $Score2, $Score3, $Score4, $Score5
]
@onready var game_labels: Array = [
	$Game1, $Game2, $Game3, $Game4, $Game5
]

var polling_interval: float = 120  # Time in seconds between API calls
var polling_timer: Timer

func _ready() -> void:
	# Create a Timer for periodic API calls
	polling_timer = Timer.new()
	polling_timer.wait_time = polling_interval
	polling_timer.autostart = true
	polling_timer.one_shot = false
	add_child(polling_timer)
	polling_timer.timeout.connect(fetch_player_data)
	
	# Fetch data immediately on start
	fetch_player_data()

func fetch_player_data() -> void:
	# Ensure correct static type for HTTPRequest
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)  # Properly add the node

	# Connect the signal using a lambda for callback
	http_request.request_completed.connect(_on_request_completed)

	# Define the API URL
	var url: String = "https://play2helpbackend.onrender.com/api/games/getAllScores/"
	
	# Make the request
	var result: int = http_request.request(url)

	#if result != OK:
		#print("Failed to make HTTP request. Error code:", result)

func _on_request_completed(
	result: int, response_code: int, headers: Array, body: PackedByteArray
) -> void:
	if response_code == 200:
		# Decode the JSON
		var json: String = body.get_string_from_utf8()
		var json_parser: JSON = JSON.new()
		var parse_result: int = json_parser.parse(json)

		#if parse_result != OK:
			#print("Failed to parse JSON:", json_parser.get_error_message())
			#return

		# Access the JSON array
		var player_list: Array = json_parser.data
		update_scoreboard(player_list)
	#else:
		#print("HTTP Request failed with code:", response_code)

func update_scoreboard(player_list: Array) -> void:
	# Loop through labels and update them
	for i in range(player_labels.size()):
		if i < player_list.size():
			var player_data: Dictionary = player_list[i]
			player_labels[i].text = player_data.get("user", "Unknown Player")
			score_labels[i].text = str(player_data.get("score", "0"))
			game_labels[i].text = player_data.get("game", "Unknown Game")
		else:
			# If no data available, set "Processing..."
			player_labels[i].text = "Processing..."
			score_labels[i].text = "Processing..."
			game_labels[i].text = "Processing..."
