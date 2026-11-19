#!/usr/bin/env python3
"""Compare the LFNU Bangsri engine export with published minute schedules."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


ROOT = Path("test/data/reference/lfnu")
EVENTS = ("imsak", "fajr", "sunrise", "dhuha", "dhuhr", "asr", "maghrib", "isha")
LABELS = {
    "imsak": "Imsak",
    "fajr": "Subuh",
    "sunrise": "Terbit",
    "dhuha": "Dhuha",
    "dhuhr": "Zuhur",
    "asr": "Asar",
    "maghrib": "Maghrib",
    "isha": "Isya",
}


def seconds(value: str) -> int:
    hour, minute, *second = map(int, value.split(":"))
    return hour * 3600 + minute * 60 + (second[0] if second else 0)


def clock(value: int) -> str:
    value %= 86400
    return f"{value // 3600:02d}:{value % 3600 // 60:02d}"


def signed_delta(engine: int, published: int) -> int:
    delta = engine - published
    if delta > 43200:
        delta -= 86400
    if delta < -43200:
        delta += 86400
    return delta


def round_up(value: int) -> int:
    return ((value + 59) // 60) * 60


def round_nearest(value: int) -> int:
    remainder = value % 60
    return value - remainder + (60 if remainder >= 30 else 0)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--sunrise-nearest",
        action="store_true",
        help="round Terbit to the nearest minute; round all other events up",
    )
    args = parser.parse_args()

    suffix = "mixed-rounding" if args.sunrise_nearest else "round-up"
    rounding_label = (
        "round up all events except Terbit, which uses nearest-minute rounding"
        if args.sunrise_nearest
        else "round up every event to the next whole minute"
    )
    source_path = ROOT / "bangsri-2026-engine-comparison.csv"
    with source_path.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))

    def rounded(event: str, raw: int) -> int:
        if args.sunrise_nearest and event == "sunrise":
            return round_nearest(raw)
        return round_up(raw)

    summaries = {}
    output = []
    for event in EVENTS:
        differences = []
        for row in rows:
            engine = rounded(event, seconds(row[f"engine_{event}"]))
            published = seconds(row[f"source_{event}"])
            delta = signed_delta(engine, published)
            differences.append(
                (delta, row["date"], clock(engine), row[f"source_{event}"])
            )

        minimum = min(differences, key=lambda item: abs(item[0]))
        maximum = max(differences, key=lambda item: abs(item[0]))
        summaries[event] = {
            "label": LABELS[event],
            "samples": len(differences),
            "min_absolute_seconds": abs(minimum[0]),
            "min_absolute_date": minimum[1],
            "max_absolute_seconds": abs(maximum[0]),
            "max_absolute_signed_seconds": maximum[0],
            "max_absolute_date": maximum[1],
            "max_absolute_source": maximum[3],
            "max_absolute_engine_rounded": maximum[2],
            "signed_min_seconds": min(item[0] for item in differences),
            "signed_max_seconds": max(item[0] for item in differences),
            "exact_matches": sum(item[0] == 0 for item in differences),
            "mismatches": sum(item[0] != 0 for item in differences),
        }

    for row in rows:
        detail = {"date": row["date"], "is_ramadan": row["is_ramadan"]}
        for event in EVENTS:
            engine = rounded(event, seconds(row[f"engine_{event}"]))
            published = seconds(row[f"source_{event}"])
            detail[f"source_{event}"] = row[f"source_{event}"]
            detail[f"engine_{suffix}_{event}"] = clock(engine)
            detail[f"delta_{event}_seconds"] = signed_delta(engine, published)
        output.append(detail)

    csv_path = ROOT / f"bangsri-2026-{suffix}-comparison.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=output[0].keys())
        writer.writeheader()
        writer.writerows(output)

    result = {
        "dataset": "bangsri-2026",
        "rounding": rounding_label,
        "delta_sign": "rounded engine minus NU Online PDF, seconds",
        "days": len(rows),
        "metrics": summaries,
    }
    json_path = ROOT / f"bangsri-2026-{suffix}-comparison.json"
    json_path.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    markdown = [
        f"# LFNU Bangsri 2026 — {suffix} comparison",
        "",
        f"- Days: {len(rows)}",
        f"- Rule: {rounding_label}; exact minute values remain unchanged.",
        "- Delta: rounded engine minus NU Online PDF, in seconds; positive means later.",
        "- The engine used the LFNU preset, including its configured Ramadan Maghrib +1 minute.",
        "- PDF values are minute-only; this is a schedule parity check, not a second-precision source validation.",
        "",
        "| Jadwal | Hari tidak cocok | Selisih absolut terbesar | Tanggal | Engine | PDF | Cocok persis |",
        "|---|---:|---:|---|---|---|---:|",
    ]
    for event in EVENTS:
        metric = summaries[event]
        markdown.append(
            f"| {LABELS[event]} | {metric['mismatches']}/{metric['samples']} "
            f"| {metric['max_absolute_seconds']} dtk "
            f"| {metric['max_absolute_date']} "
            f"| {metric['max_absolute_engine_rounded']} "
            f"| {metric['max_absolute_source']} "
            f"| {metric['exact_matches']}/{metric['samples']} |"
        )
    markdown.extend(
        [
            "",
            "## Rentang selisih bertanda",
            "",
            "| Jadwal | Paling awal | Paling akhir |",
            "|---|---:|---:|",
        ]
    )
    for event in EVENTS:
        metric = summaries[event]
        markdown.append(
            f"| {LABELS[event]} | {metric['signed_min_seconds']} dtk "
            f"| +{metric['signed_max_seconds']} dtk |"
        )
    markdown_path = ROOT / f"bangsri-2026-{suffix}-comparison.md"
    markdown_path.write_text("\n".join(markdown) + "\n", encoding="utf-8")
    print("\n".join(markdown))


if __name__ == "__main__":
    main()
