#!/usr/bin/env python3
"""Collect a nationwide Kemenag monthly schedule dataset as one JSONL file.

Example:
  python3 scripts/collect_kemenag_dataset.py --year 2026 \
    --output test/data/reference/kemenag/national-2026.jsonl

The output is one searchable file, with decimal coordinates on every record.
It resumes by skipping location/month records already downloaded successfully.
"""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


API_BASE = "https://bimasislam.kemenag.go.id/api/sihat"
USER_AGENT = "islamic-utility-kemenag-reference/1.0"
DMS = re.compile(
    r"\s*(-?\d+(?:\.\d+)?)\s*°"
    r"(?:\s*(\d+(?:\.\d+)?)\s*['′])?"
    r"(?:\s*(\d+(?:\.\d+)?)\s*[\"″])?"
    r"\s*[\"″]?\s*([NSEW])\s*",
    re.IGNORECASE,
)


def get_json(path: str, params: dict[str, str] | None = None) -> dict:
    query = f"?{urlencode(params)}" if params else ""
    request = Request(
        f"{API_BASE}/{path}{query}",
        headers={"Accept": "application/json", "User-Agent": USER_AGENT},
    )
    for attempt in range(4):
        try:
            with urlopen(request, timeout=30) as response:
                payload = json.loads(response.read().decode("utf-8"))
            if not isinstance(payload, dict):
                raise RuntimeError(f"Respons {path} bukan objek JSON.")
            if payload.get("error"):
                raise RuntimeError(f"API {path}: {payload['error']}")
            return payload
        except HTTPError as error:
            if error.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise RuntimeError(f"HTTP {error.code} saat mengambil {path}") from error
            time.sleep(min(2**attempt, 8))
        except (URLError, TimeoutError, json.JSONDecodeError) as error:
            if attempt == 3:
                raise RuntimeError(f"Gagal mengambil {path}: {error}") from error
            time.sleep(min(2**attempt, 8))
    raise RuntimeError(f"Gagal mengambil {path} setelah beberapa percobaan.")


def decimal_coordinate(value: str) -> float:
    match = DMS.fullmatch(value)
    if not match:
        raise ValueError(f"Format koordinat Kemenag tidak dikenali: {value!r}")
    degrees = abs(float(match.group(1)))
    minutes = float(match.group(2) or 0)
    seconds = float(match.group(3) or 0)
    direction = match.group(4).upper()
    result = degrees + minutes / 60 + seconds / 3600
    return -result if direction in ("S", "W") else result


def record_key(record: dict) -> tuple[str, str, int, int]:
    request = record["request"]
    return (
        " ".join(request["province"].upper().split()),
        " ".join(request["city"].upper().split()),
        request["year"],
        request["month"],
    )


def load_successful_keys(path: Path) -> set[tuple[str, str, int, int]]:
    if not path.exists():
        return set()
    raw = path.read_bytes()
    if raw and not raw.endswith(b"\n"):
        last_newline = raw.rfind(b"\n")
        raw = raw[: last_newline + 1] if last_newline >= 0 else b""
        path.write_bytes(raw)
    result = set()
    unique_lines = []
    for line in raw.splitlines():
        try:
            record = json.loads(line)
            response = record["response"]
            if response.get("status") == 1 and response.get("data"):
                key = record_key(record)
                if key not in result:
                    result.add(key)
                    unique_lines.append(line)
        except (json.JSONDecodeError, KeyError, TypeError):
            continue
    if len(unique_lines) != len(raw.splitlines()):
        path.write_bytes(b"\n".join(unique_lines) + (b"\n" if unique_lines else b""))
    return result


