# Controlled site-model mode

RetailFlex-Open can use an authorized customer or partner model as a **local reference** while keeping that model, its inputs, its outputs, and all identifying derivatives outside the public repository.

This mode is appropriate for a representative retail-store model held in a controlled UA workspace. It does not make the model open, transfer any rights, or establish that the model is calibrated, validated, or approved for operations.

## Boundary

Keep all controlled materials in an ignored local folder such as `private/` or a separately access-controlled workspace:

- OpenStudio/EnergyPlus model files, schedules, geometry, weather files, and simulation outputs;
- interval utility, tariff, BMS, CMMS, equipment, refrigeration, and occupancy data;
- screenshots, store identifiers, model names, floor plans, and model-derived figures that could identify a store;
- completed intake manifests and site-specific reports.

The public repository may contain only generic schemas, code, tests, synthetic examples, and documentation. Never commit a completed controlled-site manifest.

## Local workflow

1. Copy `config/controlled_site_manifest.example.json` and `config/site_intake.example.json` into the controlled workspace and complete them there.
2. Confirm the use authorization, data owner, allowed recipients, retention period, publication review, and whether results may be aggregated or disclosed.
3. Run a structural inventory. It emits counts only—no model path, geometry, object names, schedules, location, or equipment names.

```powershell
& 'C:\Program Files\openstudio-3.11.0\bin\openstudio.exe' execute_ruby_script `
  scripts\inspect_controlled_site_model.rb `
  --model 'C:\controlled_workspace\site_model.osm' `
  --output 'private\controlled_site\intake'
```

4. Use the inventory to choose applicable public workflow modules (baseline QA, HVAC/lighting scenario screening, or design comparison). Do not infer performance or a control recommendation from structure alone.
5. For any site-specific assessment, retain a separate controlled provenance record that links the model revision, weather, utility interval data, tariff, model assumptions, simulation version, QA results, and reviewer decision.

Run `scripts/validate_site_intake.py` before a site-specific assessment. Its readiness report intentionally blocks work when authorization, interval electricity, tariff, equipment/constraint information, or provenance fields are incomplete. The validator does not open data files.

## Evidence ladder

| Status | Minimum evidence | Permitted conclusion |
|---|---|---|
| Controlled structural reference | Authorized model and non-identifying inventory | Select relevant QA and scenario modules. |
| Site-configured baseline | Model plus documented site assumptions | Simulated screening comparison only. |
| Calibration candidate | Interval utility data and documented reconciliation | Assess calibration quality; no operational recommendation yet. |
| Pilot-ready advisory | Calibration review, constraints, tariff, HVAC/refrigeration/operations sign-off | Propose a bounded, read-only or supervised pilot. |

Refrigeration control, customer comfort, food safety, and live BAS control are out of scope unless separately authorized and reviewed by the responsible owner and qualified personnel.
