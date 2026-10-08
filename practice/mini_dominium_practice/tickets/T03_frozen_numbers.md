# T03 — "The numbers haven't changed since Tuesday"

> Uzbekcha izoh: 29-kun incident mashqi. Avval o'zingiz buzasiz, keyin topasiz.

**From:** Board book analyst
**Priority:** High

The occupancy tile shows exactly the same numbers it showed on Tuesday, even though the property team says units turned over this week.

---

## Set-up (do this yourself before you investigate, so there is something to find)

1. In your Snowflake practice account, suspend one of your dynamic tables:
   `alter dynamic table <your_db>.<your_schema>.<one_latest_model> suspend;`
2. Insert one new CDC row into `raw.yardi_replicate.unit__ct` that changes a unit status.
3. Wait for the downstream lag, then confirm the mart did not change.

## Your job

1. Find the frozen object using `information_schema.dynamic_table_refresh_history` and `show dynamic tables`.
2. Explain why nothing errored (hint: a dynamic table keeps serving its last good result).
3. Fix it, and write a 5-line runbook entry: symptom, where to look, the fix, how to verify, how to prevent.
