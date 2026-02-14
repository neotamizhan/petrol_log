#!/usr/bin/env python3
"""Generate premium app icon and App Store listing artifacts.

Outputs:
- output/app_store/icon/*
- output/app_store/screenshots/*
- output/app_store/metadata/*

Also refreshes launcher icons used by iOS/Android/Web from the same master icon.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional, Sequence

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "output" / "app_store"
ICON_DIR = OUTPUT_DIR / "icon"
SCREENSHOT_DIR = OUTPUT_DIR / "screenshots"
METADATA_DIR = OUTPUT_DIR / "metadata"
SOURCE_ICON_PATH = ROOT / "assets" / "branding" / "app_icon_source.png"

IOS_ICONSET_JSON = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json"
IOS_ICONSET_DIR = IOS_ICONSET_JSON.parent
ANDROID_ICON_PATHS = [
    ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-mdpi" / "ic_launcher.png",
    ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-hdpi" / "ic_launcher.png",
    ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-xhdpi" / "ic_launcher.png",
    ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-xxhdpi" / "ic_launcher.png",
    ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png",
]
WEB_ICON_PATHS = [
    ROOT / "web" / "icons" / "Icon-192.png",
    ROOT / "web" / "icons" / "Icon-512.png",
    ROOT / "web" / "icons" / "Icon-maskable-192.png",
    ROOT / "web" / "icons" / "Icon-maskable-512.png",
]
LAUNCH_IMAGE_PATHS = {
    ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset" / "LaunchImage.png": (414, 896),
    ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset" / "LaunchImage@2x.png": (828, 1792),
    ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset" / "LaunchImage@3x.png": (1242, 2688),
}

SOURCE_SCREENS = {
    "add": ROOT / "stitch_add_fuel_record_form" / "add_fuel_record_form_(light)" / "screen.png",
    "stats": ROOT / "stitch_add_fuel_record_form" / "fuel_analytics_dashboard" / "screen.png",
    "feed": ROOT / "stitch_add_fuel_record_form" / "petrol_log_records_feed_(light)" / "screen.png",
    "feed_dark": ROOT / "stitch_add_fuel_record_form" / "petrol_log_records_feed" / "screen.png",
    "settings": ROOT / "stitch_add_fuel_record_form" / "petrol_log_settings_(light)" / "screen.png",
}


@dataclass(frozen=True)
class ShotSpec:
    title: str
    subtitle: str
    source_key: str
    palette: tuple[str, str, str, str]


SHOT_SPECS: Sequence[ShotSpec] = (
    ShotSpec(
        title="Log Fuel Stops In Seconds",
        subtitle="Capture odometer, cost, and notes in one focused flow.",
        source_key="add",
        palette=("#F7FCFB", "#DBF6F2", "#E9FFFC", "#C6EFE7"),
    ),
    ShotSpec(
        title="See Efficiency At A Glance",
        subtitle="Instant analytics for mileage, spend trends, and refill rhythm.",
        source_key="stats",
        palette=("#0A1F21", "#0D3A3B", "#0E2F31", "#113E3B"),
    ),
    ShotSpec(
        title="Never Miss A Refill",
        subtitle="Refuel Radar projects your next stop and expected spend.",
        source_key="feed_dark",
        palette=("#071A1B", "#0A3130", "#0D2A2B", "#11413E"),
    ),
    ShotSpec(
        title="Track Every Expense Clearly",
        subtitle="History cards surface cost, volume, and interval with zero clutter.",
        source_key="feed",
        palette=("#F8FAFC", "#E6F6F3", "#F1FCF9", "#D4F0E9"),
    ),
    ShotSpec(
        title="Tune It To Your Region",
        subtitle="Set fuel price, currency, and appearance in a few taps.",
        source_key="settings",
        palette=("#F7FBFE", "#E9F7FF", "#ECF8F5", "#D9EFE8"),
    ),
)

TIERS: dict[str, tuple[int, int]] = {
    "iphone_6.7": (1290, 2796),
    "iphone_6.5": (1242, 2688),
    "ipad_13": (2064, 2752),
}


def ensure_dirs() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    METADATA_DIR.mkdir(parents=True, exist_ok=True)


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def is_dark_color(hex_value: str) -> bool:
    r, g, b = hex_rgb(hex_value)
    luminance = (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    return luminance < 118


def load_font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Avenir Next.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size, index=1 if bold else 0)
        except OSError:
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def gradient_background(width: int, height: int, palette: tuple[str, str, str, str]) -> Image.Image:
    g_vertical = Image.linear_gradient("L").resize((width, height))
    g_horizontal = Image.linear_gradient("L").rotate(90, expand=True).resize((width, height))

    c1, c2, c3, c4 = palette
    layer_a = ImageOps.colorize(g_vertical, c1, c2).convert("RGBA")
    layer_b = ImageOps.colorize(g_horizontal, c3, c4).convert("RGBA")
    bg = Image.blend(layer_a, layer_b, 0.34)

    glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    d.ellipse(
        (
            int(width * -0.15),
            int(height * -0.18),
            int(width * 0.78),
            int(height * 0.46),
        ),
        fill=(255, 255, 255, 64),
    )
    d.ellipse(
        (
            int(width * 0.30),
            int(height * 0.44),
            int(width * 1.02),
            int(height * 1.20),
        ),
        fill=(10, 150, 136, 42),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=max(6, width // 14)))
    return Image.alpha_composite(bg, glow)


def make_droplet_mask(size: int) -> Image.Image:
    scale = 4
    high = size * scale
    mask = Image.new("L", (high, high), 0)
    draw = ImageDraw.Draw(mask)

    cx = high // 2
    circle_r = int(high * 0.24)
    circle_top = int(high * 0.16)
    draw.ellipse((cx - circle_r, circle_top, cx + circle_r, circle_top + circle_r * 2), fill=255)

    shoulder_y = circle_top + int(circle_r * 1.02)
    shoulder_x = int(circle_r * 0.98)
    tip_y = int(high * 0.86)
    draw.polygon(
        [
            (cx - shoulder_x, shoulder_y),
            (cx + shoulder_x, shoulder_y),
            (cx, tip_y),
        ],
        fill=255,
    )

    mask = mask.filter(ImageFilter.GaussianBlur(radius=max(2, int(high * 0.006))))
    mask = mask.point(lambda p: 255 if p > 24 else 0)
    return mask.resize((size, size), Image.Resampling.LANCZOS)


def make_master_icon(size: int = 1024) -> Image.Image:
    canvas = gradient_background(size, size, ("#061A1B", "#0C5D58", "#0A2A2A", "#0F7C74"))

    drop_mask = make_droplet_mask(size)

    shadow_alpha = drop_mask.filter(ImageFilter.GaussianBlur(radius=max(2, int(size * 0.02))))
    shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_layer.paste((0, 0, 0, 78), (0, int(size * 0.018)), shadow_alpha)
    canvas = Image.alpha_composite(canvas, shadow_layer)

    droplet = Image.new("RGBA", (size, size), (245, 255, 252, 255))
    droplet.putalpha(drop_mask)
    canvas = Image.alpha_composite(canvas, droplet)

    edge = drop_mask.filter(ImageFilter.MaxFilter(5))
    edge = ImageChops.subtract(edge, drop_mask)
    edge_layer = Image.new("RGBA", (size, size), (255, 255, 255, 56))
    edge_layer.putalpha(edge)
    canvas = Image.alpha_composite(canvas, edge_layer)

    draw = ImageDraw.Draw(canvas)
    cx = size // 2
    lane_w = int(size * 0.108)
    lane_h = int(size * 0.40)
    lane_top = int(size * 0.30)
    lane_left = cx - lane_w // 2
    lane_box = (lane_left, lane_top, lane_left + lane_w, lane_top + lane_h)
    draw.rounded_rectangle(lane_box, radius=lane_w // 2, fill=(10, 104, 98, 236))

    dash_w = max(6, int(lane_w * 0.28))
    dash_h = max(8, int(size * 0.042))
    gap = max(6, int(size * 0.024))
    y = lane_top + int(size * 0.035)
    for _ in range(4):
        draw.rounded_rectangle(
            (cx - dash_w // 2, y, cx + dash_w // 2, y + dash_h),
            radius=dash_w // 2,
            fill=(223, 255, 250, 240),
        )
        y += dash_h + gap

    draw.ellipse(
        (
            cx - int(size * 0.020),
            lane_top + lane_h - int(size * 0.050),
            cx + int(size * 0.020),
            lane_top + lane_h - int(size * 0.010),
        ),
        fill=(255, 199, 111, 248),
    )

    return canvas.convert("RGB")


def parse_ios_icon_size(size_text: str, scale_text: str) -> int:
    base = float(size_text.split("x", 1)[0])
    scale = int(scale_text.rstrip("x"))
    return int(round(base * scale))


def save_ios_icons(master: Image.Image) -> None:
    data = json.loads(IOS_ICONSET_JSON.read_text(encoding="utf-8"))
    seen: set[str] = set()
    for image_spec in data.get("images", []):
        filename = image_spec.get("filename")
        if not filename or filename in seen:
            continue
        size = parse_ios_icon_size(image_spec["size"], image_spec["scale"])
        resized = master.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(IOS_ICONSET_DIR / filename, format="PNG")
        seen.add(filename)


def save_android_and_web_icons(master: Image.Image) -> None:
    for path in [*ANDROID_ICON_PATHS, *WEB_ICON_PATHS]:
        with Image.open(path) as target:
            size = target.size
        resized = master.resize(size, Image.Resampling.LANCZOS)
        resized.save(path, format="PNG")


def save_launch_images(master: Image.Image, icon_with_alpha: Optional[Image.Image] = None) -> None:
    for path, size in LAUNCH_IMAGE_PATHS.items():
        w, h = size
        launch = gradient_background(w, h, ("#06191A", "#0B4A48", "#0A2424", "#0F6B65")).convert("RGB")
        icon_size = int(min(w, h) * 0.33)
        source = icon_with_alpha if icon_with_alpha is not None else master.convert("RGBA")
        icon = source.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        # Ensure corners blend cleanly on launch backgrounds.
        corner_mask = rounded_rect_mask((icon_size, icon_size), radius=max(12, int(icon_size * 0.18)))
        icon_alpha = ImageChops.multiply(icon.split()[-1], corner_mask)
        icon.putalpha(icon_alpha)
        x = (w - icon_size) // 2
        y = int(h * 0.28)
        launch.paste(icon, (x, y), icon)
        launch.save(path, format="PNG")


def rounded_rect_mask(size: tuple[int, int], radius: int) -> Image.Image:
    w, h = size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    return mask


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    if not words:
        return []
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        candidate = f"{current} {word}"
        width = draw.textbbox((0, 0), candidate, font=font)[2]
        if width <= max_width:
            current = candidate
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def draw_centered_lines(
    draw: ImageDraw.ImageDraw,
    lines: Iterable[str],
    *,
    center_x: int,
    start_y: int,
    font: ImageFont.ImageFont,
    fill: tuple[int, int, int, int],
    line_gap: int,
) -> int:
    y = start_y
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        width = bbox[2] - bbox[0]
        draw.text((center_x - width // 2, y), line, font=font, fill=fill)
        y += (bbox[3] - bbox[1]) + line_gap
    return y


def render_shot(
    canvas_size: tuple[int, int],
    spec: ShotSpec,
    source_img: Image.Image,
    icon_small: Image.Image,
    out_path: Path,
) -> None:
    width, height = canvas_size
    canvas = gradient_background(width, height, spec.palette)
    draw = ImageDraw.Draw(canvas)

    title_font = load_font(max(56, width // 14), bold=True)
    subtitle_font = load_font(max(30, width // 34), bold=False)
    badge_font = load_font(max(24, width // 44), bold=True)

    chip_h = max(58, height // 35)
    chip_w = max(250, width // 3)
    chip_x = (width - chip_w) // 2
    chip_y = max(66, height // 34)
    draw.rounded_rectangle(
        (chip_x, chip_y, chip_x + chip_w, chip_y + chip_h),
        radius=chip_h // 2,
        fill=(255, 255, 255, 178),
        outline=(255, 255, 255, 200),
        width=max(1, width // 520),
    )

    icon_edge = chip_h - max(10, chip_h // 6)
    icon_resized = icon_small.resize((icon_edge, icon_edge), Image.Resampling.LANCZOS)
    icon_y = chip_y + (chip_h - icon_edge) // 2
    icon_x = chip_x + max(10, chip_h // 6)
    canvas.paste(icon_resized, (icon_x, icon_y))

    badge_text = "PETROL LOG"
    label_x = icon_x + icon_edge + max(12, width // 120)
    label_y = chip_y + (chip_h - (draw.textbbox((0, 0), badge_text, font=badge_font)[3])) // 2
    draw.text((label_x, label_y), badge_text, font=badge_font, fill=(8, 40, 40, 240))

    text_top = chip_y + chip_h + max(46, height // 40)
    max_text_w = int(width * (0.86 if width < 1800 else 0.80))
    title_lines = wrap_text(draw, spec.title, title_font, max_text_w)
    subtitle_lines = wrap_text(draw, spec.subtitle, subtitle_font, max_text_w)
    dark_theme = is_dark_color(spec.palette[0])
    title_fill = (238, 255, 252, 246) if dark_theme else (8, 30, 31, 245)
    subtitle_fill = (196, 235, 230, 226) if dark_theme else (19, 79, 79, 210)

    y = draw_centered_lines(
        draw,
        title_lines,
        center_x=width // 2,
        start_y=text_top,
        font=title_font,
        fill=title_fill,
        line_gap=max(10, height // 210),
    )
    y += max(12, height // 120)
    y = draw_centered_lines(
        draw,
        subtitle_lines,
        center_x=width // 2,
        start_y=y,
        font=subtitle_font,
        fill=subtitle_fill,
        line_gap=max(6, height // 260),
    )

    is_ipad = width >= 1800
    phone_w = int(width * (0.66 if not is_ipad else 0.46))
    phone_h = int(phone_w * 2.08)
    max_phone_h = int(height * (0.60 if not is_ipad else 0.56))
    if phone_h > max_phone_h:
        phone_h = max_phone_h
        phone_w = int(phone_h / 2.08)

    phone_x = (width - phone_w) // 2
    phone_y = y + max(26, height // 90)
    if phone_y + phone_h > height - max(40, height // 38):
        phone_y = height - phone_h - max(40, height // 38)

    shadow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    shadow_box = (
        phone_x,
        phone_y + max(8, height // 220),
        phone_x + phone_w,
        phone_y + phone_h + max(8, height // 220),
    )
    sdraw.rounded_rectangle(shadow_box, radius=max(24, phone_w // 11), fill=(0, 0, 0, 105))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(8, width // 78)))
    canvas = Image.alpha_composite(canvas, shadow)

    body_color = (19, 26, 28, 255)
    frame_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(frame_layer)
    corner = max(26, phone_w // 10)
    fdraw.rounded_rectangle((phone_x, phone_y, phone_x + phone_w, phone_y + phone_h), radius=corner, fill=body_color)

    screen_margin_x = max(14, phone_w // 24)
    screen_margin_top = max(20, phone_h // 30)
    screen_margin_bottom = max(16, phone_h // 38)
    sx0 = phone_x + screen_margin_x
    sy0 = phone_y + screen_margin_top
    sx1 = phone_x + phone_w - screen_margin_x
    sy1 = phone_y + phone_h - screen_margin_bottom
    screen_w = sx1 - sx0
    screen_h = sy1 - sy0

    fitted = ImageOps.fit(source_img, (screen_w, screen_h), method=Image.Resampling.LANCZOS, centering=(0.5, 0.03))
    screen_mask = rounded_rect_mask((screen_w, screen_h), radius=max(20, phone_w // 16))
    frame_layer.paste(fitted, (sx0, sy0), screen_mask)

    notch_w = max(72, phone_w // 3)
    notch_h = max(24, phone_h // 35)
    notch_x = phone_x + (phone_w - notch_w) // 2
    notch_y = phone_y + max(10, phone_h // 42)
    fdraw.rounded_rectangle(
        (notch_x, notch_y, notch_x + notch_w, notch_y + notch_h),
        radius=notch_h // 2,
        fill=(15, 20, 22, 240),
    )

    canvas = Image.alpha_composite(canvas, frame_layer)

    if is_ipad:
        # Add a supporting secondary card to use wide iPad canvas intentionally.
        aux_w = int(width * 0.30)
        aux_h = int(aux_w * 1.84)
        aux_x = phone_x + phone_w + max(26, width // 65)
        aux_y = phone_y + int(phone_h * 0.12)
        if aux_x + aux_w < width - 28:
            aux_shadow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
            adraw = ImageDraw.Draw(aux_shadow)
            adraw.rounded_rectangle(
                (aux_x, aux_y + 8, aux_x + aux_w, aux_y + aux_h + 8),
                radius=max(20, aux_w // 12),
                fill=(0, 0, 0, 85),
            )
            aux_shadow = aux_shadow.filter(ImageFilter.GaussianBlur(radius=max(6, width // 120)))
            canvas = Image.alpha_composite(canvas, aux_shadow)

            card = Image.new("RGBA", (width, height), (0, 0, 0, 0))
            cdraw = ImageDraw.Draw(card)
            cdraw.rounded_rectangle(
                (aux_x, aux_y, aux_x + aux_w, aux_y + aux_h),
                radius=max(20, aux_w // 12),
                fill=(255, 255, 255, 218),
            )
            mini = ImageOps.fit(source_img, (aux_w - 36, aux_h - 36), method=Image.Resampling.LANCZOS, centering=(0.5, 0.08))
            card.paste(mini, (aux_x + 18, aux_y + 18), rounded_rect_mask((aux_w - 36, aux_h - 36), 18))
            canvas = Image.alpha_composite(canvas, card)

    canvas.convert("RGB").save(out_path, format="PNG")


def generate_screenshots(master_icon: Image.Image) -> None:
    icon_small = master_icon.resize((160, 160), Image.Resampling.LANCZOS)

    loaded_sources = {key: Image.open(path).convert("RGB") for key, path in SOURCE_SCREENS.items()}
    try:
        for tier_name, size in TIERS.items():
            tier_dir = SCREENSHOT_DIR / tier_name
            tier_dir.mkdir(parents=True, exist_ok=True)
            for index, spec in enumerate(SHOT_SPECS, start=1):
                out_path = tier_dir / f"{index:02d}.png"
                render_shot(size, spec, loaded_sources[spec.source_key], icon_small, out_path)
    finally:
        for image in loaded_sources.values():
            image.close()


def write_metadata_files() -> None:
    listing = """# App Store Listing Draft - Petrol Log

