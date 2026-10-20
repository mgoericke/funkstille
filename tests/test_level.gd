extends "res://tests/game_test.gd"
## Level-Rohbau: Hoehen, Marker, begehbare Route, Ausweg aus dem Gleisbett, Navigation.


func _initialize() -> void:
	await load_main()
	calm()
	var L: Level = main.level
	check(absf(floor_y(0, -1)) < 0.05, "Spawn steht auf Boden")
	check(absf(floor_y(0, -100) - 1.0) < 0.05, "Bahnsteig auf 1 m")
	check(absf(floor_y(-7, -100)) < 0.05, "Gleisbett links auf 0 m")
	check(absf(floor_y(0, -160) - 6.0) < 0.05, "Strasse auf 6 m")
	check(L.shard_zones.size() == 2 and L.bottle_spots.size() == 4, "Marker vollstaendig")
	check(L.patrol.size() == 3 and L.lauscher_start == Vector3(0, 1, -104), "Patrouille und Lauscher-Start")
	check(L.checkpoint.origin.distance_to(L.lauscher_start) >= 26.0, "Checkpoint ausser Hoerweite")
	check(L.tower_top == Vector3(60, 156, -600) and L.exit_z == -150.0, "Turm und Ausgang")
	check(await reachable([Vector3(0, 0, -20), Vector3(0, 0, -79), Vector3(-5, 0, -81), Vector3(-5, 1, -86.2), Vector3(0, 1, -90), Vector3(0, 1, -128), Vector3(0, 6, -145), Vector3(0, 6, -152)]), "Weg Spawn bis Strasse begehbar")
	# Gleisbett hat einen Ausgang: links hinten hoch, rechts analog
	main.player.reset_to(Transform3D(Basis(), Vector3(-6, 0.2, -110)))
	check(await reachable([Vector3(-5, 0, -123), Vector3(-5, 1, -127.8), Vector3(-3, 1, -127.8)]), "Aus dem Gleisbett links wieder hoch")
	main.player.reset_to(Transform3D(Basis(), Vector3(6, 0.2, -110)))
	check(await reachable([Vector3(5, 0, -123), Vector3(5, 1, -127.8), Vector3(3, 1, -127.8)]), "Aus dem Gleisbett rechts wieder hoch")
	# Die Stirnkante bei z -80 ist nicht begehbar
	main.player.reset_to(Transform3D(Basis(), Vector3(0, 0, -77)))
	await reachable([Vector3(0, 1, -85)])
	check(main.player.global_position.y < 0.2 and main.player.global_position.z > -80.0, "Stirnkante bei z -80 nicht begehbar")
	# Navigation: Karte braucht ein paar Frames, bis sie synchron ist
	await wait(0.2)
	var nav_path := NavigationServer3D.map_get_path(L.nav_region.get_navigation_map(), L.lauscher_start, Vector3(-7, 0, -100), true)
	check(nav_path.size() > 1, "Navigation verbindet Bahnsteig und Gleisbett")
	finish()
