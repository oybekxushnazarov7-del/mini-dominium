# T01 — Property dimension for the Property Ops dashboard

> Uzbekcha izoh: bu 20-kun vazifasi. Ticket inglizcha, chunki real ishda ham shunday keladi.

**From:** Dana Whitfield (Property Operations)
**Channel:** Zendesk
**Priority:** Medium

Hi team,

The Property Ops dashboard needs one clean list of our properties. Today every report builds its own list and they never agree. Could you give us a table with:

- one row per **current** property (deleted properties must not show up),
- the Yardi property handle, the property code and name, city and state,
- the PDB property id (`txtpropid`) and market,
- total units and occupied units from Yardi.

We will point Power BI at it, so please make sure the property handle is unique.

Thanks,
Dana

---

## Engineering notes (what the team agreed in the follow-up call)

- Grain: one row per Yardi property handle (`hMy`).
- Join Yardi to PDB **only** through a resolved PDB model (PDB keys are not unique; see the Day 4 and Day 20 lessons).
- Unit counts come from the current Yardi `unit` table (CDC replayed, deletes removed).
- Name the mart `mart_yardi__dim_property`; keep it a thin projection over `int_yardi__dim_property`.
- Minimum tests: `unique` + `not_null` on `property_hmy`, `not_null` on `property_code`.