## App Name
Petrol Log

## Subtitle (<= 30 chars)
Fuel Tracker and Mileage

## Promotional Text (<= 170 chars)
Track every fuel stop in seconds and keep your mileage, spend, and refill rhythm visible at all times with a clean interface built for daily driving.

## Keywords (<= 100 chars)
fuel tracker,mileage,gas log,car expenses,odometer,petrol,cost tracking,refill

## Description
Petrol Log is a minimal fuel tracker for drivers who care about clean records and accurate insights.

What you can do:
- Log each fill with date, odometer, cost, and notes.
- Review efficiency and refill intervals automatically.
- Analyze monthly fuel spending and mileage trends.
- Use Refuel Radar to estimate your next refill window and projected cost.
- Keep everything in your preferred currency and theme.

Built for speed, clarity, and long-term tracking.
"""

    captions = """# Screenshot Caption Set

1. Log Fuel Stops In Seconds
Capture odometer, cost, and notes in one focused flow.

2. See Efficiency At A Glance
Instant analytics for mileage, spend trends, and refill rhythm.

3. Never Miss A Refill
Refuel Radar projects your next stop and expected spend.

4. Track Every Expense Clearly
History cards surface cost, volume, and interval with zero clutter.

5. Tune It To Your Region
Set fuel price, currency, and appearance in a few taps.
"""

    readme = """# Generated Asset Pack

