extends Node


const SERVER_PORT: int = 55555

@onready var label: Label = $Label
@onready var should_host := "--host" in OS.get_cmdline_user_args()
@onready var button: Button = $Button


func _ready() -> void:
	var peer := ENetMultiplayerPeer.new()
	if should_host:
		peer.create_server(SERVER_PORT)
		button.show()
	else:
		peer.create_client("127.0.0.1", SERVER_PORT)
		button.queue_free()

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	label.text += "peer %d\n" % multiplayer.get_unique_id()

	button.pressed.connect(_on_start)
	multiplayer.server_disconnected.connect(func() -> void:
		printerr("client disconnected")
		get_tree().quit(1)
	)


func _on_peer_connected(id: int) -> void:
	label.text += "peer %d connected\n" % id


func _on_start() -> void:
	_change_scene.rpc()


@rpc("authority", "call_local", "reliable")
func _change_scene() -> void:
	get_tree().change_scene_to_packed(preload("res://simonsays.tscn"))
