# RetailFlex-Open

Open, reproducible workflows for screening retail-building energy flexibility.

RetailFlex-Open creates transparent EnergyPlus/OpenStudio baseline models, applies explicitly defined flexibility scenarios, and reports changes in energy, demand, operating conditions, and comfort-related metrics. The initial release targets a **screening-level SuperMarket workflow** for Northwest Arkansas. It is not a calibrated Walmart-store digital twin and does not make savings, resilience, refrigeration-safety, or customer-operation claims.

## Version 0.1 scope

1. Generate a current OpenStudio SuperMarket prototype using `openstudio-standards`.
2. Attach a user-supplied EPW and run a sizing pass.
3. Save a traceable OSM model and a machine-readable build manifest.
4. Establish the baseline that future OpenStudio-GEB flexibility measures will modify.

The first planned measures are thermostat adjustment, precooling, lighting reduction, and plug-load reduction. Refrigeration controls are deliberately out of scope until the baseline refrigeration representation has been inspected and validated.

## Decision Sandbox demo

The repository now includes a reproducible, local **RetailFlex Decision Sandbox** workflow. It runs a baseline plus two clearly illustrative schedule scenarios and produces a self-contained HTML page for an Energy/facilities discussion. It is designed to show both favorable and unfavorable results; it does not calculate utility-bill savings or make an operating recommendation.

See the [demo runbook](docs/demo-runbook.md). The public demonstration page is limited to screened, simulated prototype outputs; generated model files and simulation outputs remain local.

## Controlled site-model mode

An authorized retail-store model may be used locally to improve model QA and choose relevant workflow modules without being copied to this repository or disclosed publicly. RetailFlex provides a non-identifying structural-inventory script and a local intake-manifest template; see [controlled site-model mode](docs/controlled-site-mode.md). A controlled model is not, by itself, a calibrated or validated model and cannot support a store-specific savings, safety, or control claim.

Before a site-specific assessment, validate the local intake manifest. The validator never reads the referenced model or data files; it produces a readiness decision from metadata and evidence status only.

```powershell
& 'C:\Users\hanhu\Anaconda3\python.exe' scripts\validate_site_intake.py `
  --input 'private\controlled_site\site_intake.json' `
  --output 'private\controlled_site\readiness_report.json'
```

See the [development plan](docs/development-plan.md) and the [site-intake example](config/site_intake.example.json). The public example is synthetic; completed manifests remain controlled.

## Requirements

- OpenStudio 3.11.0, including its embedded EnergyPlus 25.2.0.
- `openstudio-standards 0.8.5` and `openstudio-geb 0.8.0` installed through the RetailFlex bundle.
- A local EnergyPlus weather station bundle: its `.epw` **and companion `.ddy`** are required for weather-specific sizing; the companion `.stat` is recommended. The public NLR `USA-TMY3-EPW.zip` archive contains Fayetteville, Bentonville, Rogers, and Springdale EPWs. Obtain the matching DDY/STAT from the [official EnergyPlus weather-data page](https://energyplus.net/weather); do not commit any of these files to this repository.

The baseline script runs under the OpenStudio CLI with the locked bundle. Replace the paths below with local paths on the host machine.

```powershell
$env:BUNDLE_WITHOUT = 'test:development'
& 'C:\Program Files\openstudio-3.11.0\bin\openstudio.exe' `
  --bundle 'C:\path\to\Gemfile' `
  --bundle_path 'C:\path\to\openstudio-3.11-bundle' `
  execute_ruby_script scripts\build_supermarket_baseline.rb `
  --epw 'C:\path\to\USA_AR_Fayetteville-Drake.Field.723445_TMY3.epw' `
  --output artifacts\supermarket_fayetteville
```

## Data and model provenance

The repository contains no DOE building-model ZIPs, weather files, CBECS microdata, ComStock outputs, retailer data, utility data, or confidential materials. Obtain each input separately and record its local path and version in the generated manifest.

- Current baseline construction: installed `openstudio-standards` SuperMarket prototype.
- Historical comparison only: DOE post-1980 SuperMarket reference models (EnergyPlus 5.0).
- Weather: NLR Weather Data for Buildings Energy Simulations.
- Stock-level comparison: ComStock aggregate or selected public records, after a release-specific data-dictionary check.

See [model provenance](docs/model-provenance.md) and the [source manifest](config/source_manifest.json).

## Scientific status

Generated models are **simulated screening baselines**. They are not independently validated and must not be presented as representing an individual retail store without site geometry, equipment, schedules, interval energy, and refrigeration/BMS evidence. Annual simulation, sensitivity analysis, and comparison against appropriate reference data are required before interpreting a flexibility result.

## License

RetailFlex-Open source code is licensed under the MIT License. External model and data licenses remain controlling; see their respective source records.
