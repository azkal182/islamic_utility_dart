#!/usr/bin/env python3
"""Download one monthly prayer schedule from the public SIHAT Kemenag API.

Example:
  python3 scripts/fetch_kemenag_schedule.py \
    --province "Jawa Tengah" --city Jepara --month 11 --year 2026 \
    --output data/reference/kemenag/jepara-2026-11.json

This saves an official-schedule snapshot for comparison. It does not calculate
or adjust astronomical prayer times.
"""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


API_BASE = "https://bimasislam.kemenag.go.id/api/sihat"
USER_AGENT = "islamic-utility-kemenag-reference/1.0"


def get_json(path: str, params: dict[str, str] | None = None) -> dict:
    query = f"?{urlencode(params)}" if params else ""
    request = Request(
        f"{API_BASE}/{path}{query}",
        headers={"Accept": "application/json", "User-Agent": USER_AGENT},
    )
    try:
        with urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        raise RuntimeError(f"Gagal mengambil {path}: {error}") from error

    if not isinstance(payload, dict):
        raise RuntimeError(f"Respons {path} bukan objek JSON.")
    if payload.get("error"):
        raise RuntimeError(f"API {path} mengembalikan error: {payload['error']}")
    return payload


def normalized_name(value: str) -> str:
    return " ".join(value.upper().split())


def find_region(rows: list[dict], requested_name: str, label: str) -> dict:
    wanted = normalized_name(requested_name)
    exact = [row for row in rows if normalized_name(row.get("name", "")) == wanted]
    matches = exact or [
        row for row in rows if wanted in normalized_name(row.get("name", ""))
    ]
    if len(matches) != 1:
        choices = ", ".join(row.get("name", "?") for row in matches[:10])
        detail = f" Kandidat: {choices}" if choices else ""
        raise RuntimeError(
            f"{label} '{requested_name}' tidak cocok secara unik.{detail}"
        )
    return matches[0]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--province", required=True, help="Nama provinsi")
    parser.add_argument("--city", required=True, help="Nama kota/kabupaten")
    parser.add_argument("--month", required=True, type=int, choices=range(1, 13))
    parser.add_argument("--year", required=True, type=int)
    parser.add_argument("--output", required=True, type=Path, help="File JSON tujuan")
    args = parser.parse_args()

    try:
        provinces = get_json("provinsi").get("data", [])
        province = find_region(provinces, args.province, "Provinsi")

        cities = get_json("kabko", {"prov": province["id"]}).get("data", [])
        city = find_region(cities, args.city, "Kota/kabupaten")

        response = get_json(
            "jadwal",
            {
                "prov": province["id"],
                "kabko": city["id"],
                "thn": str(args.year),
                "bln": str(args.month),
            },
        )
        days = response.get("data")
        if response.get("status") != 1 or not isinstance(days, dict) or not days:
            raise RuntimeError(
                f"API tidak mengembalikan jadwal untuk {city['name']} "
                f"{args.month:02d}/{args.year}: {response.get('message', 'respons kosong')}"
            )

        snapshot = {
            "source": "SIHAT Kementerian Agama Republik Indonesia",
            "source_url": f"{API_BASE}/jadwal",
            "retrieved_at_utc": datetime.now(timezone.utc).isoformat(),
            "request": {
                "province": province["name"],
                "city": city["name"],
                "month": args.month,
                "year": args.year,
            },
            "response": response,
        }
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(snapshot, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(
            f"Tersimpan: {args.output} "
            f"({response.get('prov')} / {response.get('kabko')}, "
            f"{len(days)} hari)"
        )
        return 0
    except (KeyError, RuntimeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
