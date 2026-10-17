"""Crops in-game screenshots into the CurseForge gallery pictures.

Each picture is one feature cut out of a 1920x1080 Forever screenshot (the
addon on, every option Classic), saved unscaled as PNG in
curseforge/screenshots, numbered in the order to upload them.

    python tools/make_screenshots.py "<WoW>/_classic_beta_/Screenshots"

Update the file names and crop boxes below for new screenshots and run it
again.
"""
import sys
from pathlib import Path

from PIL import Image, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "curseforge" / "screenshots"

# (output name, screenshot, crop box left, top, right, bottom[, boxes to blur,
# where chat, a nameplate or private text shows through])
SHOTS = [
    ("01-setup-wizard", "WoWScrnShot_092826_013825.jpg", (565, 205, 1355, 825)),
    ("02-unit-frames-nameplate", "WoWScrnShot_092726_105220.jpg", (20, 10, 1060, 330)),
    ("03-cast-bar", "WoWScrnShot_092726_105220.jpg", (760, 480, 1160, 810)),
    ("04-action-bars", "WoWScrnShot_101726_140633.jpg", (228, 905, 1680, 1080)),
    ("05-minimap", "WoWScrnShot_101726_160847.jpg", (1370, 0, 1915, 252), [(1370, 18, 1406, 32), (1878, 234, 1915, 252)]),
    ("06-quest-tracker", "WoWScrnShot_101726_140633.jpg", (1500, 268, 1770, 866)),
    ("07-character-window", "WoWScrnShot_100126_200104.jpg", (8, 105, 362, 568)),
    ("08-spellbook", "WoWScrnShot_092826_005255.jpg", (18, 115, 408, 556), [(366, 492, 408, 556)]),
    ("09-talents", "WoWScrnShot_092826_005305.jpg", (18, 115, 408, 576), [(362, 482, 408, 576), (282, 552, 362, 576)]),
    ("10-trainer", "WoWScrnShot_092826_005401.jpg", (18, 115, 370, 552)),
    ("11-professions", "WoWScrnShot_092826_005636.jpg", (56, 115, 455, 552), [(399, 462, 455, 552)]),
    ("12-quest-log", "WoWScrnShot_101726_140642.jpg", (5, 110, 358, 572)),
    ("13-auction-house", "WoWScrnShot_092826_005618.jpg", (36, 120, 872, 578), [(36, 544, 66, 578), (252, 546, 872, 578)]),
    ("14-vendor", "WoWScrnShot_101726_140726.jpg", (12, 112, 354, 588)),
    ("15-bank", "WoWScrnShot_101726_141040.jpg", (12, 112, 492, 612), [(298, 112, 332, 117)]),
    ("16-backpack", "WoWScrnShot_101726_140911.jpg", (1466, 742, 1906, 990)),
    ("17-loot-window", "WoWScrnShot_092826_005715.jpg", (962, 375, 1155, 640), [(962, 460, 971, 510)]),
    ("18-looking-for-group", "WoWScrnShot_101726_140703.jpg", (5, 110, 358, 568)),
    # the BattleTag is blurred
    ("19-friends", "WoWScrnShot_101726_140657.jpg", (5, 110, 354, 566), [(145, 140, 262, 162)]),
    ("20-game-menu", "WoWScrnShot_101726_140633.jpg", (862, 398, 1058, 674)),
    ("21-options", "WoWScrnShot_092826_013856.jpg", (500, 108, 1425, 845)),
]


def main(screenshots):
    OUT.mkdir(parents=True, exist_ok=True)
    for name, source, box, *blur in SHOTS:
        image = Image.open(Path(screenshots) / source).convert("RGB")
        for area in (blur[0] if blur else []):
            image.paste(image.crop(area).filter(ImageFilter.GaussianBlur(12)), area[:2])
        image = image.crop(box)
        image.save(OUT / f"{name}.png", optimize=True)
        print(f"{name}.png {image.width}x{image.height}")


if __name__ == "__main__":
    main(sys.argv[1])
