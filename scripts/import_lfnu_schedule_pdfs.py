#!/usr/bin/env python3
"""Normalize NU Online monthly Bangsri prayer-schedule PDFs into JSON/CSV."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
from datetime import date
from pathlib import Path


MONTH_FILES = {
    1: "nu-online-jadwal-shalat-bangsri-januari-2026.pdf",
    2: "nu-online-jadwal-shalat-bangsri-februari-2026.pdf",
    3: "nu-online-jadwal-shalat-bangsri-maret-2026.pdf",
    4: "nu-online-jadwal-shalat-bangsri-april-2026.pdf",
    5: "nu-online-jadwal-shalat-bangsri-mei-2026.pdf",
    6: "nu-online-jadwal-shalat-bangsri-juni-2026.pdf",
    7: "nu-online-jadwal-shalat-bangsri-juli-2026.pdf",
    8: "nu-online-jadwal-shalat-bangsri-agustus-2026.pdf",
    9: "nu-online-jadwal-shalat-bangsri-september-2026.pdf",
    10: "nu-online-jadwal-shalat-bangsri-oktober-2026.pdf",
    11: "nu-online-jadwal-shalat-bangsri-november-2026.pdf",
    12: "nu-online-jadwal-shalat-bangsri-desember-2026.pdf",
}
MONTH_LABELS = {
    1: "Januari", 2: "Februari", 3: "Maret", 4: "April", 5: "Mei", 6: "Juni",
    7: "Juli", 8: "Agustus", 9: "September", 10: "Oktober", 11: "November", 12: "Desember",
}

HIJRI_MONTH_PAIRS = {
    1: ("Rajab", "Sya'ban"),
    2: ("Sya'ban", "Ramadan"),
    3: ("Ramadan", "Syawal"),
    4: ("Syawal", "Dzulqa'dah"),
    5: ("Dzulqa'dah", "Dzulhijjah"),
    6: ("Dzulhijjah", "Muharam"),
    7: ("Muharam", "Safar"),
    8: ("Safar", "Rabiul Awal"),
    9: ("Rabiul Awal", "Rabiul Akhir"),
    10: ("Rabiul Akhir", "Jumadal Ula"),
    11: ("Jumadal Ula", "Jumadal Akhirah"),
    12: ("Jumadal Akhirah", "Rajab"),
}

WEEKDAYS = {"Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Ahad"}
ENGLISH_TO_INDONESIAN_WEEKDAY = {
    "Monday": "Senin",
    "Tuesday": "Selasa",
    "Wednesday": "Rabu",
    "Thursday": "Kamis",
    "Friday": "Jumat",
    "Saturday": "Sabtu",
    "Sunday": "Ahad",
}
TIME_RE = re.compile(r"\b([0-2]\d:[0-5]\d)\b")
ROW_RE = re.compile(r"^\s*(Senin|Selasa|Rabu|Kamis|Jumat|Sabtu|Ahad)\s+(\d{1,2})\s+(\d{1,2})\b")
EVENTS = ("imsak", "fajr", "sunrise", "dhuha", "dhuhr", "asr", "maghrib", "isha")


def pdf_text(path: Path) -> str:
    return subprocess.run(
        ["pdftotext", "-layout", str(path), "-"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def parse_month(path: Path, month: int) -> list[dict]:
    text = pdf_text(path)
    if MONTH_LABELS[month] not in text:
        raise ValueError(f"Unexpected month title in {path.name}")
    rows = []
    previous_hijri_day = None
    crossed_hijri_month = False
    first_hijri, second_hijri = HIJRI_MONTH_PAIRS[month]
    for line in text.splitlines():
        match = ROW_RE.match(line)
        if not match:
            continue
        weekday, gregorian_day, hijri_day = match.groups()
        times = TIME_RE.findall(line)
        if len(times) != 8:
            raise ValueError(f"Expected eight prayer times, found {len(times)}: {line}")
        gregorian_day = int(gregorian_day)
        hijri_day = int(hijri_day)
        if previous_hijri_day is not None and hijri_day < previous_hijri_day:
            crossed_hijri_month = True
        previous_hijri_day = hijri_day
        hijri_month = second_hijri if crossed_hijri_month else first_hijri
        day = date(2026, month, gregorian_day)
        expected_weekday = ENGLISH_TO_INDONESIAN_WEEKDAY[day.strftime("%A")]
        if weekday != expected_weekday:
            raise ValueError(
                f"Weekday mismatch in {path.name}: {day} is {expected_weekday}, PDF says {weekday}"
            )
        record = {
            "date": day.isoformat(),
            "weekday_id": weekday,
            "hijri_month": hijri_month,
            "hijri_day": hijri_day,
            "is_ramadan": hijri_month == "Ramadan",
            "times_wib": dict(zip(EVENTS, times, strict=True)),
            "source_pdf": path.name,
        }
        rows.append(record)
    expected_days = (date(2027, 1, 1) - date(2026, month, 1)).days if month == 12 else (date(2026, month + 1, 1) - date(2026, month, 1)).days
    if len(rows) != expected_days:
        raise ValueError(f"{path.name}: expected {expected_days} daily rows, got {len(rows)}")
    if [row["date"] for row in rows] != [date(2026, month, day).isoformat() for day in range(1, expected_days + 1)]:
        raise ValueError(f"{path.name}: dates are missing, duplicated, or out of order")
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    source_dir = args.source_dir
    source_dir.mkdir(parents=True, exist_ok=True)

    sources = []
    records = []
    for month, filename in MONTH_FILES.items():
        path = source_dir / filename
        if not path.is_file():
            raise FileNotFoundError(path)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        text = pdf_text(path)
        title = next((line.strip() for line in text.splitlines() if "Jadwal Shalat Bulan" in line), None)
        sources.append({"file": filename, "sha256": digest, "title": title})
        records.extend(parse_month(path, month))

    if len(records) != 365:
        raise ValueError(f"2026 should contain 365 schedule rows, got {len(records)}")
    expected_ramadan_dates = [r["date"] for r in records if r["is_ramadan"]]
    if not expected_ramadan_dates:
        raise ValueError("No Ramadan dates were identified from the Hijri day/month columns")

    dataset = {
        "schema": "lfnu-prayer-schedule/v1",
        "source": "NU Online jadwalsholat.nu.or.id monthly PDF exports",
        "location": {
            "name": "Bangsri",
            "district": "Bangsri",
            "regency": "Kabupaten Jepara",
            "province": "Jawa Tengah",
            "latitude": -6.522777777777778,
            "longitude": 110.76,
            "elevation_m": 64,
            "timezone": "Asia/Jakarta",
            "utc_offset": "+07:00",
        },
        "method": {
            "name": "Lembaga Falakiyah NU, Indonesia",
            "fajr_angle_degrees": 20,
            "isha_angle_degrees": 18,
            "asr_madhab": "Shafi'i",
            "dhuha_solar_altitude_degrees": 4.5,
            "imsak_minutes_before_fajr": 10,
            "dhuhr_minutes_after_transit": 1,
            "routine_ihtiyath_minutes": 0,
            "ramadan_maghrib_ihtiyath_minutes": 1,
            "horizon_altitude_note": "PDF identifies elevation 64 m; the supplied LFNU settings specify 1°4′ below the horizon for sunrise/Maghrib.",
            "rounding": "Published local schedule is minute precision; exact source rounding rule is not stated in the PDF.",
        },
        "coverage": {"year": 2026, "months": 12, "days": len(records)},
        "source_documents": sources,
        "records": records,
    }
    json_path = args.output_dir / "bangsri-2026.json"
    json_path.write_text(json.dumps(dataset, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    csv_path = args.output_dir / "bangsri-2026.csv"
    columns = ["date", "weekday_id", "hijri_month", "hijri_day", "is_ramadan", *EVENTS]
    with csv_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        for record in records:
            writer.writerow({
                "date": record["date"],
                "weekday_id": record["weekday_id"],
                "hijri_month": record["hijri_month"],
                "hijri_day": record["hijri_day"],
                "is_ramadan": str(record["is_ramadan"]).lower(),
                **record["times_wib"],
            })
    print(f"Wrote {len(records)} days to {json_path} and {csv_path}")
    print(f"Ramadan coverage inferred from PDF Hijri columns: {expected_ramadan_dates[0]}..{expected_ramadan_dates[-1]} ({len(expected_ramadan_dates)} days)")


if __name__ == "__main__":
    main()
