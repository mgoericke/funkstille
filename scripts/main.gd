extends Node3D
## Wurzel der Demo: baut spaeter Level, Spieler und Lauscher auf.

## Von Tests vor dem Instanziieren gesetzt: &"spawn" oder &"checkpoint" usw.
static var start_at: StringName = &"spawn"

var player: Player
var level: Level


func _ready() -> void:
	Controls.register()
	level = Level.new()
	level.name = "Level"
	add_child(level)
	level.build()
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.radio.beacon = level.beacon
	player.reset_to(level.checkpoint if start_at == &"checkpoint" else level.spawn)
