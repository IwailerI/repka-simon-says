class_name SimonSaysPanel
extends GridContainer


signal sequence_completed
signal sequence_error

enum Col {
	R,
	G,
	B,
	Y,
}

var _seq: Array[Col] = []
var _idx: int = 0

@onready var _you: Node2D = $You
@onready var _ok: Node2D = $Ok
@onready var _b: Button = $B
@onready var _r: Button = $R
@onready var _g: Button = $G
@onready var _y: Button = $Y
@onready var _counter_label: Label = $Counter/Label


func _ready() -> void:
	_r.pressed.connect(_button.bind(Col.R))
	_g.pressed.connect(_button.bind(Col.G))
	_b.pressed.connect(_button.bind(Col.B))
	_y.pressed.connect(_button.bind(Col.Y))

	_r.pressed.connect(_r.activate.rpc)
	_g.pressed.connect(_g.activate.rpc)
	_b.pressed.connect(_b.activate.rpc)
	_y.pressed.connect(_y.activate.rpc)

	_r.disabled = true
	_g.disabled = true
	_b.disabled = true
	_y.disabled = true


@rpc("any_peer", "call_local", "reliable")
func set_label_text(t: String) -> void:
	_counter_label.text = t


func disable_input_sharing() -> void:
	_r.pressed.disconnect(_r.activate.rpc)
	_g.pressed.disconnect(_g.activate.rpc)
	_b.pressed.disconnect(_b.activate.rpc)
	_y.pressed.disconnect(_y.activate.rpc)


func play_sequence(seq: Array[Col]) -> void:
	reset()
	_seq = seq.duplicate()
	set_label_text.rpc("0 / %d" % seq.size())


func reset() -> void:
	_seq = []
	_idx = 0
	_ok.hide()
	set_label_text.rpc("")


func make_local() -> void:
	_you.show()
	_r.disabled = false
	_g.disabled = false
	_b.disabled = false
	_y.disabled = false


func trigger_success() -> void:
	_ok.show()


func _button(col: Col) -> void:
	if _seq.is_empty():
		return

	if _seq[_idx] != col:
		sequence_error.emit()
		_idx = 0
		set_label_text.rpc("0 / %d" % _seq.size())
		return

	_idx += 1
	set_label_text.rpc("%d / %d" % [_idx, _seq.size()])

	if _idx >= _seq.size():
		sequence_completed.emit()
		reset()
		_ok.show()
