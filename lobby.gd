extends Node


@onready var label: Label = $Label
@onready var should_host := "--host" in OS.get_cmdline_user_args()
@onready var button: Button = $Button
@onready var port: SpinBox = $Port
@onready var address: LineEdit = $Address
@onready var join_button: Button = $JoinButton
@onready var host_button: Button = $HostButton
@onready var reflex_mode: CheckBox = $ReflexMode


func _ready() -> void:
	button.hide()

	host_button.pressed.connect(func() -> void:
		get_tree().call_group("temporary", "hide")

		var peer := ENetMultiplayerPeer.new()
		peer.create_server(int(port.value))
		multiplayer.multiplayer_peer = peer

		button.show()
		label.text += "peer %d (hosting)\n" % multiplayer.get_unique_id()

	)
	join_button.pressed.connect(func() -> void:
		get_tree().call_group("temporary", "hide")

		var peer := ENetMultiplayerPeer.new()
		peer.create_client(address.text, int(port.value))
		multiplayer.multiplayer_peer = peer

		label.text += "peer %d (joining)\n" % multiplayer.get_unique_id()
	)

	multiplayer.peer_connected.connect(_on_peer_connected)

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
	var tree := get_tree()
	var inst := preload("res://simonsays.tscn").instantiate()

	tree.root.add_child(inst)
	tree.current_scene = inst
	queue_free()

	inst.reflex_mode = reflex_mode.button_pressed