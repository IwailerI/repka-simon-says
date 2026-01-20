extends Node2D


const Col = SimonSaysPanel.Col

const COL_STRING: Dictionary[Col, String] = {
	Col.R: "[color=darkred]R[/color]",
	Col.G: "[color=forestgreen]G[/color]",
	Col.B: "[color=navyblue]B[/color]",
	Col.Y: "[color=darkorange]Y[/color]",
}

@onready var p1: SimonSaysPanel = $P1
@onready var p2: SimonSaysPanel = $P2
@onready var p3: SimonSaysPanel = $P3
@onready var p4: SimonSaysPanel = $P4

var our_p: SimonSaysPanel
var reflex_mode: bool = false
var colored_feedback: bool = false

@onready var remaining_time: ProgressBar = $RemainingTime
@onready var text: RichTextLabel = $Text
@onready var screen_rect: ColorRect = $ScreenRect

var _round_num: int = 0
var _survivors: PackedInt32Array
var _players_in_game: PackedInt32Array


func _ready() -> void:
	if multiplayer.is_server():
		server_loop.call_deferred()
		_players_in_game = multiplayer.get_peers()
		_players_in_game.append(multiplayer.get_unique_id())
	
	multiplayer.server_disconnected.connect(func() -> void:
		printerr("client disconnected")
		get_tree().quit(1)
	)

	our_p = _get_panel_of_peer(multiplayer.get_unique_id())
	our_p.make_local()

	our_p.sequence_completed.connect(_sequence_completed.rpc)
	our_p.sequence_error.connect(func() -> void:
		var t := screen_rect.create_tween()
		(t.tween_property(screen_rect, "color", Color.TRANSPARENT, 0.5)
				.from(Color.INDIAN_RED)
				.set_trans(Tween.TRANS_EXPO)
				.set_ease(Tween.EASE_OUT))
	)

	if not colored_feedback:
		our_p.disable_input_sharing()
	

@rpc("any_peer", "call_local", "reliable")
func _sequence_completed() -> void:
	if multiplayer.is_server():
		var peer := multiplayer.get_remote_sender_id()
		if not _survivors.has(peer):
			_survivors.append(peer)
	
	var p := _get_panel_of_peer(multiplayer.get_remote_sender_id())
	p.trigger_success()


@rpc("authority", "call_local", "reliable")
func _start_sequence(seq: Array[Col]) -> void:
	our_p.play_sequence(seq)


@rpc("authority", "call_local", "reliable")
func _set_text(t: String) -> void:
	text.text = t


@rpc("authority", "call_local", "reliable")
func _start_timer(seconds: float) -> void:
	var t := remaining_time.create_tween()
	t.tween_property(remaining_time, "value", 0.0, seconds).from(1.0)


@rpc("authority", "call_local", "reliable")
func _player_dead(peer: int) -> void:
	_get_panel_of_peer(peer).hide()


@rpc("authority", "call_local", "reliable")
func _declare_winner(peer: int) -> void:
	(func() -> void:
		var p := _get_panel_of_peer(peer)
		while true:
			var t := p.create_tween()
			t.set_trans(Tween.TRANS_SINE)

			t.tween_property(p, "position", Vector2.RIGHT * 50, 0.5).as_relative()
			t.chain().tween_property(p, "position", Vector2.LEFT * 50, 0.5).as_relative()
			await t.finished
	).call_deferred()


@rpc("authority", "call_local", "reliable")
func _reload_scene() -> void:
	get_tree().reload_current_scene()


@rpc("authority", "call_local", "reliable")
func _reset_state() -> void:
	for p: SimonSaysPanel in [p1, p2, p3, p4]:
		p.reset()


func server_loop() -> void:
	await get_tree().create_timer(3.0).timeout

	while _players_in_game.size() > 1:
		await play_round()
	
	if _players_in_game.size() == 0:
		_set_text.rpc("Draw!")
	else:
		_set_text.rpc("Player %d wins!" % _players_in_game[0])
		_declare_winner.rpc(_players_in_game[0])
	
	await get_tree().create_timer(3.0).timeout

	_reload_scene.rpc()


func play_round() -> void:
	_round_num += 1
	print("round %d" % _round_num)

	_survivors.clear()
	var action_count := pow(1.27, _round_num)
	var seq: Array[Col]
	for i: int in action_count:
		seq.push_back(Col.values().pick_random())

	_set_text.rpc("Round %d is about to start..." % _round_num)
	_start_timer.rpc(3.0)
	_reset_state.rpc()

	await get_tree().create_timer(3.0).timeout

	var prompt := ""
	for v: Col in seq:
		prompt += COL_STRING[v]

	if reflex_mode:
		_start_sequence.rpc(seq)
		_set_text.rpc("Simon says:\n" + prompt)
	else:
		_set_text.rpc("Simon says:\n%s\nGet ready..." % prompt)
		_start_timer.rpc(5.0)
		await get_tree().create_timer(5.0).timeout
		_start_sequence.rpc(seq)
		_set_text.rpc("Repeat!")

	_start_timer.rpc(5.0)
	await get_tree().create_timer(5.0).timeout

	var peers := multiplayer.get_peers()
	peers.append(multiplayer.get_unique_id())
	for peer: int in peers:
		if not _survivors.has(peer):
			_player_dead.rpc(peer)
			_players_in_game.erase(peer)


func _get_panel_of_peer(peer: int) -> SimonSaysPanel:
	var peers := multiplayer.get_peers()
	peers.append(multiplayer.get_unique_id())
	peers.sort()
	return [p1, p2, p3, p4][peers.find(peer)]