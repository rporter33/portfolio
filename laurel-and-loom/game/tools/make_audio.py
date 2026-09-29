#!/usr/bin/env python3
"""Generate every sound in the game: a plucked lyre (Karplus-Strong), a frame
drum, and filtered noise. Pure Python, deterministic (seeded), no samples.

    python3 tools/make_audio.py        # writes assets/audio/*.wav

Music is in D Dorian. The battle loop and the enemy-phase drum loop are exact
multiples of one bar at 96 BPM, so the drums can be layered on and off in sync.
"""
import cmath
import math
import os
import random
import struct
import wave

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SFX_RATE = 22050
MUSIC_RATE = 16000

NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def hz(name: str) -> float:
    """'D4' -> frequency. Sharps as 'F#4'."""
    letter, rest = name[0], name[1:]
    semis = NOTE_INDEX[letter]
    if rest.startswith("#"):
        semis += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        semis -= 1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + semis
    return 440.0 * 2 ** ((midi - 69) / 12)


# --- Voices -----------------------------------------------------------------

def pluck(freq, dur, rate, amp=0.5, decay=0.996, soften=0.55, seed=0):
    """A plucked gut string: Karplus-Strong with an allpass for exact tuning."""
    rnd = random.Random(seed * 7919 + int(freq * 10))
    length = rate / freq
    # The two-point average delays half a sample; an allpass supplies the rest
    # of the fraction. Keep the allpass delay in [0.1, 1.1) where it's stable.
    n = max(2, int(math.floor(length - 0.6)))
    c = _allpass_coefficient(length - 0.5 - n, 2 * math.pi * freq / rate)
    line = []
    lp = 0.0
    for _ in range(n):
        lp += (1 - soften) * (rnd.uniform(-1, 1) - lp)
        line.append(lp)
    out = []
    ptr = 0
    last = 0.0
    ap_x = ap_y = 0.0
    total = int(dur * rate)
    for i in range(total):
        s = line[ptr]
        avg = 0.5 * (s + last)
        last = s
        ap = c * avg + ap_x - c * ap_y
        ap_x, ap_y = avg, ap
        line[ptr] = decay * ap
        ptr = (ptr + 1) % n
        out.append(s * amp)
    # Release: a short fade so nothing clicks.
    fade = min(total, int(0.03 * rate))
    for i in range(fade):
        out[total - 1 - i] *= i / fade
    return out


def _allpass_coefficient(delay, omega):
    """Solve for the first-order allpass coefficient whose phase delay at
    `omega` is exactly `delay` samples (the usual (1-d)/(1+d) is only exact
    near DC, which leaves high notes audibly sharp)."""
    def phase_delay(c):
        z = cmath.exp(-1j * omega)
        return -cmath.phase((c + z) / (1 + c * z)) / omega
    lo, hi = -0.999, 0.999  # phase delay falls as c rises
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if phase_delay(mid) > delay:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def drum(dur, rate, amp=0.8, f0=110.0, f1=48.0, seed=0):
    """A frame drum: a sine sweeping down in pitch, with a little skin noise."""
    rnd = random.Random(seed)
    out = []
    phase = 0.0
    lp = 0.0
    for i in range(int(dur * rate)):
        t = i / rate
        f = f1 + (f0 - f1) * math.exp(-t * 18)
        phase += 2 * math.pi * f / rate
        env = math.exp(-t * 9)
        lp += 0.2 * (rnd.uniform(-1, 1) - lp)
        out.append(amp * env * (math.sin(phase) + 0.25 * lp * math.exp(-t * 30)))
    return out


def noise(dur, rate, amp=0.4, cutoff=0.3, attack=0.005, decay_rate=12.0, sweep=0.0, seed=0):
    """Filtered noise with an exponential envelope; `sweep` opens the filter."""
    rnd = random.Random(seed)
    out = []
    lp = 0.0
    for i in range(int(dur * rate)):
        t = i / rate
        k = min(0.98, max(0.01, cutoff + sweep * t))
        lp += k * (rnd.uniform(-1, 1) - lp)
        env = min(1.0, t / attack) * math.exp(-t * decay_rate)
        out.append(amp * env * lp)
    return out


# --- Mixing and output ---------------------------------------------------------

def mix(into, sound, at_seconds, rate, gain=1.0):
    start = int(at_seconds * rate)
    need = start + len(sound)
    if need > len(into):
        into.extend([0.0] * (need - len(into)))
    for i, v in enumerate(sound):
        into[start + i] += v * gain
    return into


def write(name, samples, rate, peak=0.85, length=None):
    if length is not None:
        # Fold anything past the loop point back to the start, so tails ring
        # across the seam instead of being cut.
        tail = samples[length:]
        samples = samples[:length] + [0.0] * max(0, length - len(samples))
        for i, v in enumerate(tail):
            samples[i % length] += v
    top = max(1e-9, max(abs(v) for v in samples))
    scale = peak / top if top > peak else 1.0
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * scale)) * 32767)) for v in samples))
    print(f"  {name:16s} {len(samples) / rate:6.2f}s")


