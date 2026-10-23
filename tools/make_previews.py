"""Turns in-game screenshots into the window pictures of the setup wizard.

The setup wizard and the options page draw most of their before / after
pictures from the game's own art (src/Previews.lua), but whole windows are
shown as screenshots (ns.PreviewImages). This crops each window out of a
1920x1080 screenshot, scales it to at most 512x256 and pads it into a
power-of-two 32-bit TGA (uncompressed, bottom-left origin, like the other
bundled textures) in src/Textures/Previews, then prints the Lua table entries
(image size and file size) to paste into PreviewsForever.lua / Previews.lua.

    python tools/make_previews.py "<WoW>/_forever_/Screenshots"

Take new screenshots with the default UI scale, one window open at a time,
update the file names and crop boxes below, and run it again.
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "src" / "Textures" / "Previews"
MAX_WIDTH, MAX_HEIGHT = 512, 256

# (output name, screenshot, crop box left, top, right, bottom[, boxes to make
# transparent, where something outside the window shows through])
FOREVER = [
    ("forever-characterframe-modern", "WoWScrnShot_092826_004427.jpg", (4, 101, 418, 575)),
    ("forever-spellbook-modern", "WoWScrnShot_092826_004439.jpg", (148, 30, 958, 758)),
    ("forever-talents-modern", "WoWScrnShot_092826_004452.jpg", (342, 20, 1562, 748)),
    ("forever-trainer-modern", "WoWScrnShot_092826_004732.jpg", (4, 108, 352, 536)),
    ("forever-auctionhouse-modern", "WoWScrnShot_092826_004835.jpg", (26, 108, 840, 655)),
    ("forever-professions-modern", "WoWScrnShot_092826_004946.jpg", (42, 104, 724, 708)),
    ("forever-lootframe-modern", "WoWScrnShot_092826_005134.jpg", (1054, 545, 1274, 690)),
    ("forever-characterframe-classic", "WoWScrnShot_092826_005240.jpg", (28, 112, 370, 578)),
    ("forever-spellbook-classic", "WoWScrnShot_092826_005255.jpg", (22, 115, 452, 535), [(362, 380, 452, 535)]),
    ("forever-talents-classic", "WoWScrnShot_092826_005305.jpg", (22, 115, 412, 553), [(366, 275, 412, 553)]),
    ("forever-trainer-classic", "WoWScrnShot_092826_005401.jpg", (22, 117, 364, 550)),
    ("forever-auctionhouse-classic", "WoWScrnShot_092826_005618.jpg", (38, 115, 870, 551)),
    ("forever-professions-classic", "WoWScrnShot_092826_005636.jpg", (52, 117, 404, 552)),
    ("forever-lootframe-classic", "WoWScrnShot_092826_005715.jpg", (965, 385, 1155, 630)),
]


def power_of_two(value):
    size = 1
    while size < value:
        size *= 2
    return size


def main(screenshots):
    OUT.mkdir(parents=True, exist_ok=True)
    for name, source, box, *clear in FOREVER:
        image = Image.open(Path(screenshots) / source).convert("RGBA")
        for left, top, right, bottom in (clear[0] if clear else []):
            image.paste((0, 0, 0, 0), (left, top, right, bottom))
        image = image.crop(box)
        scale = min(MAX_WIDTH / image.width, MAX_HEIGHT / image.height, 1)
        size = (round(image.width * scale), round(image.height * scale))
        image = image.resize(size, Image.LANCZOS)
        canvas = Image.new("RGBA", (power_of_two(size[0]), power_of_two(size[1])), (0, 0, 0, 0))
        canvas.paste(image, (0, 0))
        canvas.save(OUT / f"{name}.tga", orientation=-1)
        _, key, look = name.split("-")
        print(f'{key} {look} = {{ file = "{name}", width = {size[0]}, height = {size[1]}, '
              f"fileWidth = {canvas.width}, fileHeight = {canvas.height} }},")


if __name__ == "__main__":
    main(sys.argv[1])
