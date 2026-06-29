class_name Hud
extends CanvasLayer

signal restart_pressed

@onready var _distance_label: Label = $Margin/VBox/DistanceLabel
@onready var _coin_label: Label = $Margin/VBox/CoinLabel
@onready var _death_panel: Control = $DeathPanel
@onready var _restart_button: Button = $DeathPanel/RestartButton

func _ready() -> void:
	_death_panel.visible = false
	_restart_button.pressed.connect(func(): restart_pressed.emit())

func update_stats(distance: float, coins: int) -> void:
	_distance_label.text = "%d m" % int(distance / 100.0)
	_coin_label.text = "Coins: %d" % coins

func show_death(distance: float, coins: int) -> void:
	update_stats(distance, coins)
	_death_panel.visible = true
