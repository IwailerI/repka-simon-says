extends Node


@onready var label: Label = $Label
@onready var should_host := "--host" in OS.get_cmdline_user_args()
@onready var button: Button = $Button
@onready var port: SpinBox = $Port
@onready var address: LineEdit = $Address
@onready var join_button: Button = $JoinButton
@onready var host_button: Button = $HostButton

func _ready() -> void:
	button.hide()

	join_button.pressed.connect(func() -> void:
		get_tree().call_group("temporary", "hide")

		var peer := ENetMultiplayerPeer.new()
		peer.create_server(int(port.value))
		multiplayer.multiplayer_peer = peer

		button.show()
	)
	host_button.pressed.connect(func() -> void:
		get_tree().call_group("temporary", "hide")

		var peer := ENetMultiplayerPeer.new()
		peer.create_client(address.text, int(port.value))
		multiplayer.multiplayer_peer = peer
	)

	
	multiplayer.peer_connected.connect(_on_peer_connected)

	label.text += "peer %d\n" % multiplayer.get_unique_id()

	button.pressed.connect(_on_start)
	multiplayer.server_disconnected.connect(func() -> void:
		printerr("client disconnected")
		get_tree().quit(1)
	)
	multiplayer.connection_failed.connect(func() -> void:
		label.text += "connection failed\n"
	)


func _on_peer_connected(id: int) -> void:
	label.text += "peer %d connected\n" % id


func _on_start() -> void:
	_change_scene.rpc()


@rpc("authority", "call_local", "reliable")
func _change_scene() -> void:
	get_tree().change_scene_to_packed(preload("res://simonsays.tscn"))
