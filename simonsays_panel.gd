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


func play_sequence(seq: Array[Col]) -> void:
	reset()
	_seq = seq.duplicate()


func reset() -> void:
	_seq = []
	_idx = 0
	_ok.hide()


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
		return

	_idx += 1

	if _idx >= _seq.size():
		sequence_completed.emit()
		reset()
		_ok.show()
