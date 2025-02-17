extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$WebView.connect("ready", _on_view_ready)

# Called when the WebView emits the "ready" signal.
func _on_view_ready() -> void:
	$WebView.load()
