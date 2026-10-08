# mini_dominium — 30 kunlik roadmap uchun amaliyot to'plami

Bu to'plamdagi barcha ma'lumotlar **sintetik** (o'ylab topilgan). Lekin har bir jadval Dominium loyihasidagi haqiqiy muammoni aynan takrorlaydi. Shuning uchun bu yerda qilgan ishingiz real ishda deyarli bir xil bo'ladi. Bu to'plamni GitHub'ga bemalol yuklashingiz mumkin; Dominium arxividagi haqiqiy fayllarni esa hech qachon yuklamang.

## Tarkib

| Fayl | Dominium'dagi o'xshashi | Qaysi muammoni o'rgatadi | Kunlar |
| --- | --- | --- | --- |
| `data/procore/projects.csv` | `RAW.PROCORE` | kunlik to'liq snapshot, o'chirilgan loyiha faqat eskirgan vaqt belgisi bilan bilinadi | 4, 17, 29 |
| `data/procore/change_events.csv` | `CHANGE_EVENTS` | ~16 marta fan-out, nuqtali ustun nomlari (`"change_order_change_reason.id"`), null kalitli eski qatorlar | 4, 9, 17 |
| `data/procore/change_event_custom_fields.csv` | `CHANGE_EVENT_CUSTOM_FIELDS` | EAV: `id` — change event id; 345079 = kategoriya, 362390 = status | 10, 20 |
| `data/yardi_replicate/property.csv` + `property__ct.csv` | `RAW.YARDI_REPLICATE` (Qlik) | CDC juftligi, `BEFOREIMAGE`, delete, `__ct`da qo'shimcha ustun (drift), `"TYPE"` kalit so'zli ustun | 9, 17 |
| `data/yardi_replicate/unit.csv` + `unit__ct.csv` | Yardi `UNIT` | CDC replay, o'chirilgan property unitlari | 17, 20 |
| `data/propertydata/tblpdb_property.csv` | `TBLPDB_PROPERTY` | unique bo'lmagan `yardihmy`/`txtpropid`, `txtid = '0'` va null qatorlar, 3 ta ingestion | 3, 20 |
| `data/propertydata/tblpdb_valueevents.csv` | PDB value events | axlat kalit orqali join fan-out (17 → 51) | 3 |
| `data/workfront/program_snapshots.csv` | `RAW.WORKFRONT.PRGM` | kunlik snapshot; `UPDATES` — eskida Python `repr`, yangida JSON | 10, 19 |
| `data/nonproforma/deal_proforma_npv.csv` | proforma fayllari | bir deal/tur uchun bir nechta fayl, turli NPV — deterministik tanlash | 20, 27–29 |
| `data/nonproforma/deal_milestones.csv` | Workfront milestone sanalari | snapshot, milestone ladder | 27–29 |
| `seeds/milestone_weights.csv` | milestone weights seed | seed, lookup | 20, 28 |
| `seeds/accretive_override_fields.csv` | override registry | ataylab xato yozilgan `Actual Stablized Occupancy Date` qatori ham kalit | 28 |
| `sharepoint/Accretive Value Overrides.xlsx` | SharePoint'dagi intake varag'i | Excel named table (`AccretiveOverrides`), EAV, 2 ta xato qator | 25, 27 |
| `tickets/T01…T04` | Zendesk ticketlari va WRD | real ish oqimi | 20, 22, 27–29 |
| `solutions/day09_load_raw.sql` | ingestion | stage, file format, COPY INTO | 9 |
| `solutions/answers.md`, `expected_*.csv` | — | o'z natijangizni tekshirish uchun | har kuni |

## Qanday boshlash

1. 8-kunda Snowflake'da bazalar va warehouse'larni o'zingiz yarating.
2. 9-kunda fayllarni stage'ga yuklab, `COPY INTO` bilan `RAW`ga quying. Qotib qolsangiz — `solutions/day09_load_raw.sql`.
3. Har bir modeldan keyin natijani `solutions/answers.md` bilan solishtiring.

## Muhim

- Barcha vaqt belgilari UTC deb qabul qilingan.
- "Bugungi sana" (as-of date) capstone uchun: **2026-09-30**.
- Milestone foizlari va NPV'lar o'ylab topilgan; ular Dominium'ning haqiqiy biznes qoidalari emas.
