#!/usr/bin/env python3
"""Generate a small independent solar-event reference from NOAA equations.

This is a deliberately separate implementation of NOAA GML's published
fractional-year equations. It is a validation reference, not a replacement
for a high-precision ephemeris (such as NREL SPA).
"""

from __future__ import annotations

from datetime import date, datetime, time, timedelta, timezone
import json
import math
from pathlib import Path


LOCATIONS = [
    ("Jakarta", -6.2088, 106.8456, "Asia/Jakarta"),
    ("Singapore", 1.3521, 103.8198, "Asia/Singapore"),
    ("Makkah", 21.4225, 39.8262, "Asia/Riyadh"),
    ("London", 51.5072, -0.1276, "Europe/London"),
    ("Reykjavik", 64.1466, -21.9426, "Atlantic/Reykjavik"),
    ("Tromso", 69.6492, 18.9553, "Europe/Oslo"),
    ("Sydney", -33.8688, 151.2093, "Australia/Sydney"),
    ("Ushuaia", -54.8019, -68.3030, "America/Argentina/Ushuaia"),
]
DATES = [date(2026, m, d) for m, d in ((1, 15), (3, 20), (6, 21), (9, 22))]
TWILIGHT_ANGLES = {"fajr": -18.0, "isha": -17.0}


def solar_terms(instant: datetime) -> tuple[float, float]:
    """Return NOAA equation of time (min) and solar declination (radians)."""
    day = instant.timetuple().tm_yday
    days = 366 if date(instant.year, 12, 31).timetuple().tm_yday == 366 else 365
    hour = instant.hour + instant.minute / 60 + instant.second / 3600
    gamma = 2 * math.pi / days * (day - 1 + (hour - 12) / 24)
    eqtime = 229.18 * (
        0.000075 + 0.001868 * math.cos(gamma) - 0.032077 * math.sin(gamma)
        - 0.014615 * math.cos(2 * gamma) - 0.040849 * math.sin(2 * gamma)
    )
    decl = (
        0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma)
        - 0.006758 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma)
        - 0.002697 * math.cos(3 * gamma) + 0.00148 * math.sin(3 * gamma)
    )
    return eqtime, decl


def altitude(instant: datetime, lat: float, lon: float) -> float:
    eqtime, decl = solar_terms(instant)
    minutes = instant.hour * 60 + instant.minute + instant.second / 60
    true_solar = (minutes + eqtime + 4 * lon) % 1440
    hour_angle = math.radians(true_solar / 4 - 180)
    latitude = math.radians(lat)
    sine = math.sin(latitude) * math.sin(decl) + math.cos(latitude) * math.cos(decl) * math.cos(hour_angle)
    return math.degrees(math.asin(max(-1.0, min(1.0, sine))))


def solve_crossing(day: date, lat: float, lon: float, target: float, rising: bool) -> str | None:
    local_solar_noon_utc = datetime.combine(day, time(12), tzinfo=timezone.utc) - timedelta(minutes=4 * lon)
    start = local_solar_noon_utc - timedelta(hours=12)
    previous_time = start
    previous_value = altitude(previous_time, lat, lon) - target
    for minute in range(1, 24 * 60 + 1):
        current_time = start + timedelta(minutes=minute)
        current_value = altitude(current_time, lat, lon) - target
        crossed = (previous_value <= 0 < current_value) if rising else (previous_value >= 0 > current_value)
        if crossed:
            lo, hi = previous_time, current_time
            for _ in range(32):
                mid = lo + (hi - lo) / 2
                value = altitude(mid, lat, lon) - target
                if (value < 0) == rising:
                    lo = mid
                else:
                    hi = mid
            event = lo + (hi - lo) / 2
            event = event.replace(microsecond=0) + timedelta(seconds=round(event.microsecond / 1_000_000))
            return event.isoformat().replace("+00:00", "Z")
        previous_time, previous_value = current_time, current_value
    return None


def solar_noon(day: date, lon: float) -> str:
    instant = datetime.combine(day, time(12), tzinfo=timezone.utc)
    for _ in range(5):
        eqtime, _ = solar_terms(instant)
        instant = datetime.combine(day, time.min, tzinfo=timezone.utc) + timedelta(minutes=720 - 4 * lon - eqtime)
    return instant.isoformat().replace("+00:00", "Z")


def asr_altitude(day: date, lat: float, factor: float = 1.0) -> float:
    noon = datetime.combine(day, time(12), tzinfo=timezone.utc)
    _, decl = solar_terms(noon)
    zenith_distance = abs(math.radians(lat) - decl)
    shadow = factor + math.tan(zenith_distance)
    return math.degrees(math.atan(1 / shadow))


def main() -> None:
    records = []
    for name, lat, lon, timezone_name in LOCATIONS:
        for day in DATES:
            events = {
                "transit": solar_noon(day, lon),
                "sunrise": solve_crossing(day, lat, lon, -0.833, True),
                "sunset": solve_crossing(day, lat, lon, -0.833, False),
                "asr_shafii": solve_crossing(day, lat, lon, asr_altitude(day, lat, 1), False),
                "fajr_18": solve_crossing(day, lat, lon, -18, True),
                "isha_17": solve_crossing(day, lat, lon, -17, False),
            }
            records.append({"location": name, "latitude": lat, "longitude": lon, "civil_timezone": timezone_name, "date": day.isoformat(), "events_utc": events})
    output = {
        "source": "NOAA Global Monitoring Laboratory, General Solar Position Calculations",
        "source_url": "https://www.gml.noaa.gov/grad/solcalc/solareqns.PDF",
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "method": "Independent Python implementation of NOAA fractional-year equation-of-time and declination equations; UTC event crossings found by bisection.",
        "coordinate_source": "Representative city coordinates maintained in the package's parity test matrix; these are calculation points, not surveyed observer locations.",
        "assumptions": {
            "sunrise_sunset_center_altitude_degrees": -0.833,
            "fajr_solar_center_altitude_degrees": -18,
            "isha_solar_center_altitude_degrees": -17,
            "asr_shadow_factor": 1,
            "elevation_meters": 0,
            "rounding": "UTC ISO-8601 timestamps to nearest millisecond; no civil timezone or minute rounding",
        },
        "records": records,
    }
    path = Path("test/data/reference/astronomy/noaa-2026.json")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(records)} reference records to {path}")


if __name__ == "__main__":
    main()