# --- Sound effects ---------------------------------------------------------------

def sfx():
    r = SFX_RATE
    write("cursor", pluck(hz("A6"), 0.08, r, amp=0.18, decay=0.9, soften=0.2), r)
    write("select", pluck(hz("A5"), 0.35, r, amp=0.5), r)
    write("confirm", mix(pluck(hz("D5"), 0.4, r, amp=0.45), pluck(hz("A5"), 0.45, r, amp=0.5), 0.07, r), r)
    write("cancel", mix(pluck(hz("A4"), 0.35, r, amp=0.45), pluck(hz("D4"), 0.4, r, amp=0.45), 0.07, r), r)
    write("menu", pluck(hz("E6"), 0.12, r, amp=0.25, decay=0.95), r)

    hit = noise(0.25, r, amp=0.7, cutoff=0.18, decay_rate=18, seed=2)
    mix(hit, drum(0.3, r, amp=0.7, f0=140, f1=60), 0, r)
    mix(hit, pluck(hz("D3"), 0.3, r, amp=0.35), 0, r)
    write("hit", hit, r)

    crit = noise(0.4, r, amp=0.6, cutoff=0.4, decay_rate=10, seed=3)
    mix(crit, drum(0.4, r, amp=0.8, f0=160, f1=55), 0, r)
    for i, n in enumerate(["D5", "F5", "A5", "D6"]):
        mix(crit, pluck(hz(n), 0.9, r, amp=0.35, soften=0.2), 0.04 + i * 0.03, r)
    write("crit", crit, r)

    write("miss", noise(0.35, r, amp=0.5, cutoff=0.05, attack=0.08, decay_rate=9, sweep=1.2, seed=4), r)

    heal = []
    for i, n in enumerate(["D5", "F5", "A5", "C6", "D6"]):
        mix(heal, pluck(hz(n), 0.8, r, amp=0.3, soften=0.35), i * 0.07, r)
    write("heal", heal, r)

    snip = noise(0.05, r, amp=0.6, cutoff=0.9, decay_rate=80, seed=5)
    mix(snip, noise(0.05, r, amp=0.6, cutoff=0.9, decay_rate=80, seed=6), 0.08, r)
    mix(snip, pluck(hz("E5"), 0.5, r, amp=0.3), 0.08, r)
    write("cut", snip, r)

    turn = noise(0.5, r, amp=0.4, cutoff=0.02, attack=0.2, decay_rate=5, sweep=0.8, seed=7)
    mix(turn, pluck(hz("A4"), 0.6, r, amp=0.35), 0.25, r)
    mix(turn, pluck(hz("D5"), 0.7, r, amp=0.4), 0.33, r)
    write("turn", turn, r)

    measure = []
    for i, n in enumerate(["A5", "E6", "A6", "E6", "A6"]):
        mix(measure, pluck(hz(n), 0.5, r, amp=0.18, soften=0.1), i * 0.05, r)
    write("measure", measure, r)

    unravel = []
    for i, n in enumerate(["D6", "A5", "F5", "D5", "A4"]):
        mix(unravel, pluck(hz(n), 0.6, r, amp=0.28), i * 0.05, r)
    mix(unravel, noise(0.5, r, amp=0.25, cutoff=0.6, attack=0.1, decay_rate=6, sweep=-1.0, seed=8), 0, r)
    write("unravel", unravel, r)

    fortune = []
    for i, n in enumerate(["G5", "B5", "D6"]):
        mix(fortune, pluck(hz(n), 0.6, r, amp=0.25, soften=0.2), i * 0.06, r)
    write("fortune", fortune, r)

    player = []
    for i, n in enumerate(["D4", "A4", "D5", "F5", "A5"]):
        mix(player, pluck(hz(n), 1.3, r, amp=0.4), i * 0.09, r)
    write("phase_player", player, r)

    enemy = drum(0.6, r, amp=0.9, f0=90, f1=40)
    mix(enemy, drum(0.6, r, amp=0.9, f0=90, f1=40, seed=1), 0.28, r)
    mix(enemy, pluck(hz("D2"), 1.2, r, amp=0.5, decay=0.998), 0.28, r)
    write("phase_enemy", enemy, r)

    victory = []
    for i, n in enumerate(["D4", "F#4", "A4", "D5", "F#5", "A5", "D6"]):
        mix(victory, pluck(hz(n), 1.8, r, amp=0.35), i * 0.08, r)
    mix(victory, pluck(hz("D3"), 2.0, r, amp=0.4, decay=0.998), 0, r)
    write("victory", victory, r)

    defeat = []
    for i, n in enumerate(["D5", "C5", "A4", "F4", "D4"]):
        mix(defeat, pluck(hz(n), 1.6, r, amp=0.35), i * 0.28, r)
    write("defeat", defeat, r)

    death = noise(0.7, r, amp=0.45, cutoff=0.5, attack=0.01, decay_rate=5, sweep=-0.6, seed=9)
    mix(death, pluck(hz("D3"), 0.8, r, amp=0.3), 0, r)
    write("death", death, r)


