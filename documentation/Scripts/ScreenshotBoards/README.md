# Screenshot and starter board tools

Run from the repository root. These tools maintain the source catalog in `ScreenshotBoards/`; the full [catalog guide](../../../ScreenshotBoards/README.md) covers artwork provenance, board contents and the expansion workflow. [Verification records](../../../ScreenshotBoards/VERIFICATION.md) are historical results.

| Tool | Purpose |
| --- | --- |
| `extract-symbols.swift` | Extract source symbol artwork into `ScreenshotBoards`; pass `--expansion` for the expansion set. |
| `prepare-expansion-symbols.py` | Prepare expansion artwork; requires Pillow. |
| `package-boards.py` | Rebuild paired English/Spanish source boards, archives, manifest and preview; invoke the multilingual converter and copy version-2 resources into the production starter catalog. |

Typical packaging command:

```sh
python3 documentation/Scripts/ScreenshotBoards/package-boards.py
```

Packaging writes source-board artifacts and `PECS Maker/Resources/StarterBoards`. Review existing changes before running it. It is not a read-only validator. The converter requires paired language content and matching card image hashes; see [multilingual documents](../MultilingualBoards/README.md).

All script-relative repository paths account for the move into `documentation/Scripts`. Command-line input/output paths remain relative to your working directory.
