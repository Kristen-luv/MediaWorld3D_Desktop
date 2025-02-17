extends Node3D

@onready var player_labels: Array = [
	$api_json/User1, $api_json/User2, $api_json/User3, $api_json/User4, $api_json/User5, 
	$api_json/User6, $api_json/User7, $api_json/User8, $api_json/User9, $api_json/User10
]
@onready var score_labels: Array = [
	$api_json/Total_score1, $api_json/Total_score2, $api_json/Total_score3, $api_json/Total_score4, $api_json/Total_score5, 
	$api_json/Total_score6, $api_json/Total_score7, $api_json/Total_score8, $api_json/Total_score9, $api_json/Total_score10
]
@onready var tokens_labels: Array = [
	$api_json/Total_tokens1, $api_json/Total_tokens2, $api_json/Total_tokens3, $api_json/Total_tokens4, $api_json/Total_tokens5, 
	$api_json/Total_tokens6, $api_json/Total_tokens7, $api_json/Total_tokens8, $api_json/Total_tokens9, $api_json/Total_tokens10
]
@onready var claimed_tokens_labels: Array = [
	$api_json/Claimed_tokens1, $api_json/Claimed_tokens2, $api_json/Claimed_tokens3, $api_json/Claimed_tokens4, $api_json/Claimed_tokens5, 
	$api_json/Claimed_tokens6, $api_json/Claimed_tokens7, $api_json/Claimed_tokens8, $api_json/Claimed_tokens9, $api_json/Claimed_tokens10
]

var polling_interval: float = 5.0  # Time in seconds between API calls
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
	var url: String = "https://play2helpbackend.onrender.com/api/games/getTotalScores/"
	
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

		# Access the JSON data
		var response_data: Dictionary = json_parser.data
		var total_scores: Array = response_data.get("total_scores", [])
		update_scoreboard(total_scores)
	#else:
		#print("HTTP Request failed with code:", response_code)

func update_scoreboard(total_scores: Array) -> void:
	# Loop through labels and update them
	for i in range(player_labels.size()):
		if i < total_scores.size():
			var player_data: Dictionary = total_scores[i]
			player_labels[i].text = player_data.get("user", "Unknown Player")
			score_labels[i].text = str(player_data.get("total_score", "0"))
			tokens_labels[i].text = str(player_data.get("total_tokens", "0.0"))
			claimed_tokens_labels[i].text = str(player_data.get("claimed_tokens", "0.0"))
		else:
			# If no data available, set default placeholder
			player_labels[i].text = "Processing..."
			score_labels[i].text = "Processing..."
			tokens_labels[i].text = "Processing..."
			claimed_tokens_labels[i].text = "Processing..."
