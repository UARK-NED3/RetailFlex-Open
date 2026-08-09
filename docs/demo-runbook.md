# RetailFlex Decision Sandbox runbook

This demonstration uses a representative SuperMarket prototype and public weather data. It is a simulated screening workflow, not a Walmart-store model or operating recommendation.

## Reproduce the local demo

1. Generate a weather-sized baseline with `build_supermarket_baseline.rb`.
2. Generate scenario OSMs:

```powershell
& 'C:\Program Files\openstudio-3.11.0\bin\openstudio.exe' execute_ruby_script scripts\prepare_demo_scenarios.rb --baseline artifacts\supermarket_fayetteville\supermarket_baseline.osm --output artifacts\demo\scenarios
```

3. Run annual simulations and check each `run\eplusout.end` for `Completed Successfully`.

```powershell
.\scripts\run_demo_simulations.ps1 -ScenarioDirectory artifacts\demo\scenarios
```

4. Extract results and build the standalone page:

```powershell
& 'C:\Program Files\openstudio-3.11.0\bin\openstudio.exe' execute_ruby_script scripts\summarize_demo_results.rb --scenarios artifacts\demo\scenarios --output artifacts\demo\report
& 'C:\Program Files\openstudio-3.11.0\bin\openstudio.exe' execute_ruby_script scripts\build_demo_html.rb --input artifacts\demo\report\results.json --output artifacts\demo\retailflex_decision_sandbox.html
```

Open the generated HTML file directly in a browser. It has no network dependency.

## Meeting boundary

Show the numerical result even when it is unfavorable. The appropriate outcome is a decision to reject, redesign, or seek site data—not a generic savings claim. Do not add refrigeration control, actual tariff savings, utility-bill savings, or comfort/safety claims without authorized store-specific data and review.