## Icon
- output/app_store/icon/petrol_log_icon_1024.png
- output/app_store/icon/petrol_log_icon_preview.png

## App Store Screenshots
- output/app_store/screenshots/iphone_6.7/
- output/app_store/screenshots/iphone_6.5/
- output/app_store/screenshots/ipad_13/

## Launcher Icons Updated In Project
- ios/Runner/Assets.xcassets/AppIcon.appiconset/*
- android/app/src/main/res/mipmap-*/ic_launcher.png
- web/icons/Icon-*.png

## Notes
- Generated from one brand master icon for consistency.
- iPad screenshots included because the current app supports iPad.
- Brand icon source: assets/branding/app_icon_source.png
"""

    (METADATA_DIR / "app_store_listing.md").write_text(listing, encoding="utf-8")
    (METADATA_DIR / "screenshot_captions.md").write_text(captions, encoding="utf-8")
    (OUTPUT_DIR / "README.md").write_text(readme, encoding="utf-8")


def generate_icon_files() -> Image.Image:
    if not SOURCE_ICON_PATH.exists():
        raise FileNotFoundError(
            f"Missing source icon: {SOURCE_ICON_PATH}. Add your brand icon before generating."
        )

    with Image.open(SOURCE_ICON_PATH) as source_icon:
        source_rgba = source_icon.convert("RGBA")
        source_rgb = source_rgba.convert("RGB")

        # Trim bright backdrop from exported mockup-style source images.
        gray = ImageOps.grayscale(source_rgb)
        non_backdrop_mask = gray.point(lambda p: 255 if p < 245 else 0)
        bbox = non_backdrop_mask.getbbox()
        if bbox is not None:
            source_rgb = source_rgb.crop(bbox)
            source_rgba = source_rgba.crop(bbox)

        master = ImageOps.fit(
            source_rgb,
            (1024, 1024),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )
        master_rgba = ImageOps.fit(
            source_rgba,
            (1024, 1024),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )
    master.save(ICON_DIR / "petrol_log_icon_1024.png", format="PNG")

    preview = Image.new("RGB", (1600, 900), "#F2F7F6")
    icon_large = master.resize((560, 560), Image.Resampling.LANCZOS)
    shadow = Image.new("RGBA", preview.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    x = (preview.width - icon_large.width) // 2
    y = (preview.height - icon_large.height) // 2
    sdraw.rounded_rectangle(
        (x - 8, y + 18, x + icon_large.width + 8, y + icon_large.height + 30),
        radius=130,
        fill=(0, 0, 0, 60),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=24))
    preview = Image.alpha_composite(preview.convert("RGBA"), shadow)
    preview.paste(icon_large, (x, y))

    label_font = load_font(58, bold=True)
    subtitle_font = load_font(28, bold=False)
    draw = ImageDraw.Draw(preview)
    title = "Petrol Log Icon"
    subtitle = "Source: user-provided brand icon"
    tbox = draw.textbbox((0, 0), title, font=label_font)
    sbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    draw.text(((preview.width - (tbox[2] - tbox[0])) // 2, 70), title, font=label_font, fill=(12, 41, 40))
    draw.text(((preview.width - (sbox[2] - sbox[0])) // 2, 144), subtitle, font=subtitle_font, fill=(57, 88, 85))
    preview.convert("RGB").save(ICON_DIR / "petrol_log_icon_preview.png", format="PNG")

    save_ios_icons(master)
    save_android_and_web_icons(master)
    save_launch_images(master, master_rgba)
    return master


def main() -> None:
    ensure_dirs()
    master = generate_icon_files()
    generate_screenshots(master)
    write_metadata_files()
    print("Generated App Store assets in:", OUTPUT_DIR)


if __name__ == "__main__":
    main()
