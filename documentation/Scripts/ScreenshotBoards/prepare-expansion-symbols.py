#!/usr/bin/env python3
"""Convert extracted expansion symbols to PNG-8, retaining dimensions and alpha.
Run after extract-symbols.swift --expansion. Requires Pillow.
Full-colour source sheets are retained in artwork/expansion for regeneration.
"""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[3] / 'ScreenshotBoards'
report = []
for path in sorted((root / 'symbols').glob('expansion-*/*.png')):
    original = Image.open(path).convert('RGBA')
    # ImageGen's visually opaque fills can use alpha 250-254. Match the existing
    # PNG-8 normalization while retaining transparent/antialiased boundaries.
    alpha = original.getchannel('A').point(lambda value: 255 if value >= 250 else value)
    original.putalpha(alpha)
    indexed = original.quantize(colors=256, method=Image.Quantize.FASTOCTREE)
    before = path.stat().st_size
    indexed.save(path, optimize=True)
    with Image.open(path) as decoded:
        assert decoded.mode == 'P' and decoded.size == original.size
        histogram = decoded.convert('RGBA').getchannel('A').histogram()
        assert histogram[0] > original.width * original.height * 0.1
        assert histogram[255] > 100
    report.append(dict(symbol=str(path.relative_to(root / 'symbols')), before=before,
                       after=path.stat().st_size, width=original.width, height=original.height,
                       fullyTransparentPixels=histogram[0], fullyOpaquePixels=histogram[255]))
(root / 'expansion-png8-validation.json').write_text(json.dumps(report, indent=2) + '\n')
print(f'Validated {len(report)} PNG-8 symbols with transparency.')
