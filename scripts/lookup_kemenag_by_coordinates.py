#!/usr/bin/env python3
"""Find the nearest Kemenag city schedule to coordinates for a given date.

Example:
  python3 scripts/lookup_kemenag_by_coordinates.py \
    --dataset test/data/reference/kemenag/national-2026.jsonl \
    --latitude -6.2 --longitude 106.8 --date 2026-11-19
"""

import argparse
from datetime import date
import gzip
import json
import math
from pathlib import Path
import sys


EARTH_RADIUS_KM = 6371.0088


def distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    lat1, lon1, lat2, lon2 = map(math.radians, (lat1, lon1, lat2, lon2))
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(a))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", required=True, type=Path)
    parser.add_argument("--latitude", required=True, type=float)
    parser.add_argument("--longitude", required=True, type=float)
    parser.add_argument("--date", required=True, type=date.fromisoformat)
    args = parser.parse_args()

    nearest = None
    try:
        opener = gzip.open if args.dataset.suffix == ".gz" else open
        with opener(args.dataset, "rt", encoding="utf-8") as data_file:
            for line_number, line in enumerate(data_file, start=1):
                try:
                    record = json.loads(line)
                    request = record["request"]
                    if (
                        request["year"] != args.date.year
                        or request["month"] != args.date.month
                    ):
                        continue
                    coordinates = record["coordinates"]
                    distance = distance_km(
                        args.latitude,
                        args.longitude,
                        coordinates["latitude"],
                        coordinates["longitude"],
                    )
                    if nearest is None or distance < nearest[0]:
                        nearest = (distance, record)
                except (json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
                    raise RuntimeError(
                        f"Record JSONL tidak valid pada baris {line_number}: {error}"
                    ) from error
    except OSError as error:
        print(f"Gagal membaca dataset: {error}", file=sys.stderr)
        return 1
    except RuntimeError as error:
        print(str(error), file=sys.stderr)
        return 1

    if nearest is None:
        print(
            f"Tidak ada jadwal untuk {args.date:%Y-%m} di dataset {args.dataset}.",
            file=sys.stderr,
        )
        return 1

    distance, record = nearest
    day = record["response"].get("data", {}).get(args.date.isoformat())
    if day is None:
        print(f"Jadwal tanggal {args.date.isoformat()} tidak tersedia.", file=sys.stderr)
        return 1

    request = record["request"]
    print(f"Lokasi terdekat: {request['city']}, {request['province']}")
    print(f"Jarak dari koordinat input: {distance:.2f} km")
    print(
        "Koordinat Kemenag: "
        f"{record['coordinates']['latitude']:.6f}, "
        f"{record['coordinates']['longitude']:.6f} "
        f"({record['coordinates']['latitude_dms']}, "
        f"{record['coordinates']['longitude_dms']})"
    )
    print(f"Tanggal: {day.get('tanggal', args.date.isoformat())}")
    for key in ("imsak", "subuh", "terbit", "dhuha", "dzuhur", "ashar", "maghrib", "isya"):
        if key in day:
            print(f"{key}: {day[key]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
