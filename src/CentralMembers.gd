extends Node3D

# Arrays for labels
@onready var name_labels: Array = [
	$api_json/Name1, $api_json/Name2, $api_json/Name3, $api_json/Name4, $api_json/Name5, 
	$api_json/Name6, $api_json/Name7, $api_json/Name8, $api_json/Name9, $api_json/Name10
]
@onready var role_labels: Array = [
	$api_json/Role1, $api_json/Role2, $api_json/Role3, $api_json/Role4, $api_json/Role5,
	$api_json/Role6, $api_json/Role7, $api_json/Role8, $api_json/Role9, $api_json/Role10
]
@onready var joindate_labels: Array = [
	$api_json/JoinDate1, $api_json/JoinDate2, $api_json/JoinDate3, $api_json/JoinDate4, $api_json/JoinDate5,
	$api_json/JoinDate6, $api_json/JoinDate7, $api_json/JoinDate8, $api_json/JoinDate9, $api_json/JoinDate10
]
@onready var brands_labels: Array = [
	$api_json/Brands1, $api_json/Brands2, $api_json/Brands3, $api_json/Brands4, $api_json/Brands5,
	$api_json/Brands6, $api_json/Brands7, $api_json/Brands8, $api_json/Brands9, $api_json/Brands10
]
@onready var earned_tokens_labels: Array = [
	$api_json/EarnedTokens1, $api_json/EarnedTokens2, $api_json/EarnedTokens3, $api_json/EarnedTokens4, $api_json/EarnedTokens5,
	$api_json/EarnedTokens6, $api_json/EarnedTokens7, $api_json/EarnedTokens8, $api_json/EarnedTokens9, $api_json/EarnedTokens10
]
@onready var earned_dollars_labels: Array = [
	$api_json/EarnedDollars1, $api_json/EarnedDollars2, $api_json/EarnedDollars3, $api_json/EarnedDollars4, $api_json/EarnedDollars5,
	$api_json/EarnedDollars6, $api_json/EarnedDollars7, $api_json/EarnedDollars8, $api_json/EarnedDollars9, $api_json/EarnedDollars10
]

# Timer for polling API data
var polling_interval: float = 120  # Time in seconds
var polling_timer: Timer
var http_request: HTTPRequest

func _ready() -> void:
	# Initialize the HTTPRequest node once
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Connect the request_completed signal
	http_request.request_completed.connect(_on_request_completed)

	# Create a Timer for periodic API calls
	polling_timer = Timer.new()
	polling_timer.wait_time = polling_interval
	polling_timer.autostart = true
	polling_timer.one_shot = false
	add_child(polling_timer)
	polling_timer.timeout.connect(fetch_member_data)

	# Fetch data immediately on start
	#print("Fetching member data immediately...")
	fetch_member_data()

func fetch_member_data() -> void:
	# Stop the timer while the request is being made
	polling_timer.stop()

	# Define the API URL
	var url: String = "https://play2helpbackend.onrender.com/api/games/getMemberData/"
	
	# Make the request
	#print("Making HTTP request to:", url)
	var result: int = http_request.request(url)

	#if result != OK:
		#print("Failed to make HTTP request. Error code:", result)
	#else:
		#print("HTTP request sent successfully, waiting for response...")

func _on_request_completed(
	result: int, response_code: int, headers: Array, body: PackedByteArray
) -> void:
	#print("Request completed with response code:", response_code)

	if response_code == 200:
		var json: String = body.get_string_from_utf8()
		#print("Response JSON:", json)

		var json_parser: JSON = JSON.new()
		var parse_result: int = json_parser.parse(json)

		#if parse_result != OK:
			#print("Failed to parse JSON:", json_parser.get_error_message())
			#return

		var response_data: Dictionary = json_parser.data
		#print("Parsed Data:", response_data)

		# Fetching the 'member' array
		var member_data: Array = response_data.get("member", [])
		update_member_data(member_data)
	#else:
		#print("HTTP Request failed with code:", response_code)

	# Restart the polling timer
	polling_timer.start()


func update_member_data(member_data: Array) -> void:
	if member_data.size() == 0:
		#print("No member data available.")
		return

	for i in range(name_labels.size()):
		if i < member_data.size():
			var data: Dictionary = member_data[i]

			# Safely retrieve data with fallback
			var name: String = str(data.get("name", "Unknown Name"))
			var role: String = str(data.get("role", "Unknown Role"))
			var join_date: String = str(data.get("joined_date", "Unknown Date"))
			var earned_tokens: String = str(data.get("earned_tokens", 0.0))
			var earned_dollars: String = str(data.get("earned_dollars", 0.0))
			var brands: String = str(data.get("brands", []))  # Ensure this is a string

			# Debugging print statements
			#print("Member Name: ", name)
			#print("Member Role: ", role)
			#print("Earned Tokens: ", earned_tokens)
			#print("Earned Dollars: ", earned_dollars)

			# Update the labels
			name_labels[i].text = name
			role_labels[i].text = role
			joindate_labels[i].text = join_date
			earned_tokens_labels[i].text = earned_tokens
			earned_dollars_labels[i].text = earned_dollars
			brands_labels[i].text = brands

		else:
			# Fallback for when there is no data for a label
			name_labels[i].text = "Processing..."
			role_labels[i].text = "Processing..."
			joindate_labels[i].text = "Processing..."
			earned_tokens_labels[i].text = "Processing..."
			earned_dollars_labels[i].text = "Processing..."
			brands_labels[i].text = "Processing..."

	#print("Updated member data displayed.")
