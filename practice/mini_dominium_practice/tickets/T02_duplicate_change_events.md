# T02 — Cost Issue Tracking dashboard shows thousands of change events

> Uzbekcha izoh: 22-kun va 29-kunda ishlatiladi (incident mashqi).

**From:** Construction Finance
**Channel:** Zendesk
**Priority:** High

The Cost Issue Tracking page says Lakeside Townhomes has 4,760 change events. The project has maybe ten. It also still lists "Cedar Point (cancelled)", which was deleted in Procore weeks ago. Can you check?

---

## The query behind the dashboard tile (written by a previous contractor)

```sql
select
    p."name" as project_name,
    count(*) as change_events
from raw.procore.change_events as ce
inner join raw.procore.projects as p
    on ce."project_id" = p."id"
group by 1
order by 1;
```

## Your job

1. Explain in two sentences **why** the numbers are wrong (there are two separate problems).
2. Write the corrected logic as dbt models, not as a dashboard query.
3. Add the test that would have caught this before the business did.
4. Write the reply to the business user: plain English, no SQL, what was wrong and when it is fixed.
