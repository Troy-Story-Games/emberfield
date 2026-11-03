"""Synthesizes the store trailer's soundtrack: an original 58-second, 120 BPM track in A minor.

Everything is generated from oscillators and noise, so the track is the project's own
and safe to use on YouTube and in the Play listing.

    python tools/trailer_music.py out.wav [--along]

--along keeps the groove going through 42-52 s, mixed lower, so the touch instrument
(see --along in tools/trailer.gd) plays along with the track instead of over a breakdown.

Needs numpy and scipy. The sections line up with the timeline in tools/trailer.gd:
  0-6 s    intro: pad and arpeggio
  6-28 s   groove: soft kick, hats, bass (touch modes and settings)
  28-30 s  riser into the drop
  30-42 s  drop: full drums, bass and lead (Audio mode visualizes this)
  42-52 s  breakdown: quiet pad only, so the touch instrument is heard on top
  52-58 s  outro: drums return, final hit and tail
"""

import sys
import wave

import numpy as np
from scipy import signal

RATE = 44100
BPM = 120.0
BEAT = 60.0 / BPM
BAR = BEAT * 4
LENGTH = 58.0
N = int(RATE * LENGTH)
rng = np.random.default_rng(7)

# A minor: Am - F - C - G, one bar each.
CHORDS = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
BASS_ROOTS = [33, 29, 36, 31]


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def saw(freq, t, harmonics=None):
    """Band-limited sawtooth from additive harmonics."""
    top = harmonics or max(1, int(RATE * 0.45 / freq))
    out = np.zeros_like(t)
    for k in range(1, top + 1):
        out += np.sin(2 * np.pi * freq * k * t) / k
    return out * (2 / np.pi)


def lowpass(x, cutoff, order=2):
    b, a = signal.butter(order, cutoff / (RATE / 2), "low")
    return signal.lfilter(b, a, x)


def highpass(x, cutoff, order=2):
    b, a = signal.butter(order, cutoff / (RATE / 2), "high")
    return signal.lfilter(b, a, x)


def place(track, start, clip, gain=1.0):
    i = int(start * RATE)
    if i >= len(track):
        return
    j = min(len(track), i + len(clip))
    track[i:j] += clip[: j - i] * gain


def env(n, attack, release_rate):
    t = np.arange(n) / RATE
    return np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t * release_rate)


def kick(punch=1.0):
    n = int(0.45 * RATE)
    t = np.arange(n) / RATE
    freq = 45 + 110 * np.exp(-t / 0.035)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    body = np.sin(phase) * np.exp(-t * 7.5)
    click = rng.uniform(-1, 1, n) * np.exp(-t * 300) * 0.25
    return np.tanh((body + click) * 1.6 * punch)


def clap():
    n = int(0.3 * RATE)
    t = np.arange(n) / RATE
    noise = signal.lfilter(*signal.butter(2, [900 / (RATE / 2), 5000 / (RATE / 2)], "band"), rng.uniform(-1, 1, n))
    # Three quick slaps then a tail.
    e = np.zeros(n)
    for d in (0.0, 0.011, 0.022):
        e += np.where(t >= d, np.exp(-(t - d) * 120), 0)
    e += np.where(t >= 0.03, np.exp(-(t - 0.03) * 16), 0) * 0.6
    return noise * e * 2.2


def hat(open_hat=False):
    n = int((0.3 if open_hat else 0.06) * RATE)
    t = np.arange(n) / RATE
    noise = highpass(rng.uniform(-1, 1, n), 7000)
    return noise * np.exp(-t * (9 if open_hat else 70))


def pad_chord(notes, seconds, bright):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for m in notes + [notes[0] - 12]:
        for det in (-0.09, 0.0, 0.09):
            out += saw(hz(m + det), t, harmonics=24)
    out = lowpass(out, 500 + 2600 * bright)
    fade = np.minimum(1, t / 0.25) * np.minimum(1, (seconds - t) / 0.25)
    return out * fade * 0.07


def pluck(midi, seconds=0.22, bright=1.0):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    tone = saw(hz(midi), t, harmonics=12) * 0.6 + np.sign(np.sin(2 * np.pi * hz(midi) * t)) * 0.25
    tone = lowpass(tone, 1200 + 3800 * bright)
    return tone * env(n, 0.003, 14)


def bass_note(midi, seconds):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    tone = saw(hz(midi), t, harmonics=20) + np.sin(2 * np.pi * hz(midi) * t) * 0.8
    tone = lowpass(tone, 420, order=3)
    return np.tanh(tone * 1.4) * env(n, 0.004, 3.5)


def lead_note(midi, seconds):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t / 0.3)
    phase = np.cumsum(hz(midi) * vib) / RATE
    tone = np.zeros(n)
    for det in (-0.06, 0.06):
        f = 2 ** (det / 12)
        for k in range(1, 18):
            tone += np.sin(2 * np.pi * k * phase * f) / k
    tone = lowpass(tone, 3200)
    e = np.minimum(1, t / 0.02) * np.minimum(1, (seconds - t) / 0.05).clip(0)
    return tone * e * 0.12


def reverb(x, seconds=2.2, mix=0.25):
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    ir = rng.standard_normal((2, n)) * np.exp(-t * 6.9 / seconds)
    ir = np.array([lowpass(ch, 6000) for ch in ir])
    ir /= np.sqrt((ir ** 2).sum(axis=1, keepdims=True))
    wet = np.array([signal.fftconvolve(x, ch)[: len(x)] for ch in ir])
    return np.vstack([x, x]) * (1 - mix) + wet * mix


