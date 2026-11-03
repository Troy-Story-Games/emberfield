"""Builds the 1920x1080 store trailer from the frames tools/trailer.gd records.

    python tools/make_trailer.py <frames dir> <out.mp4>

The frames dir holds Movie Maker's frameNNNNNNNN.png files and frame.wav. The portrait
footage sits on the right, over a blurred copy of itself, with captions on the left.
Needs ffmpeg on PATH and Pillow. Uses Segoe UI (Windows) for the captions.
"""

import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

FPS = 30
START_FRAME = 90  # matches START_FRAME in tools/trailer.gd
LENGTH = 58.0
W, H = 1920, 1080
PHONE_H = 980
PHONE_W = round(PHONE_H * 1080 / 1920 / 2) * 2
PHONE_X = 1160
PHONE_Y = (H - PHONE_H) // 2
RADIUS = 44
BEZEL = 10
TEXT_X = 150
ACCENT = (255, 140, 60)
FONTS = "C:/Windows/Fonts/"

# (start, end, title, subtitle)
CAPTIONS = [
    (0.4, 5.8, "Emberfield", "Particle art at your fingertips"),
    (6.2, 15.8, "14 touch-driven modes", "Swirl, swallow and explode\nthousands of glowing particles."),
    (16.2, 27.2, "Make it yours", "Pick the colors, particle count,\nsize and trail length."),
    (27.6, 41.8, "Dances to your music", "Listens to the microphone, or to\nmusic playing on your phone."),
    (42.2, 51.8, "Play it like an instrument", "Turn on the touch instrument\nand every touch plays a note."),
    (52.2, LENGTH, "Emberfield", "Free  \u00b7  Open source  \u00b7  No ads"),
]


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def caption_png(path, title, subtitle, big):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    title_font = font("segoeuib.ttf", 112 if big else 76)
    sub_font = font("segoeuisl.ttf", 44)
    title_h = d.textbbox((0, 0), title, font=title_font)[3]
    sub_box = d.multiline_textbbox((0, 0), subtitle, font=sub_font, spacing=14)
    block = title_h + 28 + 6 + 28 + sub_box[3]
    y = (H - block) // 2
    d.text((TEXT_X, y), title, font=title_font, fill=(255, 255, 255, 255))
    y += title_h + 28
    d.rounded_rectangle((TEXT_X, y, TEXT_X + 96, y + 6), radius=3, fill=ACCENT + (255,))
    y += 6 + 28
    d.multiline_text((TEXT_X, y), subtitle, font=sub_font, fill=(255, 255, 255, 215), spacing=14)
    img.save(path)


def phone_pngs(mask_path, bezel_path):
    mask = Image.new("L", (PHONE_W, PHONE_H), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, PHONE_W - 1, PHONE_H - 1), radius=RADIUS, fill=255)
    mask.save(mask_path)
    bw, bh = PHONE_W + BEZEL * 2, PHONE_H + BEZEL * 2
    bezel = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    d = ImageDraw.Draw(bezel)
    d.rounded_rectangle((0, 0, bw - 1, bh - 1), radius=RADIUS + BEZEL, fill=(14, 14, 16, 255), outline=(70, 70, 76, 255), width=2)
    bezel.save(bezel_path)


def main():
    frames, out = sys.argv[1], sys.argv[2]
    tmp = tempfile.mkdtemp(prefix="trailer_")
    mask, bezel = os.path.join(tmp, "mask.png"), os.path.join(tmp, "bezel.png")
    phone_pngs(mask, bezel)
    caps = []
    for k, (a, b, title, sub) in enumerate(CAPTIONS):
        path = os.path.join(tmp, "cap%d.png" % k)
        caption_png(path, title, sub, big=title == "Emberfield")
        caps.append((path, a, b))

    cmd = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "warning", "-stats",
        "-framerate", str(FPS), "-start_number", str(START_FRAME), "-i", os.path.join(frames, "frame%08d.png"),
        "-ss", str(START_FRAME / FPS), "-i", os.path.join(frames, "frame.wav"),
        "-i", mask, "-i", bezel,
    ]
    for path, _, _ in caps:
        cmd += ["-loop", "1", "-framerate", str(FPS), "-t", str(LENGTH), "-i", path]

    g = [
        "[0:v]split[a][b]",
        # Background: the same footage, filling the frame, blurred and dimmed.
        "[a]scale=%d:-2,crop=%d:%d,boxblur=36:3,eq=brightness=-0.18:saturation=1.25[bg]" % (W, W, H),
        "[b]scale=%d:%d,format=rgba[ph0]" % (PHONE_W, PHONE_H),
        "[2:v]format=gray,scale=%d:%d[m]" % (PHONE_W, PHONE_H),
        "[ph0][m]alphamerge[ph]",
        "[bg][3:v]overlay=%d:%d[v0]" % (PHONE_X - BEZEL, PHONE_Y - BEZEL),
        "[v0][ph]overlay=%d:%d[v1]" % (PHONE_X, PHONE_Y),
    ]
    last = "v1"
    for k, (_, a, b) in enumerate(caps):
        fade_out = "" if b >= LENGTH else ",fade=t=out:st=%.2f:d=0.4:alpha=1" % (b - 0.4)
        g.append("[%d:v]format=rgba,fade=t=in:st=%.2f:d=0.4:alpha=1%s[c%d]" % (4 + k, a, fade_out, k))
        g.append("[%s][c%d]overlay=0:0:enable='between(t,%.2f,%.2f)'[v%d]" % (last, k, a, b, k + 2))
        last = "v%d" % (k + 2)
    g.append("[%s]fade=t=out:st=%.2f:d=0.8,format=yuv420p[vout]" % (last, LENGTH - 0.8))
    g.append("[1:a]afade=t=in:d=0.05,loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[aout]")

    cmd += [
        "-filter_complex", ";".join(g),
        "-map", "[vout]", "-map", "[aout]",
        "-t", str(LENGTH), "-r", str(FPS),
        "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-profile:v", "high", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "256k", "-movflags", "+faststart",
        out,
    ]
    subprocess.run(cmd, check=True)
    print("wrote", out)


if __name__ == "__main__":
    main()
