# Model provenance and claim boundary

## Current executable baseline

The intended RetailFlex baseline is generated locally with `openstudio-standards`, not copied from the legacy DOE SuperMarket ZIPs. This protects compatibility with the current OpenStudio runtime and makes the standards, climate-zone designation, weather file, and sizing results explicit.

The v0.1 script defaults to `90.1-2013_SuperMarket` and `ASHRAE 169-2013-4A`. Those choices are a reproducible starting point, not a claim that a specific Arkansas store complies with that standard or has that exact configuration.

## Historical DOE reference model

DOE's post-1980 SuperMarket reference archive contains refrigeration cases and compressor-rack objects and is useful as an archival comparison reference. Its IDFs declare EnergyPlus 5.0.0. The EnergyPlus 26.1 updater installed for this project begins at EnergyPlus 9.0.0, so the legacy file must not be treated as current-toolchain executable input.

## Weather and sizing boundary

The prototype creation routine first applies a climate-zone-specific prototype. RetailFlex then attaches the user-supplied EPW and performs a separate local sizing pass. A generated manifest records the EPW path, filename, template, climate zone, and runtime version. This is a simulated construction/sizing result, not calibration.

## Validation boundary

Before any energy-flexibility conclusion, retain and inspect at least:

1. EnergyPlus severe errors and warnings.
2. Annual electricity and gas use by end use.
3. Monthly peak electrical demand and timing.
4. Unmet heating/cooling hours and relevant refrigerated-zone conditions.
5. Sensitivity to weather, schedules, controls, and key equipment assumptions.

Customer-specific claims require authorized site data and a separately documented calibration/validation plan.
