#!/usr/bin/env python3
"""Erzeugt alle Platzhalter-Sounds als WAV (22,05 kHz, 16 Bit, mono) nach ../sounds/.

Nur Python-Standardbibliothek. Die Klaenge sind synthetisch (Oszillatoren, gefiltertes
Rauschen, Huellkurven) und koennen jederzeit durch echte Aufnahmen gleichen Namens ersetzt werden.

    python3 tools/gen_sounds.py
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sounds")
random.seed(2026)


# ---------------------------------------------------------------- Grundbausteine

def n_of(seconds):
    return int(seconds * SR)


def silence(seconds):
    return [0.0] * n_of(seconds)


def noise(seconds):
    return [random.uniform(-1.0, 1.0) for _ in range(n_of(seconds))]


def sine(seconds, freq, phase=0.0):
    """freq darf eine Zahl oder eine Funktion f(t) sein (Tonhoehen-Verlauf)."""
    out = []
    ph = phase
    for i in range(n_of(seconds)):
        f = freq(i / SR) if callable(freq) else freq
        out.append(math.sin(ph))
        ph += 2.0 * math.pi * f / SR
    return out


def env_exp(x, decay, attack=0.002):
    """Schneller Anstieg, exponentielles Abklingen (decay = 1/s)."""
    a = max(1, n_of(attack))
    return [v * (min(1.0, i / a)) * math.exp(-decay * i / SR) for i, v in enumerate(x)]


def env_ar(x, attack, release):
    n = len(x)
    a = max(1, n_of(attack))
    r = max(1, n_of(release))
    out = []
    for i, v in enumerate(x):
        g = min(1.0, i / a)
        if i > n - r:
            g *= max(0.0, (n - i) / r)
        out.append(v * g)
    return out


def lowpass(x, cutoff):
    a = math.exp(-2.0 * math.pi * cutoff / SR)
    y, out = 0.0, []
    for v in x:
        y = (1.0 - a) * v + a * y
        out.append(y)
    return out


def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [v - l for v, l in zip(x, lp)]


def bandpass(x, freq, q):
    """RBJ-Biquad-Bandpass; freq darf eine Funktion f(t) sein (Sweep)."""
    out = []
    x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x):
        f = freq(i / SR) if callable(freq) else freq
        w0 = 2.0 * math.pi * min(f, SR * 0.45) / SR
        alpha = math.sin(w0) / (2.0 * q)
        b0, b2 = alpha, -alpha
        a0, a1, a2 = 1.0 + alpha, -2.0 * math.cos(w0), 1.0 - alpha
        y = (b0 * v + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1 = x1, v
        y2, y1 = y1, y
        out.append(y)
    return out


def mix(*parts):
    """mix((signal, gain, offset_s), ...) - Signale versetzt aufaddieren."""
    length = max(n_of(off) + len(sig) for sig, _, off in parts)
    out = [0.0] * length
    for sig, gain, off in parts:
        o = n_of(off)
        for i, v in enumerate(sig):
            out[o + i] += v * gain
    return out


def gain(x, g):
    return [v * g for v in x]


def normalize(x, peak=0.85):
    m = max(1e-9, max(abs(v) for v in x))
    return [v * peak / m for v in x]


def loopable(x, fade_s=0.5):
    """Ende weich in den Anfang ueberblenden, damit die Schleife nahtlos ist."""
    f = n_of(fade_s)
    body = x[:len(x) - f]
    tail = x[len(x) - f:]
    for i in range(f):
        g = i / f
        body[i] = body[i] * g + tail[i] * (1.0 - g)
    return body


def write(name, x):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in x))
    print(f"  {name}.wav  {len(x) / SR:.2f}s")

# ---------------------------------------------------------------- Klaenge

def step_concrete(variant):
    # Schritt auf Beton: dumpfer Tritt plus trockenes Knirschen, je Variante leicht anders
    f = 70 + variant * 9
    thud = env_exp(sine(0.14, lambda t: f + 50 * math.exp(-t * 40)), 28)
    grit = env_exp(bandpass(noise(0.09), 1500 + variant * 230 + random.uniform(-100, 100), 1.1), 55)
    scuff = env_exp(highpass(noise(0.05), 3200), 90)
    return normalize(mix((thud, 1.0, 0), (grit, 0.55, 0.004), (scuff, 0.18, 0)), 0.55)


def click_light():
    # Schalter der Taschenlampe: kurzes, trockenes Knacken
    tick = env_exp(bandpass(noise(0.03), 2600, 3.0), 160)
    body = env_exp(sine(0.04, 420), 120)
    return normalize(mix((tick, 1.0, 0), (body, 0.4, 0)), 0.5)


SOUNDS = {
    "step_concrete_1": lambda: step_concrete(0),
    "step_concrete_2": lambda: step_concrete(1),
    "step_concrete_3": lambda: step_concrete(2),
    "step_concrete_4": lambda: step_concrete(3),
    "click_light": click_light,
}

if __name__ == "__main__":
    print("Erzeuge Sounds nach", os.path.normpath(OUT))
    for name, fn in SOUNDS.items():
        write(name, fn())
