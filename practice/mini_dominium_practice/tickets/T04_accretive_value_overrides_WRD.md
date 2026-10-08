# T04 — Warehouse Requirements Document: Accretive Value Overrides (capstone)

> Uzbekcha izoh: 27–29-kunlar capstone loyihasi. Bu Dominium'dagi haqiqiy loyihaning soddalashtirilgan nusxasi.

## 1. Business context

Each development deal has a projected value (NPV) from its Excel proforma model. The company recognises a growing share of that NPV as the deal clears milestones. The warehouse calculates this automatically, but sometimes the automation is wrong (a milestone date was never updated in Workfront, a stale proforma file was picked). The deal team needs to **correct** the number without anyone editing the calculated value.

Done means: the deal team types a correction into the SharePoint sheet, it lands in Snowflake, and the corrected value reaches the dashboard. Both the calculated and the corrected value stay visible, so every published number can be traced.

## 2. Sources

| Source | Location | Shape |
| --- | --- | --- |
| Proforma NPVs | `raw.nonproforma.deal_proforma_npv` | several files per deal and proforma type |
| Milestone dates | `raw.nonproforma.deal_milestones` | snapshot per ingestion |
| Milestone weights | seed `milestone_weights.csv` | cumulative % by tax-credit flag |
| Override registry | seed `accretive_override_fields.csv` | which items may be overridden, and how |
| Overrides | `sharepoint/Accretive Value Overrides.xlsx`, sheet `Overrides`, table `AccretiveOverrides` | one row per correction (EAV) |

## 3. Calculation rules (as of date: 2026-09-30)

1. **Proforma choice:** use the most advanced proforma type available for the deal: Closing Model > Live Model > IC Approval Model. Within that type, use the file with the latest `file_last_modified`.
2. **Milestone reached:** use the latest `deal_milestones` snapshot. The milestone reached is the highest `milestone_order` whose date is not null and is on or before the as-of date.
3. **Percentage:** look up the cumulative % for that milestone in `milestone_weights` using `is_tax_credit` (`Y` → tax-credit column, otherwise the non-tax-credit column). No milestone reached → 0.
4. **Accretive value = NPV × percentage.**

## 4. Override rules

1. **Ingestion is append-only.** Every run writes the whole sheet as a new batch with a new `runID`. Only the newest batch (by `ingestionTimeStamp`) is current.
2. Discard rows with no `Workfront Program ID` at ingestion (log how many were discarded).
3. `Item to be Overridden` must match `item_name` in the registry exactly, typos included. Rows that do not match are **not applied** and must surface as a dbt test **warning**, not an error (one bad cell must not stop the pipeline).
4. An override is active when the as-of date is between `Valid from` and `Valid until` (blank `Valid until` = open-ended).
5. Several active overrides for the same deal and item → the one with the latest `Date of Override` wins.
6. Apply by `override_kind`: `milestone_date` replaces that date before the milestone is recomputed; `base_value` replaces the NPV, but only when `Proforma Type` is blank or equals the chosen proforma type; `weight_driver` replaces `is_tax_credit`; `attribute` is stored and shown, but does not change the value.

## 5. Required outputs

| Model | Grain | Notes |
| --- | --- | --- |
| `base_non_proforma__accretive_overrides` | one row per override row of the current batch | typed, renamed, current batch only |
| `int_deals_accretive_base` | one row per deal | the calculated values, no overrides |
| `int_deals_accretive_overrides` | one row per deal and item | active, registry-valid, latest-wins overrides |
| `mart_deals_accretive` | one row per deal | calculated **and** final columns side by side, plus `overrides_applied` |

Tests: `unique` + `not_null` on every grain key; `relationships` from overrides to the registry with `severity: warn`; a test that deals with no overrides have final = calculated.

## 6. Acceptance

Your `mart_deals_accretive` must match `solutions/expected_mart_deals_accretive.csv` for every deal (7 rows).
