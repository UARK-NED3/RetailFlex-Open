#!/usr/bin/env python3
"""Build public, derived TMY3 climate metrics for the RetailFlex Climate Atlas.

The generator reads a user-local public EPW archive and writes station-level
derived metrics only. It never copies EPW records into the repository output.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
from pathlib import Path
import statistics
import zipfile


BASE_C = 18.3
HOT_C = 30.0
HOT_HUMID_DB_C = 26.7
HOT_HUMID_DP_C = 18.3


def number(value: str) -> float | None:
    try:
        result = float(value)
    except (TypeError, ValueError):
        return None
    return result if result < 90 else None  # EPW missing temperature sentinels


def regional_group(state: str) -> str:
    if state == "AK":
        return "Alaska"
    if state == "HI":
        return "Hawaii"
    if state in {"GU", "PR", "VI", "AS"}:
        return "Territories"
    return "Contiguous U.S."


def archetype(cdd: float, hdd: float, humid_hours: int) -> str:
    """Transparent RetailFlex screening labels, not ASHRAE climate zones."""
    if cdd >= 1200:
        return "hot-humid" if humid_hours >= 500 else "hot-dry"
    if hdd >= 2400:
        return "cold"
    if cdd >= 500:
        return "mixed-cooling"
    return "mixed-heating"


def read_station(archive: zipfile.ZipFile, member: str) -> dict | None:
    with archive.open(member) as binary:
        rows = csv.reader(io.TextIOWrapper(binary, encoding="utf-8-sig", newline=""))
        header = [next(rows, []) for _ in range(8)]
        location = header[0]
        if len(location) < 10 or location[0].strip().upper() != "LOCATION":
            return None
        city, state, country = location[1].strip(), location[2].strip(), location[3].strip()
        latitude, longitude, elevation = (float(location[index]) for index in (6, 7, 9))
        dry_bulb: list[float] = []
        cooling_degree_hours = heating_degree_hours = 0.0
        hot_hours = humid_hot_hours = 0
        annual_ghi_wh_m2 = 0.0
        for row in rows:
            if len(row) < 22:
                continue
            db, dp = number(row[6]), number(row[7])
            if db is None:
                continue
            dry_bulb.append(db)
            cooling_degree_hours += max(0.0, db - BASE_C)
            heating_degree_hours += max(0.0, BASE_C - db)
            hot_hours += int(db >= HOT_C)
            humid_hot_hours += int(db >= HOT_HUMID_DB_C and dp is not None and dp >= HOT_HUMID_DP_C)
            try:
                ghi = float(row[13])
            except (TypeError, ValueError):
                ghi = 0.0
            annual_ghi_wh_m2 += max(0.0, min(ghi, 1500.0))
    if len(dry_bulb) < 8000:
        return None
    cdd = cooling_degree_hours / 24.0
    hdd = heating_degree_hours / 24.0
    return {
        "type": "Feature",
        "properties": {
            "station_id": str(location[5]).strip(),
            "city": city,
            "state": state,
            "country": country,
            "region": regional_group(state),
            "elevation_m": round(elevation, 1),
            "dry_bulb_mean_c": round(statistics.fmean(dry_bulb), 2),
            "dry_bulb_max_c": round(max(dry_bulb), 1),
            "cooling_degree_days_c": round(cdd, 1),
            "heating_degree_days_c": round(hdd, 1),
            "hot_hours_ge_30c": hot_hours,
            "hot_humid_hours": humid_hot_hours,
            "annual_ghi_kwh_m2": round(annual_ghi_wh_m2 / 1000.0, 1),
            "retail_climate_archetype": archetype(cdd, hdd, humid_hot_hours),
            "evidence_class": "derived_from_typical_meteorological_year",
        },
        "geometry": {"type": "Point", "coordinates": [round(longitude, 4), round(latitude, 4)]},
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Build derived EPW climate metrics for RetailFlex Climate Atlas.")
    parser.add_argument("--weather-archive", required=True, type=Path, help="Local public ZIP containing EPW files")
    parser.add_argument("--output", required=True, type=Path, help="Output GeoJSON path")
    parser.add_argument("--javascript-output", type=Path, help="Optional local-script atlas data output")
    args = parser.parse_args()
    if not args.weather_archive.is_file():
        raise SystemExit(f"Weather archive not found: {args.weather_archive}")
    features: list[dict] = []
    with zipfile.ZipFile(args.weather_archive) as archive:
        members = sorted(member for member in archive.namelist() if member.lower().endswith(".epw"))
        for member in members:
            feature = read_station(archive, member)
            if feature:
                features.append(feature)
    output = {
        "type": "FeatureCollection",
        "metadata": {
            "schema_version": "0.1.0",
            "title": "RetailFlex Climate Atlas — U.S. TMY3 derived station metrics",
            "source": "NLR Weather Data for Buildings Energy Simulations, DOI: 10.7799/1603006",
            "source_archive": args.weather_archive.name,
            "source_records_redistributed": False,
            "derivation": "Hourly EPW records aggregated locally to station-level climate indicators; raw EPW records are not included.",
            "claim_boundary": "Typical-meteorological-year screening indicators, not observed store weather, utility load, design certification, or future-climate projections.",
            "archetype_definition": "RetailFlex screening labels: hot-humid if CDD18.3 >=1200 and hot-humid hours >=500; hot-dry if CDD18.3 >=1200 otherwise; cold if HDD18.3 >=2400; mixed-cooling if CDD18.3 >=500; mixed-heating otherwise.",
            "station_count": len(features)
        },
        "features": features,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, separators=(",", ":")), encoding="utf-8")
    if args.javascript_output:
        args.javascript_output.parent.mkdir(parents=True, exist_ok=True)
        args.javascript_output.write_text(
            "window.RETAILFLEX_CLIMATE_ATLAS=" + json.dumps(output, separators=(",", ":")) + ";\n",
            encoding="utf-8",
        )
    print(f"Wrote {len(features)} derived station metrics to {args.output}")


if __name__ == "__main__":
    main()
