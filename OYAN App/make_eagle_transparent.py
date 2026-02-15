#!/usr/bin/env python3
"""Makes the black background of eagle_book.png transparent.
Run: pip3 install Pillow  (if needed), then: python3 make_eagle_transparent.py"""

from PIL import Image
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
img_path = os.path.join(script_dir, "Assets.xcassets/eagle_book.imageset/eagle_book.png")
img = Image.open(img_path)
img = img.convert("RGBA")
data = img.getdata()

new_data = []
for item in data:
    r, g, b, a = item
    # Make black/dark pixels (background) transparent; fuzz ~30 for anti-aliased edges
    if r < 30 and g < 30 and b < 30:
        new_data.append((r, g, b, 0))
    else:
        new_data.append(item)

img.putdata(new_data)
img.save(img_path)
print("Done. eagle_book.png now has transparent background.")
