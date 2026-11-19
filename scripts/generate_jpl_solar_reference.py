#!/usr/bin/env python3
"""Generate 2026 solar event references from Skyfield and NASA JPL DE421.

Development-time tool only. Run with:
  uv run --with skyfield python scripts/generate_jpl_solar_reference.py
Skyfield downloads the public JPL DE421 ephemeris into its cache on first run.
"""

from __future__ import annotations

from datetime import date, datetime, time, timedelta, timezone
import json
import math
import os
from pathlib import Path
import tempfile
from zoneinfo import ZoneInfo

import skyfield
from skyfield import almanac
from skyfield.api import Loader, wgs84


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
PROFILES = [
    {"id": "mwl_18_17_shafii", "label": "Muslim World League", "fajr_angle_degrees": 18.0, "isha_angle_degrees": 17.0, "asr_shadow_factor": 1.0},
    {"id": "egyptian_19_5_17_5_shafii", "label": "Egyptian General Authority", "fajr_angle_degrees": 19.5, "isha_angle_degrees": 17.5, "asr_shadow_factor": 1.0},
    {"id": "indonesian_20_18_shafii", "label": "Indonesian preset", "fajr_angle_degrees": 20.0, "isha_angle_degrees": 18.0, "asr_shadow_factor": 1.0},
    {"id": "karachi_18_18_shafii", "label": "Karachi preset", "fajr_angle_degrees": 18.0, "isha_angle_degrees": 18.0, "asr_shadow_factor": 1.0},
    {"id": "north_america_15_15_shafii", "label": "North America preset", "fajr_angle_degrees": 15.0, "isha_angle_degrees": 15.0, "asr_shadow_factor": 1.0},
    {"id": "mwl_18_17_hanafi", "label": "Muslim World League, Hanafi Asr", "fajr_angle_degrees": 18.0, "isha_angle_degrees": 17.0, "asr_shadow_factor": 2.0},
]


def iso_utc(value: datetime) -> str:
    value = value.astimezone(timezone.utc)
    value = value.replace(microsecond=0) + timedelta(seconds=round(value.microsecond / 1_000_000))
    return value.isoformat().replace("+00:00", "Z")


def root_time(samples: list[tuple[datetime, float]], target: float, rising: bool, altitude_at) -> datetime | None:
    for (left, left_alt), (right, right_alt) in zip(samples, samples[1:]):
        a, b = left_alt - target, right_alt - target
        if (rising and a <= 0 < b) or (not rising and a >= 0 > b):
            lo, hi = left, right
            for _ in range(36):
                mid = lo + (hi - lo) / 2
                value = altitude_at(mid) - target
                if (value < 0) == rising:
                    lo = mid
                else:
                    hi = mid
            return lo + (hi - lo) / 2
    return None


def all_crossings(samples, target: float, rising: bool, altitude_at) -> list[datetime]:
    crossings = []
    for pair in zip(samples, samples[1:]):
        event = root_time(list(pair), target, rising, altitude_at)
        if event is not None:
            crossings.append(event)
    return crossings


