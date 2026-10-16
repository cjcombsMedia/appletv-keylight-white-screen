#!/usr/bin/env python3
"""Generate the tvOS asset catalog (layered parallax icon + top shelf art) for Keylight."""
import json, math, os, struct, sys, zlib

ROOT = sys.argv[1]
CAT = os.path.join(ROOT, "Assets.xcassets")
BRAND = os.path.join(CAT, "App Icon & Top Shelf Image.brandassets")
INFO = {"author": "xcode", "version": 1}


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)
        f.write("\n")


def write_png(path, width, height, rows):
    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw += row

    def chunk(typ, data):
        out = struct.pack(">I", len(data)) + typ + data
        return out + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 6))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


def clamp8(v):
    return max(0, min(255, int(round(v))))


def smoothstep(edge0, edge1, x):
    if edge1 == edge0:
        return 0.0
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- icon layers

def rounded_rect_coverage(px, py, cx, cy, hw, hh, radius, feather):
    """Signed-distance coverage of a rounded rectangle, with a soft edge."""
    dx = abs(px - cx) - (hw - radius)
    dy = abs(py - cy) - (hh - radius)
    dx = max(dx, 0.0)
    dy = max(dy, 0.0)
    dist = math.hypot(dx, dy) - radius
    if abs(px - cx) <= hw - radius and abs(py - cy) <= hh - radius:
        dist = -min(hw - radius - abs(px - cx), hh - radius - abs(py - cy)) - radius
    return 1.0 - smoothstep(-feather, feather, dist)


def icon_rows(w, h, layer):
    cx, cy = w / 2.0, h / 2.0
    for y in range(h):
        row = bytearray()
        for x in range(w):
            if layer == "back":
                t = y / max(1, h - 1)
                r = 22 - 10 * t
                g = 24 - 11 * t
                b = 29 - 13 * t
                row += bytes((clamp8(r), clamp8(g), clamp8(b), 255))
            elif layer == "middle":
                nx = (x - cx) / (0.42 * w)
                ny = (y - cy) / (0.60 * h)
                d = math.hypot(nx, ny)
                a = (1.0 - smoothstep(0.30, 0.95, d)) ** 1.35
                warm = smoothstep(0.0, 1.0, y / max(1, h - 1))
                r = 255
                g = 226 - 22 * warm
                b = 196 - 60 * warm
                row += bytes((clamp8(r), clamp8(g), clamp8(b), clamp8(a * 235)))
            else:  # front softbox
                hw, hh = 0.30 * w, 0.27 * h
                radius = 0.075 * w
                cov = rounded_rect_coverage(x + 0.5, y + 0.5, cx, cy, hw, hh,
                                            radius, 0.030 * w)
                t = (y - (cy - hh)) / (2 * hh)
                t = max(0.0, min(1.0, t))
                r = 255
                g = 252 - 14 * t
                b = 244 - 40 * t
                row += bytes((clamp8(r), clamp8(g), clamp8(b), clamp8(cov * 255)))
        yield row


def build_imagestack(path, sizes):
    """sizes: list of (scale_label, width, height)."""
    write_json(os.path.join(path, "Contents.json"), {
        "layers": [{"filename": "Front.imagestacklayer"},
                   {"filename": "Middle.imagestacklayer"},
                   {"filename": "Back.imagestacklayer"}],
        "info": INFO,
    })
    for layer_name, key in (("Front", "front"), ("Middle", "middle"), ("Back", "back")):
        layer_dir = os.path.join(path, layer_name + ".imagestacklayer")
        write_json(os.path.join(layer_dir, "Contents.json"), {"info": INFO})
        images = []
        for scale, w, h in sizes:
            filename = "%s%s.png" % (key, "" if scale == "1x" else "@" + scale)
            write_png(os.path.join(layer_dir, "Content.imageset", filename), w, h,
                      icon_rows(w, h, key))
            images.append({"filename": filename, "idiom": "tv", "scale": scale})
        write_json(os.path.join(layer_dir, "Content.imageset", "Contents.json"),
                   {"images": images, "info": INFO})


# ------------------------------------------------------------- top shelf art

def top_shelf_png(path, w, h):
    """Separable glow so large canvases stay fast: amplitude varies by row, shape by column."""
    cx = w / 2.0
    xprofile = []
    for x in range(w):
        nx = (x - cx) / (0.55 * w)
        xprofile.append((1.0 - smoothstep(0.0, 1.0, abs(nx))) ** 1.8)

    cache = {}
    rows = []
    for y in range(h):
        t = y / max(1, h - 1)
        ny = (y - h * 0.42) / (0.62 * h)
        amp = (1.0 - smoothstep(0.0, 1.0, abs(ny))) ** 1.6
        level = int(amp * 96)
        if level not in cache:
            a = level / 96.0
            row = bytearray()
            for x in range(w):
                glow = a * xprofile[x]
                r = 18 - 8 * t + 232 * glow
                g = 20 - 9 * t + 214 * glow
                b = 25 - 11 * t + 180 * glow
                row += bytes((clamp8(r), clamp8(g), clamp8(b), 255))
            cache[level] = bytes(row)
        rows.append(cache[level])
    write_png(path, w, h, rows)


def build_imageset(path, sizes, basename):
    images = []
    for scale, w, h in sizes:
        filename = "%s%s.png" % (basename, "" if scale == "1x" else "@" + scale)
        top_shelf_png(os.path.join(path, filename), w, h)
        images.append({"filename": filename, "idiom": "tv", "scale": scale})
    write_json(os.path.join(path, "Contents.json"), {"images": images, "info": INFO})


# ------------------------------------------------------------------- catalog

write_json(os.path.join(CAT, "Contents.json"), {"info": INFO})

write_json(os.path.join(BRAND, "Contents.json"), {
    "assets": [
        {"filename": "App Icon - App Store.imagestack", "idiom": "tv",
         "role": "primary-app-icon", "size": "1280x768"},
        {"filename": "App Icon.imagestack", "idiom": "tv",
         "role": "primary-app-icon", "size": "400x240"},
        {"filename": "Top Shelf Image Wide.imageset", "idiom": "tv",
         "role": "top-shelf-image-wide", "size": "2320x720"},
        {"filename": "Top Shelf Image.imageset", "idiom": "tv",
         "role": "top-shelf-image", "size": "1920x720"},
    ],
    "info": INFO,
})

print("app icon (400x240 @1x/@2x)…")
build_imagestack(os.path.join(BRAND, "App Icon.imagestack"),
                 [("1x", 400, 240), ("2x", 800, 480)])
print("app store icon (1280x768)…")
build_imagestack(os.path.join(BRAND, "App Icon - App Store.imagestack"),
                 [("1x", 1280, 768)])
print("top shelf…")
build_imageset(os.path.join(BRAND, "Top Shelf Image.imageset"),
               [("1x", 1920, 720), ("2x", 3840, 1440)], "topshelf")
print("top shelf wide…")
build_imageset(os.path.join(BRAND, "Top Shelf Image Wide.imageset"),
               [("1x", 2320, 720), ("2x", 4640, 1440)], "topshelfwide")
print("done")