def build(along=False):
    drums = np.zeros(N)
    bass = np.zeros(N)
    pads = np.zeros(N)
    arps = np.zeros(N)
    lead = np.zeros(N)
    fx = np.zeros(N)
    duck = np.ones(N)

    bars = int(LENGTH / BAR)
    for bar in range(bars):
        start = bar * BAR
        chord = CHORDS[bar % 4]
        root = BASS_ROOTS[bar % 4]
        intro = bar < 3
        groove = 3 <= bar < 14
        riser = bar == 14
        drop = 15 <= bar < 21
        breakdown = 21 <= bar < 26 and not along
        groove = groove or (21 <= bar < 26 and along)
        outro = bar >= 26

        bright = 0.15 + 0.85 * min(1.0, bar / 14) if not drop else 1.0
        pad_gain = 0.45 if breakdown else (1.0 if drop else 0.8)
        if bar < bars - 1:
            place(pads, start, pad_chord(chord, BAR, 0.35 if breakdown else bright), pad_gain)

        # Arpeggio: sixteenths over chord tones, up an octave.
        if not breakdown and bar < bars - 1:
            pattern = [0, 1, 2, 1, 2, 0, 1, 2]
            for s in range(16):
                m = chord[pattern[s % 8]] + 12 + (12 if s % 8 >= 6 else 0)
                g = 0.10 if intro else (0.13 if not drop else 0.10)
                if along and 21 <= bar < 26:
                    g = 0.07  # leave room for the touch instrument's melody
                place(arps, start + s * BEAT / 4, pluck(m, bright=bright), g)

        if groove or drop or (outro and bar < bars - 1):
            for b in range(4):
                t0 = start + b * BEAT
                place(drums, t0, kick(1.2 if drop else 0.8), 0.9 if drop else 0.55)
                if drop or outro:
                    d = np.ones(int(BEAT * RATE))
                    tt = np.arange(len(d)) / RATE
                    d -= 0.55 * np.exp(-tt * 9)
                    i = int(t0 * RATE)
                    duck[i: i + len(d)] = np.minimum(duck[i: i + len(d)], d[: N - i])
                if (bar >= 8 or drop or outro) and b in (1, 3):
                    place(drums, t0, clap(), 0.35 if drop else 0.22)
                for h in range(2):
                    th = t0 + h * BEAT / 2
                    if h == 1 and (drop or outro):
                        place(drums, th, hat(True), 0.12)
                    else:
                        place(drums, th, hat(), 0.16 if drop else 0.10)
            for e8 in range(8):
                octave = 12 if e8 % 2 == 1 and drop else 0
                place(bass, start + e8 * BEAT / 2, bass_note(root + octave, BEAT / 2), 0.32 if drop else 0.24)

        if riser:
            n = int(BAR * RATE)
            t = np.arange(n) / RATE
            noise = rng.uniform(-1, 1, n)
            sweep = np.zeros(n)
            # A rising band of noise, done in short blocks with a moving filter.
            block = 2048
            for k in range(0, n, block):
                f = 400 + 9000 * (k / n) ** 2
                b, a = signal.butter(2, [f / (RATE / 2), min(0.99, f * 1.8 / (RATE / 2))], "band")
                sweep[k: k + block] = signal.lfilter(b, a, noise[k: k + block])
            place(fx, start, sweep * (t / BAR) ** 2, 0.5)
            for s in range(16):
                place(drums, start + s * BEAT / 4, clap(), 0.06 + 0.2 * s / 16)
            place(bass, start, bass_note(root, BAR), 0.2)

        if drop:
            # Lead melody, two bars repeating with a lift on the second pass.
            phrase = [(69, 0, 1.5), (72, 1.5, 0.5), (71, 2, 1), (67, 3, 1),
                      (69, 4, 1), (76, 5, 1), (74, 6, 1.5), (72, 7.5, 0.5)]
            half = (bar - 15) % 2
            lift = 12 if bar >= 19 else 0
            for m, at, dur in phrase:
                if at // 4 == half:
                    place(lead, start + (at - half * 4) * BEAT, lead_note(m + lift, dur * BEAT), 1.0)

    # Final hit at the start of the last bar, left to ring out.
    last = (bars - 1) * BAR
    place(drums, last, kick(1.3), 1.0)
    place(drums, last, clap(), 0.4)
    tail = int((LENGTH - last) * RATE)
    tail_t = np.arange(tail) / RATE
    hit = pad_chord(CHORDS[0], LENGTH - last, 0.8) * np.exp(-tail_t * 0.9) * 1.5
    place(pads, last, hit, 1.0)
    place(bass, last, bass_note(BASS_ROOTS[0], LENGTH - last), 0.35)

    music = (pads + arps) * duck + bass * (0.6 + 0.4 * duck) + lead * duck + fx
    stereo = reverb(music, mix=0.28) + np.vstack([drums, drums]) * 0.95
    # Gentle stereo width on the arpeggio.
    delay = int(0.012 * RATE)
    stereo[1, delay:] += arps[:-delay] * 0.25 * duck[:-delay]
    stereo = np.tanh(stereo * 1.3)
    if along:
        # Sit about 8 dB back while the touch instrument plays, then come up for the outro.
        t = np.arange(N) / RATE
        down = np.clip((t - 42.8) / 1.5, 0, 1) * np.clip((52.0 - t) / 0.4, 0, 1)
        stereo *= 1 - 0.6 * down
    fade_n = int(1.2 * RATE)
    stereo[:, -fade_n:] *= np.linspace(1, 0, fade_n)
    stereo[:, : int(0.05 * RATE)] *= np.linspace(0, 1, int(0.05 * RATE))
    return stereo / np.abs(stereo).max() * 0.89


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out = args[0] if args else "trailer_music.wav"
    data = (build(along="--along" in sys.argv).T * 32767).astype(np.int16)
    with wave.open(out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print("wrote", out)


if __name__ == "__main__":
    main()
