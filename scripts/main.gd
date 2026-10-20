extends Node3D
## Wurzel der Demo: baut spaeter Level, Spieler und Lauscher auf.

## Von Tests vor dem Instanziieren gesetzt: &"spawn" oder &"checkpoint" usw.
static var start_at: StringName = &"spawn"

var player: Player


func _ready() -> void:
	Controls.register()
	_build_test_floor()  # TEMPORAER: entfaellt, sobald das Level (Task 4) existiert
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.reset_to(Transform3D(Basis(), Vector3.ZERO))


## TEMPORAER bis zum Level: grosser flacher Boden und Umgebung.
func _build_test_floor() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "TestFloor"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	col.shape = box
	col.position.y = -0.5
	floor_body.add_child(col)
	add_child(floor_body)
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	add_child(env)
	Look.apply(env)
