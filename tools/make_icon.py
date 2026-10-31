"""Generates the Emberfield icon SVGs: a spiral of embers, hot at the core.

python tools/make_icon.py  ->  icon/icon.svg, icon/icon_foreground.svg, icon/icon_background.svg
Then rasterize with: Godot --headless --path . -s res://tools/make_icons.gd
Only radial gradients and plain shapes are used, since Godot's SVG renderer has no filters.
"""
import math
import random
from pathlib import Path

SIZE = 512
CENTER = SIZE / 2
OUT = Path(__file__).resolve().parent.parent / "icon"

# Hot core to cool edge: white-gold, amber, orange, ember red.
STOPS = [(0.0, (255, 246, 214)), (0.25, (255, 200, 90)), (0.55, (255, 128, 40)), (1.0, (214, 46, 26))]


def heat(t):
    for (t0, c0), (t1, c1) in zip(STOPS, STOPS[1:]):
        if t <= t1:
            k = (t - t0) / (t1 - t0)
            return tuple(round(a + (b - a) * k) for a, b in zip(c0, c1))
    return STOPS[-1][1]


def hexc(c):
    return "#%02x%02x%02x" % c


def background():
    return (
        '<radialGradient id="bg" cx="50%" cy="46%" r="72%">'
        '<stop offset="0%" stop-color="#2a1208"/>'
        '<stop offset="45%" stop-color="#0d0605"/>'
        '<stop offset="100%" stop-color="#030202"/></radialGradient>',
        f'<rect width="{SIZE}" height="{SIZE}" fill="url(#bg)"/>',
    )


def foreground(scale):
    """Spiral embers. scale < 1 shrinks toward the center for the adaptive safe zone."""
    rng = random.Random(7)
    defs = [
        '<radialGradient id="core" cx="50%" cy="50%" r="50%">'
        '<stop offset="0%" stop-color="#ffd27a" stop-opacity="0.95"/>'
        '<stop offset="30%" stop-color="#ff7a26" stop-opacity="0.45"/>'
        '<stop offset="100%" stop-color="#ff4a1a" stop-opacity="0"/></radialGradient>'
    ]
    body = [f'<circle cx="{CENTER}" cy="{CENTER}" r="{200 * scale:.1f}" fill="url(#core)"/>']
    arms = 3
    per_arm = 90
    for arm in range(arms):
        for k in range(per_arm):
            t = k / (per_arm - 1)
            radius = (14 + 205 * t ** 1.15 + rng.uniform(-10, 10) * t) * scale
            angle = arm * math.tau / arms + t * 2.6 * math.pi + rng.uniform(-0.09, 0.09)
            x = CENTER + math.cos(angle) * radius
            y = CENTER + math.sin(angle) * radius
            dot = (7.5 - 5.5 * t) * scale * rng.uniform(0.55, 1.25)
            color = heat(min(1.0, t * 1.1 + rng.uniform(-0.05, 0.05)))
            # Trail: a tapered streak behind the ember, along the spiral.
            back = angle - rng.uniform(0.2, 0.42) * (1.0 - 0.45 * t)
            bx = CENTER + math.cos(back) * radius * 0.97
            by = CENTER + math.sin(back) * radius * 0.97
            alpha = 0.4 * (1.0 - 0.5 * t)
            body.append(
                f'<line x1="{bx:.1f}" y1="{by:.1f}" x2="{x:.1f}" y2="{y:.1f}" stroke="{hexc(color)}" '
                f'stroke-opacity="{alpha:.2f}" stroke-width="{dot * 0.8:.1f}" stroke-linecap="round"/>'
            )
            if t < 0.45:
                body.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{dot * 2.2:.1f}" fill="{hexc(color)}" fill-opacity="0.12"/>')
            body.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{dot:.1f}" fill="{hexc(color)}"/>')
    for _ in range(70):
        radius = rng.uniform(60, 235) * scale
        angle = rng.uniform(0, math.tau)
        x = CENTER + math.cos(angle) * radius
        y = CENTER + math.sin(angle) * radius
        color = heat(rng.uniform(0.3, 1.0))
        body.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rng.uniform(1.2, 3.0) * scale:.1f}" fill="{hexc(color)}" fill-opacity="{rng.uniform(0.4, 0.9):.2f}"/>')
    body.append(f'<circle cx="{CENTER}" cy="{CENTER}" r="{13 * scale:.1f}" fill="#fff8e6"/>')
    return defs, body


def svg(defs, body):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">\n'
        f"<defs>{''.join(defs)}</defs>\n" + "\n".join(body) + "\n</svg>\n"
    )


def main():
    bg_def, bg_rect = background()
    fg_defs, fg_body = foreground(1.0)
    (OUT / "icon.svg").write_text(svg([bg_def] + fg_defs, [bg_rect] + fg_body))
    # Adaptive icons crop to a circle or squircle; keep the art inside the central ~62%.
    safe_defs, safe_body = foreground(0.62)
    (OUT / "icon_foreground.svg").write_text(svg(safe_defs, safe_body))
    (OUT / "icon_background.svg").write_text(svg([bg_def], [bg_rect]))


if __name__ == "__main__":
    main()
