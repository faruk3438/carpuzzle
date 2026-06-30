import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 44100
OUT_DIR = Path("assets/sounds")


def _write_wav(name, samples, gain=1.0):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    shaped = [math.tanh(s * 1.35) for s in samples]
    peak = max(0.001, max(abs(s) for s in shaped))
    scale = (0.74 * gain) / peak
    with wave.open(str(OUT_DIR / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        for sample in shaped:
            value = int(max(-1.0, min(1.0, sample * scale)) * 32767)
            wav.writeframes(struct.pack("<h", value))


def _env(t, attack, release, duration):
    if t < attack:
        return t / attack
    if t > duration - release:
        return max(0.0, (duration - t) / release)
    return 1.0


def _smooth_noise(rng, total, mix):
    value = 0.0
    out = []
    for _ in range(total):
        value = value * mix + rng.uniform(-1.0, 1.0) * (1.0 - mix)
        out.append(value)
    return out


def _highpass(samples, amount=0.995):
    prev_in = 0.0
    prev_out = 0.0
    out = []
    for sample in samples:
        value = amount * (prev_out + sample - prev_in)
        out.append(value)
        prev_in = sample
        prev_out = value
    return out


def _lowpass(samples, mix=0.9):
    value = 0.0
    out = []
    for sample in samples:
        value = value * mix + sample * (1.0 - mix)
        out.append(value)
    return out


def car_slide():
    rng = random.Random(120)
    duration = 0.42
    total = int(SAMPLE_RATE * duration)
    scrub = _highpass(_smooth_noise(rng, total, 0.88), 0.985)
    dust = _lowpass(_smooth_noise(rng, total, 0.62), 0.74)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        p = t / duration
        slide_env = math.sin(math.pi * p) ** 0.42
        motor_freq = 132 - 28 * p
        motor = math.sin(2 * math.pi * motor_freq * t) * 0.11
        tire = scrub[i] * 0.48 * slide_env
        road = dust[i] * 0.11 * (1.0 - p) ** 0.35
        tick = 0.0
        if i % 1737 < 38:
            tick = rng.uniform(-0.25, 0.25) * (1.0 - p)
        samples.append((tire + road + motor + tick) * _env(t, 0.025, 0.12, duration))
    return samples


def car_whoosh():
    rng = random.Random(241)
    duration = 0.30
    total = int(SAMPLE_RATE * duration)
    air = _highpass(_smooth_noise(rng, total, 0.92), 0.997)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        p = t / duration
        lift = math.sin(math.pi * p) ** 1.15
        tail = math.exp(-max(0.0, p - 0.34) * 11.0)
        sweep_up = 360 + 1620 * (1.0 - math.cos(math.pi * min(1.0, p * 1.12))) * 0.5
        sweep_down = 1480 - 720 * p
        airy_tone = math.sin(2 * math.pi * sweep_up * t) * 0.034 * lift
        shimmer = math.sin(2 * math.pi * sweep_down * t) * 0.014 * lift * tail
        soft_air = air[i] * 0.085 * lift * tail
        samples.append(
            (airy_tone + shimmer + soft_air)
            * _env(t, 0.055, 0.11, duration)
        )
    return samples


def car_crash():
    rng = random.Random(361)
    duration = 0.42
    total = int(SAMPLE_RATE * duration)
    grit = _highpass(_smooth_noise(rng, total, 0.50), 0.970)
    dust = _lowpass(_smooth_noise(rng, total, 0.70), 0.80)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        p = t / duration
        impact = math.exp(-p * 21.0)
        tail = math.exp(-p * 5.8)
        hit = 1.0 if i < int(SAMPLE_RATE * 0.018) else 0.0
        click = rng.uniform(-1.0, 1.0) * hit * (1.0 - p * 12.0)
        thump = (
            math.sin(2 * math.pi * 54 * t)
            + math.sin(2 * math.pi * 86 * t) * 0.55
            + math.sin(2 * math.pi * 132 * t) * 0.22
        ) * 1.26 * impact
        crack = grit[i] * 1.35 * impact
        metal = (
            math.sin(2 * math.pi * 420 * t)
            + math.sin(2 * math.pi * 760 * t) * 0.55
            + math.sin(2 * math.pi * 1240 * t) * 0.34
        ) * 0.26 * tail
        ring_env = math.exp(-p * 7.2)
        clank = (
            math.sin(2 * math.pi * 1550 * t)
            + math.sin(2 * math.pi * 2210 * t) * 0.70
            + math.sin(2 * math.pi * 2860 * t) * 0.42
        ) * 0.22 * ring_env
        debris = dust[i] * 0.30 * math.exp(-p * 3.8)
        samples.append(
            (click * 0.72 + thump + crack + metal + clank + debris)
            * _env(t, 0.0008, 0.12, duration)
        )
    return samples


def main():
    _write_wav("car_slide.wav", car_slide())
    _write_wav("car_whoosh.wav", car_whoosh(), gain=0.38)
    _write_wav("car_crash.wav", car_crash())


if __name__ == "__main__":
    main()
