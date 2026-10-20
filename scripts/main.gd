extends Node3D
## Wurzel der Demo: baut spaeter Level, Spieler und Lauscher auf.

## Von Tests vor dem Instanziieren gesetzt: &"spawn" oder &"checkpoint" usw.
static var start_at: StringName = &"spawn"


func _ready() -> void:
	Controls.register()
