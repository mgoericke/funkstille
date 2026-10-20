extends Node
## Autoload "Noise": Geraeusch-Ereignisse. Der Lauscher hoert darauf.
## Quellen: &"step", &"sprint", &"shards", &"bottle", &"radio"

signal emitted(pos: Vector3, radius: float, source: StringName)


func emit(pos: Vector3, radius: float, source: StringName) -> void:
	emitted.emit(pos, radius, source)