# --- Music ---------------------------------------------------------------------------

CHORDS = {
    "Dm": ["D3", "A3", "D4", "F4", "A4", "F4", "D4", "A3"],
    "C":  ["C3", "G3", "C4", "E4", "G4", "E4", "C4", "G3"],
    "G":  ["G2", "D3", "G3", "B3", "D4", "B3", "G3", "D3"],
    "F":  ["F2", "C3", "F3", "A3", "C4", "A3", "F3", "C3"],
    "Am": ["A2", "E3", "A3", "C4", "E4", "C4", "A3", "E3"],
}
ROOTS = {"Dm": "D2", "C": "C2", "G": "G2", "F": "F2", "Am": "A2"}

BATTLE_BARS = ["Dm", "C", "G", "Dm", "Dm", "F", "C", "Am"]
# Melody in eighths; None is a rest.
BATTLE_TUNE = [
    ["A4", None, "D5", None, "F5", "E5", "D5", None],
    ["E5", None, "G5", None, "E5", "D5", "C5", None],
    ["B4", None, "D5", None, "G5", None, "F5", "E5"],
    ["D5", None, None, None, "A4", None, None, None],
    ["F5", None, "A5", None, "G5", "F5", "E5", None],
    ["F5", None, "C5", None, "A4", None, "C5", None],
    ["E5", None, "D5", None, "C5", None, "G4", None],
    ["A4", None, None, None, "E5", None, "C5", None],
]

TITLE_BARS = ["Dm", "F", "C", "Dm", "G", "Dm", "C", "Am"]
TITLE_TUNE = [
    ["D5", None, None, None, None, None, "E5", None],
    ["F5", None, None, None, "C5", None, None, None],
    ["E5", None, None, None, "G4", None, None, None],
    ["A4", None, None, None, None, None, None, None],
    ["B4", None, None, None, "D5", None, None, None],
    ["F5", None, "E5", None, "D5", None, None, None],
    ["E5", None, None, None, "C5", None, None, None],
    ["A4", None, None, None, None, None, None, None],
]


def song(bars, tune, bpm, arp_gain, tune_gain, seed):
    r = MUSIC_RATE
    beat = 60.0 / bpm
    eighth = beat / 2
    bar_len = beat * 4
    out = []
    for b, chord in enumerate(bars):
        t0 = b * bar_len
        mix(out, pluck(hz(ROOTS[chord]), bar_len * 1.2, r, amp=0.5, decay=0.999, soften=0.7, seed=seed + b), t0, r)
        for i, n in enumerate(CHORDS[chord]):
            accent = 1.0 if i % 4 == 0 else 0.7
            mix(out, pluck(hz(n), 1.2, r, amp=0.3 * accent, soften=0.6, seed=seed + b * 8 + i), t0 + i * eighth, r, arp_gain)
        for i, n in enumerate(tune[b]):
            if n is not None:
                mix(out, pluck(hz(n), 1.6, r, amp=0.45, soften=0.35, seed=seed + 100 + b * 8 + i), t0 + i * eighth, r, tune_gain)
    return out, int(round(len(bars) * bar_len * r))


def music():
    print("music:")
    battle, n = song(BATTLE_BARS, BATTLE_TUNE, 96, 0.8, 0.9, seed=11)
    write("music_battle", battle, MUSIC_RATE, peak=0.7, length=n)
    title, n = song(TITLE_BARS, TITLE_TUNE, 72, 0.6, 0.8, seed=23)
    write("music_title", title, MUSIC_RATE, peak=0.6, length=n)
    # One bar of frame drum for the enemy phase: DUM . tek tek DUM . tek .
    r = MUSIC_RATE
    beat = 60.0 / 96
    bar = []
    for t, kind in [(0, "dum"), (1.0, "tek"), (1.5, "tek"), (2.0, "dum"), (3.0, "tek")]:
        if kind == "dum":
            mix(bar, drum(0.5, r, amp=0.9, f0=100, f1=45, seed=int(t * 10)), t * beat, r)
        else:
            mix(bar, noise(0.12, r, amp=0.5, cutoff=0.6, decay_rate=35, seed=int(t * 10)), t * beat, r)
            mix(bar, drum(0.15, r, amp=0.3, f0=300, f1=200), t * beat, r)
    write("music_drums", bar, MUSIC_RATE, peak=0.6, length=int(round(4 * beat * r)))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    print("sfx:")
    sfx()
    music()
