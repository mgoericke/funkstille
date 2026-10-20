class_name Tuning
## Alle Spielwerte an einer Stelle. Andere Skripte lesen nur von hier.

# Bewegung (m/s) und Schrittweite (Meter pro Schritt)
const WALK_SPEED := 2.8
const CROUCH_SPEED := 1.4
const SPRINT_SPEED := 5.5
const STEP_DIST := 0.75

# Hoerweiten der Geraeusche (Meter)
const NOISE_WALK := 2.0
const NOISE_CROUCH := 0.0
const NOISE_SPRINT := 9.0
const NOISE_SHARDS := 10.0
const NOISE_SHARDS_CROUCH := 4.0
const NOISE_BOTTLE := 14.0
const NOISE_RADIO := 12.0
const RADIO_PULSE := 0.5

# Lauscher: Geschwindigkeiten (m/s) und Zeiten (s)
const L_WANDER := 1.0
const L_INVESTIGATE := 1.6
const L_HUNT := 4.2
const L_ALERT_TIME := 1.2
const L_HUNT_RANGE := 6.0
const L_GIVE_UP := 4.0
const L_SEARCH_TIME := 3.0
const L_CATCH := 1.1

# Wurf
const THROW_SPEED := 9.0
const THROW_UP := 2.0

# Blick
const MOUSE_SENS := 0.0025
const PAD_LOOK := 2.6  # rad/s
