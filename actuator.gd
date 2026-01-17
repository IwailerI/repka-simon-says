class_name Actuator
extends Control

var _radius: float = 0.0
var _color := Color.TRANSPARENT


@rpc("any_peer", "call_local", "reliable")
func activate() -> void:
    var rect := get_rect()
    var r := maxf(rect.size.x, rect.size.y) * 0.5
    var t := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
    t.tween_property(self, "_color", Color.TRANSPARENT, 1.0).from(Color.WHITE)
    t.parallel().tween_property(self, "_radius", r * 1.2, 1.0).from(0.0)

    
func _process(_delta: float) -> void:
    queue_redraw()
    

func _draw() -> void:
    if _radius > 0:
        var rect := get_global_rect()
        draw_circle(rect.size * 0.5, _radius, _color)
