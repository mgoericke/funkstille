extends "res://tests/game_test.gd"
## Funkgeraet: Signal waechst mit dem Fortschritt, Rauschen sendet Impulse, R schaltet um, clear_voice.


func _initialize() -> void:
	print("Funkgeraet")
	await load_main()
	var r: Radio = main.player.get_node_or_null("Head/Radio")
	check(r != null, "Funkgeraet unter Head/Radio")
	if r == null:
		finish()
		return
	check(r.on, "Funkgeraet startet eingeschaltet")
	check(is_equal_approx(r.strength(Vector3(0, 0, 0)), 0.15), "Am Start Signalstaerke 0,15")
	check(r.strength(Vector3(0, 0, -1)) < r.strength(Vector3(0, 1, -100)), "Signal wird zum Ausgang hin staerker")
	check(is_equal_approx(r.strength(Vector3(0, 6, -160)), 1.0), "Am Ausgang volles Signal")
	check(is_equal_approx(r.strength(Vector3(0, 0, -75)), 0.15 + 0.85 * 0.5), "Halbe Strecke: 0,575")
	check(is_equal_approx(r.strength(Vector3(0, 0, 50)), 0.15), "Hinter dem Start nicht unter 0,15")
	check(r.beacon.is_equal_approx(main.level.beacon), "Beacon = Level.beacon")

	var pulses := []
	var pos_ok := [true]
	noise_bus().emitted.connect(func(p, rad, s):
		if s == &"radio":
			pulses.append(rad)
			if not p.is_equal_approx(r.global_position):
				pos_ok[0] = false)
	await wait(2.0)
	check(pulses.size() >= 3 and pulses.size() <= 5, "Rauscht alle 0,5 s (%d Impulse)" % pulses.size())
	check(pulses.all(func(x): return x == Tuning.NOISE_RADIO), "Radius 12 m")
	check(pos_ok[0], "Impuls an der Position des Funkgeraets")

	await tap(&"radio")
	pulses.clear()
	await wait(2.0)
	check(not r.on and pulses.size() == 0, "R schaltet aus, danach still")
	pulses.clear()
	Input.action_press(&"radio")
	await wait(0.1)
	Input.action_release(&"radio")
	check(r.on and pulses.size() >= 1, "Einschalten sendet sofort einen Impuls (<0,1 s)")
	await wait(0.1)

	# Lautstaerken: Rauschen leiser, Ton lauter mit wachsender Staerke
	r.update_sound(0.15)
	var n0: float = r.static_player.volume_db
	var t0: float = r.tone_player.volume_db
	r.update_sound(1.0)
	check(n0 > r.static_player.volume_db and t0 < r.tone_player.volume_db, "Rauschen sinkt, Ton steigt mit der Staerke")
	check(is_equal_approx(r.static_player.volume_db, -22.0) and is_equal_approx(r.tone_player.volume_db, -8.0), "Pegel bei s=1: -22 / -8 dB")
	check(is_equal_approx(n0, lerpf(-6.0, -22.0, 0.15)), "Pegel Rauschen bei s=0,15")

	# clear_voice: Rauschen stumm, Ton voll, keine Impulse
	r.clear_voice = true
	pulses.clear()
	await wait(1.2)
	check(r.static_player.volume_db <= -60.0 and is_equal_approx(r.tone_player.volume_db, 0.0), "clear_voice: Rauschen aus, Ton voll")
	check(pulses.size() == 0, "clear_voice: kein Rausch-Impuls fuer den Lauscher")

	# Eingabe gesperrt: R wirkt nicht
	r.clear_voice = false
	main.player.input_enabled = false
	await tap(&"radio")
	check(r.on, "Bei gesperrter Eingabe schaltet R nicht")
	main.player.input_enabled = true
	finish()
