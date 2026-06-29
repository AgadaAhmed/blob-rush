class_name RunState
extends RefCounted

signal died

var distance: float = 0.0
var coins: int = 0
var alive: bool = true

func advance(speed: float, delta: float) -> void:
	if not alive:
		return
	distance += speed * delta

func add_coin(amount: int = 1) -> void:
	coins += amount

func kill() -> void:
	if alive:
		alive = false
		died.emit()
