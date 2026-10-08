# Javoblar kaliti (avval o'zingiz ishlang!)

Bu sonlar generator skripti va mustaqil SQL tekshiruvi bilan tasdiqlangan. Modelingiz boshqa son bersa, xato sizning logikangizda — sonni "moslashtirmang", sababini toping.

## RAW yuklangandan keyin (9-kun)

| Jadval | Qatorlar |
| --- | --- |
| raw.procore.projects | 159 |
| raw.procore.change_events | 584 |
| raw.procore.change_event_custom_fields | 1162 |
| raw.yardi_replicate.property / property__ct | 6 / 8 |
| raw.yardi_replicate.unit / unit__ct | 48 / 36 |
| raw.propertydata.tblpdb_property / tblpdb_valueevents | 33 / 17 |
| raw.workfront.prgm | 80 |
| raw.nonproforma.deal_proforma_npv / deal_milestones | 26 / 14 |

## Procore (4, 17-kunlar)

| Savol | Javob |
| --- | --- |
| Kalitlari null bo'lgan eski shakldagi qatorlar | 3 (`title = 'Function_Name'`) |
| Noyob change event `id` lar | 36 |
| Fan-out koeffitsienti (xom qator / noyob id) | ≈ 16,1 |
| `int_procore__change_event_daily` (id × kun) | 442 qator |
| Oxirgi ingestion'da bor (joriy) change eventlar | 30 |
| Eskirgan (Procore'da o'chirilgan) change eventlar | 6 |
| Joriy loyihalar / o'chirilgan loyiha | 5 / 1 (`Cedar Point (cancelled)`, id 3300103) |

## Yardi CDC (17-kun)

| Savol | Javob |
| --- | --- |
| `historical_yardi_property` (full load + `BEFOREIMAGE`siz o'zgarishlar) | 11 qator |
| Joriy propertylar (`latest_yardi_property`) | 6 ta: hMy 1, 2, 3, 4, 6, 7 (5 o'chirilgan, 7 yangi) |
| hMy = 3 ning joriy `iUnits` qiymati | 224 |
| Joriy unitlar | 48 |
| Joriy propertylar bo'yicha band (Occupied) unitlar | 1→6, 2→4, 3→5, 4→5, 6→2, 7→0 |

## PDB (3, 20-kunlar)

| Savol | Javob |
| --- | --- |
| `int_pdb__property_resolved` (har `yardihmy > 0` uchun bitta, Active ustun) | 7 qator |
| hMy = 3 uchun tanlangan `txtpropid` | P-1003 (Inactive P-0991 emas) |
| valueevents × xom property, hech qanday filtrsiz join | 51 qator (fan-out!) |
| Oxirgi ingestion + `try_to_number(txtid) > 0` bilan join | 14 qator |

## Workfront (10, 19-kunlar)

| Savol | Javob |
| --- | --- |
| Joriy programlar | 8 |
| `UPDATES` formati | 1–5 sentabr: Python `repr()` (bitta qo'shtirnoq), 6–10 sentabr: haqiqiy JSON |
| Ehtiyot bo'ling | `Can't` va `Lender's` so'zlaridagi apostrof — oddiy `replace("'", '"')` JSON'ni buzadi |

## T01 — mart_yardi__dim_property

6 qator (hMy 1, 2, 3, 4, 6, 7). Har birida 8 ta unit; band unitlar yuqoridagi jadvaldagidek.

## T02 — to'g'ri sonlar (joriy loyiha × joriy change event)

| Loyiha | Change eventlar |
| --- | --- |
| Lakeside Townhomes | 9 |
| Maple Ridge Apartments | 6 |
| Oakwood Rehab | 5 |
| Riverbend Senior Living | 4 |
| Solivita Commons | 6 |

Ikki muammo: (1) snapshotlar collapse qilinmagan — har bir change event har bir ingestion uchun takrorlanadi, va loyihalar ham takrorlanadi, shuning uchun join ko'paytma beradi; (2) Procore'da o'chirilgan qatorlar eski snapshotlarda qolib ketgan — ularni faqat eskirgan `Insertion_TimeStamp` orqali aniqlash mumkin.

## T04 — capstone

`expected_mart_deals_accretive.csv` — 7 ta deal. Override varag'ida 9 qator bor: 1 tasi `Workfront Program ID`siz (ingestion'da tashlanadi), 1 tasi registry'da yo'q item (`Mariposa Gardens` — warning), 1 tasi muddati o'tgan (Maple Ridge, `Valid until` 2026-06-30), 1 tasi boshqa proforma turiga tegishli (Harbor View — qo'llanmaydi), Riverbend'da ikkita NPV tuzatishi (yangisi, 17 500 000 yutadi).