def main() -> None:
    cache_directory = os.environ.get(
        "SKYFIELD_CACHE_DIR",
        str(Path(tempfile.gettempdir()) / "islamic-utility-skyfield"),
    )
    loader = Loader(cache_directory)
    ts = loader.timescale()
    ephemeris = loader("de421.bsp")
    sun = ephemeris["sun"]
    earth = ephemeris["earth"]
    records = []
    for name, latitude, longitude, timezone_name in LOCATIONS:
        zone = ZoneInfo(timezone_name)
        topos = wgs84.latlon(latitude, longitude, elevation_m=0)
        observer = earth + topos
        for civil_date in DATES:
            start_local = datetime.combine(civil_date, time.min, tzinfo=zone)
            end_local = datetime.combine(civil_date + timedelta(days=1), time.min, tzinfo=zone)
            start_utc = start_local.astimezone(timezone.utc)
            end_utc = end_local.astimezone(timezone.utc)

            def altitude_at(instant: datetime) -> float:
                sky_time = ts.from_datetime(instant.astimezone(timezone.utc))
                return observer.at(sky_time).observe(sun).apparent().altaz()[0].degrees

            t0 = ts.from_datetime(start_utc - timedelta(hours=12))
            t1 = ts.from_datetime(end_utc + timedelta(hours=12))
            transit_function = almanac.meridian_transits(ephemeris, sun, topos)
            transit_times, transit_kind = almanac.find_discrete(t0, t1, transit_function)
            transits = [
                t.utc_datetime().astimezone(timezone.utc)
                for t, kind in zip(transit_times, transit_kind)
                if int(kind) == 1
                and t.utc_datetime().astimezone(zone).date() == civil_date
            ]
            transit = transits[0] if transits else None

            if transit is None:
                raise RuntimeError(f"No upper transit for {name} on {civil_date}.")
            # Associate every event with the solar day centered on upper
            # transit, even when sunrise or sunset falls on another UTC date.
            solar_day_start = transit - timedelta(hours=12)
            solar_day_end = transit + timedelta(hours=12)
            duration_minutes = int((solar_day_end - solar_day_start).total_seconds() // 60)
            samples = [
                (solar_day_start + timedelta(minutes=minute), altitude_at(solar_day_start + timedelta(minutes=minute)))
                for minute in range(0, duration_minutes + 1, 5)
            ]
            if samples[-1][0] < solar_day_end:
                samples.append((solar_day_end, altitude_at(solar_day_end)))

            sunrise_candidates = all_crossings(samples, -0.833, True, altitude_at)
            sunset_candidates = all_crossings(samples, -0.833, False, altitude_at)
            fajr_candidates = all_crossings(samples, -18.0, True, altitude_at)
            isha_candidates = all_crossings(samples, -17.0, False, altitude_at)
            sunrise = next((event for event in sunrise_candidates if event < transit), None)
            sunset = next((event for event in sunset_candidates if event > transit), None)
            fajr = next((event for event in reversed(fajr_candidates) if event < transit), None)
            isha = next((event for event in isha_candidates if event > transit), None)

            asr = None
            method_events = {}
            if transit is not None:
                transit_time = ts.from_datetime(transit)
                geocentric_sun = earth.at(transit_time).observe(sun).apparent()
                declination = geocentric_sun.radec(epoch="date")[1].degrees
                for profile in PROFILES:
                    difference = math.radians(abs(latitude - declination))
                    target_asr_altitude = math.degrees(
                        math.atan(
                            1.0
                            / (profile["asr_shadow_factor"] + math.tan(difference))
                        )
                    )
                    asr_candidates = all_crossings(
                        samples, target_asr_altitude, False, altitude_at
                    )
                    profile_asr = next(
                        (event for event in asr_candidates if event > transit), None
                    )
                    profile_fajr = root_time(
                        samples, -profile["fajr_angle_degrees"], True, altitude_at
                    )
                    profile_isha_candidates = all_crossings(
                        samples,
                        -profile["isha_angle_degrees"],
                        False,
                        altitude_at,
                    )
                    profile_isha = next(
                        (event for event in profile_isha_candidates if event > transit),
                        None,
                    )
                    method_events[profile["id"]] = {
                        "asr": iso_utc(profile_asr) if profile_asr else None,
                        "fajr": iso_utc(profile_fajr) if profile_fajr else None,
                        "isha": iso_utc(profile_isha) if profile_isha else None,
                    }
                    if profile["id"] == "mwl_18_17_shafii":
                        asr = profile_asr

            records.append({
                "location": name,
                "latitude": latitude,
                "longitude": longitude,
                "civil_timezone": timezone_name,
                "date": civil_date.isoformat(),
                "method_events_utc": method_events,
                "events_utc": {
                    "transit": iso_utc(transit) if transit else None,
                    "sunrise": iso_utc(sunrise) if sunrise else None,
                    "sunset": iso_utc(sunset) if sunset else None,
                    "asr_shafii": iso_utc(asr) if asr else None,
                    "fajr_18": iso_utc(fajr) if fajr else None,
                    "isha_17": iso_utc(isha) if isha else None,
                },
            })

    output = {
        "source": "NASA/JPL DE421 planetary ephemeris, evaluated with Skyfield",
        "source_url": "https://ssd.jpl.nasa.gov/planets/eph_export.html",
        "skyfield_source": "https://rhodesmill.org/skyfield/",
        "skyfield_version": skyfield.__version__,
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "method": "Topocentric apparent solar altitude from Skyfield/JPL DE421; crossings refined by bisection; upper meridian transit from Skyfield almanac.",
        "coordinate_source": "Representative city coordinates maintained in the package parity test matrix; calculation points, not surveyed observer locations.",
        "assumptions": {
            "sunrise_sunset_center_altitude_degrees": -0.833,
            "fajr_solar_center_altitude_degrees": -18,
            "isha_solar_center_altitude_degrees": -17,
            "asr_shadow_factor": 1,
            "elevation_meters": 0,
            "atmospheric_refraction": "Standard combined sunrise/sunset threshold only; zero-pressure topocentric apparent altitude otherwise.",
            "rounding": "UTC ISO-8601 timestamps rounded to nearest second; no event-minute rounding.",
        },
        "calculation_profiles": PROFILES,
        "records": records,
    }
    path = Path("test/data/reference/astronomy/jpl-de421-2026.json")
    path.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(records)} records to {path}")


if __name__ == "__main__":
    main()
