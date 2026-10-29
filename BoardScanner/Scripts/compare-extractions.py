#!/usr/bin/env python3
"""Compare saved app output to independently transcribed screenshot labels and positions.

Usage: compare-extractions.py OUTPUT_DIRECTORY [--ios]
Default reads <N>-Photo-<N>/board.boardscan; --ios reads ios-photo-<N>.boardscan.
"""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("output", type=Path)
parser.add_argument("--ios", action="store_true")
args = parser.parse_args()
expectations = json.loads((Path(__file__).resolve().parents[1] / "Tests/Fixtures/screenshot-expectations.json").read_text())
summary = []
failures = 0
for number, expected in enumerate(expectations, 1):
    path = args.output / (f"ios-photo-{number}.boardscan" if args.ios else f"{number}-Photo-{number}/board.boardscan")
    board = json.loads(path.read_text())
    mismatches = []
    casing = []
    if (board["rows"], board["columns"]) != (6, 11):
        mismatches.append({"grid": [board["rows"], board["columns"]]})
    by_position = {(card["row"], card["column"]): card for card in board["cards"]}
    if len(board["cards"]) != 66 or len(by_position) != 66:
        mismatches.append({"slots": len(board["cards"]), "uniquePositions": len(by_position)})
    exact = 0
    count = sum(label is not None for row in expected["rows"] for label in row)
    for row, labels in enumerate(expected["rows"]):
        for column, label in enumerate(labels):
            card = by_position.get((row, column))
            if card is None or card["included"] != (label is not None):
                mismatches.append({"row": row, "column": column, "expected": label, "occupancy": None if card is None else card["included"]})
            elif label is not None:
                if card["label"].casefold() != label.casefold():
                    mismatches.append({"row": row, "column": column, "expected": label, "actual": card["label"]})
                else:
                    exact += 1
                    if card["label"] != label:
                        casing.append({"row": row, "column": column, "expected": label, "actual": card["label"]})
            elif card.get("isEmpty") is not True or card["label"] or card["needsReview"]:
                mismatches.append({"row": row, "column": column, "emptySlotHasContent": True})
    failures += len(mismatches)
    summary.append({"photo": number, "title": expected["title"], "expectedCards": count,
                    "includedCards": sum(card["included"] for card in board["cards"]),
                    "matchingLabelsIgnoringCase": exact, "reviewFlags": sum(card["needsReview"] for card in board["cards"]),
                    "casingDifferences": casing, "mismatches": mismatches})
print(json.dumps({"boards": summary, "totalMatchingLabelsIgnoringCase": sum(item["matchingLabelsIgnoringCase"] for item in summary),
                  "mismatches": failures}, indent=2))
raise SystemExit(1 if failures else 0)