def download_record(
    province: dict, city: dict, month: int, year: int, delay: float
) -> tuple[dict, dict | None, str | None]:
    request = {
        "province_id": province["id"],
        "province": province["name"],
        "city_id": city["id"],
        "city": city["name"],
        "year": year,
        "month": month,
    }
    try:
        response = get_json(
            "jadwal",
            {
                "prov": province["id"],
                "kabko": city["id"],
                "thn": str(year),
                "bln": f"{month:02d}",
            },
        )
        if response.get("status") != 1 or not response.get("data"):
            raise RuntimeError(response.get("message", "Respons jadwal kosong"))
        record = {
            "source": "SIHAT Kementerian Agama Republik Indonesia",
            "retrieved_at_utc": datetime.now(timezone.utc).isoformat(),
            "request": request,
            "coordinates": {
                "latitude": decimal_coordinate(response["lintang"]),
                "longitude": decimal_coordinate(response["bujur"]),
                "latitude_dms": response["lintang"],
                "longitude_dms": response["bujur"],
            },
            "response": response,
        }
        return request, record, None
    except (KeyError, RuntimeError, ValueError) as error:
        return request, None, str(error)
    finally:
        time.sleep(delay)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--year", required=True, type=int)
    parser.add_argument(
        "--months",
        type=int,
        nargs="+",
        choices=range(1, 13),
        default=list(range(1, 13)),
        help="Bulan yang diambil; default semua bulan 1 sampai 12",
    )
    parser.add_argument(
        "--output", required=True, type=Path, help="Satu file JSONL untuk semua lokasi"
    )
    parser.add_argument(
        "--delay", type=float, default=0.2, help="Jeda antar-panggilan jadwal (default 0.2 detik)"
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=3,
        help="Jumlah permintaan bersamaan (default 3, maksimum 6)",
    )
    args = parser.parse_args()
    if args.delay < 0:
        parser.error("--delay tidak boleh negatif")
    if not 1 <= args.workers <= 6:
        parser.error("--workers harus antara 1 dan 6")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    completed = load_successful_keys(args.output)
    errors_path = args.output.with_suffix(args.output.suffix + ".errors.jsonl")
    errors = errors_path.open("a", encoding="utf-8")
    total = 0
    succeeded = 0
    failed = 0

    try:
        provinces = get_json("provinsi").get("data", [])
        provinces = [
            province
            for province in provinces
            if province.get("name", "").strip().upper() != "PUSAT"
        ]
        locations = []
        for province in provinces:
            cities = get_json("kabko", {"prov": province["id"]}).get("data", [])
            locations.extend((province, city) for city in cities)
            time.sleep(args.delay)

        tasks = [
            (province, city, month)
            for province, city in locations
            for month in sorted(set(args.months))
        ]
        pending = [
            (province, city, month)
            for province, city, month in tasks
            if (
                " ".join(province["name"].upper().split()),
                " ".join(city["name"].upper().split()),
                args.year,
                month,
            )
            not in completed
        ]
        print(
            f"Lokasi: {len(locations)}; bulan: {len(set(args.months))}; "
            f"rekaman baru: {len(pending)}; sudah tersedia: {len(tasks) - len(pending)}",
            flush=True,
        )

        with args.output.open("a", encoding="utf-8") as output:
            with ThreadPoolExecutor(max_workers=args.workers) as executor:
                futures = [
                    executor.submit(
                        download_record,
                        province,
                        city,
                        month,
                        args.year,
                        args.delay,
                    )
                    for province, city, month in pending
                ]
                for index, future in enumerate(as_completed(futures), start=1):
                    request, record, error = future.result()
                    total += 1
                    if record is not None:
                        output.write(json.dumps(record, ensure_ascii=False) + "\n")
                        output.flush()
                        completed.add(
                            (
                                " ".join(request["province"].upper().split()),
                                " ".join(request["city"].upper().split()),
                                args.year,
                                request["month"],
                            )
                        )
                        succeeded += 1
                    else:
                        errors.write(
                            json.dumps(
                                {"request": request, "error": error},
                                ensure_ascii=False,
                            )
                            + "\n"
                        )
                        errors.flush()
                        failed += 1

                    if index % 25 == 0 or index == len(pending):
                        print(
                            f"Progres {index}/{len(pending)}: "
                            f"berhasil {succeeded}, gagal {failed}",
                            flush=True,
                        )
    except (KeyError, RuntimeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    finally:
        errors.close()

    print(
        f"Selesai: {succeeded} berhasil, {failed} gagal. Dataset: {args.output}"
    )
    if failed:
        print(f"Rincian kegagalan: {errors_path}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
