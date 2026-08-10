# RetailFlex-Open development plan

## Purpose

RetailFlex-Open is evolving from a public prototype demonstration into a reproducible workflow for screening retail-building energy decisions. It is not an autonomous controller or a substitute for licensed design, food-safety, refrigeration, or facilities authority.

## Track A — development without user or owner input

| Deliverable | Decision enabled | Completion condition |
|---|---|---|
| Public prototype baseline and synthetic decision sandbox | Explain the method and its claim boundary | Reproducible simulation and explicit screening-only language |
| Controlled site-model adapter | Safely inventory an authorized local OSM or IDF without copying it | Counts-only output written to an ignored location |
| Site-intake contract and validator | Determine whether a site assessment can begin | Deterministic ready/blocked report with missing-evidence reasons |
| Readiness report | Identify the next evidence collection step | No savings/control recommendation when critical inputs are missing |
| Scenario-library specification | Bound measures before an owner supplies data | Each measure has applicable system, mechanism, data need, and approval gate |
| Tests and release checks | Keep public material non-confidential and reproducible | Automated repository-contract tests pass |

## Track B — development requiring user, owner, or practitioner input

| Required input/decision | Owner | Why it is needed | Resulting capability |
|---|---|---|---|
| Written data-use and publication boundary | Retailer/owner and UA | Defines what may be retained, shared, aggregated, or published | Controlled project workspace |
| Model identity/revision and source assumptions | Model owner/design team | Prevents configuration drift | Site-configured baseline |
| 12 months of interval whole-building electricity and meter definition | Owner/utility team | Tests time alignment and baseline realism | Calibration candidate |
| Tariff, billing determinants, and billing period | Owner/utility team | Converts demand/energy outputs to an economic screen | Tariff-aware decision report |
| HVAC/refrigeration inventory, schedules, and operating constraints | Facilities/operations | Prevents infeasible or unsafe measures | Constrained measure selection |
| Read-only BMS trends and point dictionary, if approved | Controls/facilities | Tests model behavior at relevant operating periods | Advisory-pilot design |
| Success metric and implementation authority | Energy lead and facilities lead | Resolves whether the task is energy, peak, reliability, comfort, or design | Bounded pilot charter |

## Sequencing

1. Complete Track A and use only synthetic/prototype material in public demonstrations.
2. Hold a data-and-operations scoping meeting; complete the controlled intake manifest locally.
3. Run the readiness validator. A critical block means collect evidence rather than simulate a recommendation.
4. Configure and QA a site baseline; document the reconciliation result.
5. Evaluate only approved measures against tariff, operating, safety, and comfort constraints.
6. Present an advance, redesign, collect-data, or reject decision. Live control is outside this plan.
