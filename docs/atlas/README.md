# RetailFlex Climate Atlas

Public U.S. climate-station screening layer for RetailFlex-Open. It uses station-level metrics derived from typical-meteorological-year EnergyPlus weather files; it does not contain raw weather records, store locations, models, utility data, or simulated store results.

## Metrics

- Cooling/heating degree days: hourly dry-bulb departures from 18.3 °C, divided by 24.
- Hot hours: dry bulb at least 30 °C.
- Hot-humid hours: dry bulb at least 26.7 °C and dew point at least 18.3 °C.
- Annual GHI: sum of EPW global horizontal irradiance.

The “Retail climate archetype” is a transparent RetailFlex screening label, not an ASHRAE climate zone or design classification. Its exact thresholds are embedded in the GeoJSON metadata.

## Build

The generated GeoJSON contains aggregates only. Rebuild it from a locally held public EPW archive:

```powershell
& 'C:\Users\hanhu\Anaconda3\python.exe' scripts\build_climate_atlas.py `
  --weather-archive 'C:\path\to\USA-TMY3-EPW.zip' `
  --output docs\atlas\data\retailflex_climate_atlas_tmy3.geojson `
  --javascript-output docs\atlas\data\retailflex_climate_atlas_tmy3.js
```

Source: Merket and Adhikari, *Weather Data for Buildings Energy Simulations*, NLR Data Catalog, DOI [10.7799/1603006](https://doi.org/10.7799/1603006). Retain source attribution and applicable NLR terms. The atlas is a TMY screening resource, not an observed-extreme or future-climate assessment.
