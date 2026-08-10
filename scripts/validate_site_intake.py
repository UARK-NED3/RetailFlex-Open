#!/usr/bin/env python3
"""Validate a local RetailFlex controlled-site intake without reading data files.

The report intentionally contains statuses and evidence gaps only. It does not
open referenced model, utility, BMS, tariff, or equipment files.
"""

import argparse
import json
from pathlib import Path


ALLOWED_STATUSES = {"available", "not_available", "pending_authorization"}
ALLOWED_FORMATS = {"osm", "idf"}


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"Invalid JSON in {path}: {error}") from error


def status(value: object, label: str, blocks: list[str], warnings: list[str], required: bool = True) -> str:
    if value not in ALLOWED_STATUSES:
        blocks.append(f"{label}: status must be one of {sorted(ALLOWED_STATUSES)}")
        return "invalid"
    if value != "available":
        message = f"{label}: {value.replace('_', ' ')}"
        (blocks if required else warnings).append(message)
    return value


def assess(intake: dict) -> dict:
    blocks: list[str] = []
    warnings: list[str] = []
    site = intake.get("site", {})
    assets = intake.get("data_assets", {})
    governance = intake.get("governance", {})

    if intake.get("classification") != "controlled":
        blocks.append("classification: a site intake must be controlled")
    if site.get("building_type") != "supermarket":
        warnings.append("site.building_type: current workflow is designed for supermarket screening")
    if site.get("model_format") not in ALLOWED_FORMATS:
        blocks.append("site.model_format: must be osm or idf")
    for key in ("model_revision_recorded", "weather_station_recorded"):
        if site.get(key) is not True:
            blocks.append(f"site.{key}: required")

    electricity = assets.get("interval_electricity", {})
    status(electricity.get("status"), "interval_electricity", blocks, warnings)
    if electricity.get("status") == "available":
        if not isinstance(electricity.get("coverage_months"), (int, float)) or electricity["coverage_months"] < 12:
            blocks.append("interval_electricity.coverage_months: at least 12 months required for calibration candidate")
        if electricity.get("interval_minutes") not in {15, 30, 60}:
            blocks.append("interval_electricity.interval_minutes: use 15, 30, or 60 minutes")
        for key in ("time_zone_recorded", "meter_boundary_recorded"):
            if electricity.get(key) is not True:
                blocks.append(f"interval_electricity.{key}: required")

    tariff = assets.get("tariff", {})
    status(tariff.get("status"), "tariff", blocks, warnings)
    if tariff.get("status") == "available" and tariff.get("version_recorded") is not True:
        blocks.append("tariff.version_recorded: required")
    for key in ("equipment_inventory", "operating_constraints", "refrigeration_configuration"):
        status(assets.get(key, {}).get("status"), key, blocks, warnings)
    status(assets.get("bms_trends", {}).get("status"), "bms_trends", blocks, warnings, required=False)

    for key in ("data_use_authorized", "retention_period_recorded", "publication_review_recorded"):
        if governance.get(key) is not True:
            blocks.append(f"governance.{key}: required")
    if not intake.get("requested_decision"):
        blocks.append("requested_decision: required")

    readiness = "blocked" if blocks else ("ready_with_warnings" if warnings else "ready")
    return {
        "schema_version": "0.1.0",
        "classification": "controlled_local_only",
        "report_scope": "intake_status_only_no_source_data_read",
        "readiness": readiness,
        "permitted_next_step": (
            "collect_missing_evidence" if blocks else "configure_site_baseline_and_document_reconciliation"
        ),
        "blocks": blocks,
        "warnings": warnings,
        "prohibited_interpretations": [
            "No store-specific savings claim", "No refrigeration safety or control recommendation", "No live control authorization"
        ]
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate a local RetailFlex site-intake manifest.")
    parser.add_argument("--input", required=True, type=Path, help="Local controlled-site intake JSON")
    parser.add_argument("--output", type=Path, help="Ignored local readiness-report JSON")
    args = parser.parse_args()
    report = assess(load_json(args.input))
    encoded = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    if report["readiness"] == "blocked":
        raise SystemExit(2)


if __name__ == "__main__":
    main()
