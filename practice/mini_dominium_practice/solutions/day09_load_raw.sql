-- =====================================================================
-- mini_dominium: RAW qatlamini yuklash skripti (9-kun uchun yechim)
-- Avval o'zingiz yozib ko'ring. Qotib qolsangizgina shu faylga qarang.
-- Snowsight worksheet'da, ACCOUNTADMIN yoki SYSADMIN roli bilan ishga tushiring.
-- =====================================================================

use role sysadmin;

-- 1. Warehouse'lar (Dominium'dagi 3 ta warehouse nusxasi, eng kichik o'lcham)
create warehouse if not exists ingesting_wh
    warehouse_size = 'XSMALL' auto_suspend = 60 auto_resume = true initially_suspended = true;
create warehouse if not exists transforming_wh
    warehouse_size = 'XSMALL' auto_suspend = 60 auto_resume = true initially_suspended = true;
create warehouse if not exists adhoc_analytics_wh
    warehouse_size = 'XSMALL' auto_suspend = 60 auto_resume = true initially_suspended = true;
use warehouse ingesting_wh;

-- 2. Bazalar va sxemalar
create database if not exists raw;
create database if not exists transformed;
create database if not exists ad_hoc;

create schema if not exists raw.procore;
create schema if not exists raw.yardi_replicate;
create schema if not exists raw.propertydata;
create schema if not exists raw.workfront;
create schema if not exists raw.nonproforma;
create schema if not exists raw.metadata;
create schema if not exists raw.landing;

-- 3. File format va stage
create or replace file format raw.landing.csv_with_header
    type = csv
    skip_header = 1
    field_optionally_enclosed_by = '"'
    empty_field_as_null = true
    null_if = ('');

create or replace stage raw.landing.mini_dominium_stage
    file_format = raw.landing.csv_with_header;

-- 4. Fayllarni stage'ga yuklash. Ikki yo'l:
--   a) Snowsight: Data > Databases > RAW > LANDING > Stages > MINI_DOMINIUM_STAGE > "+ Files"
--      (papka nomini, masalan procore/, "Path" maydoniga yozing)
--   b) Snow CLI / SnowSQL terminalda (yo'lni o'zingiznikiga almashtiring):
--      put file:///Users/siz/mini_dominium_practice/data/procore/*.csv @raw.landing.mini_dominium_stage/procore/ auto_compress=true;
--      put file:///Users/siz/mini_dominium_practice/data/yardi_replicate/*.csv @raw.landing.mini_dominium_stage/yardi_replicate/ auto_compress=true;
--      put file:///Users/siz/mini_dominium_practice/data/propertydata/*.csv @raw.landing.mini_dominium_stage/propertydata/ auto_compress=true;
--      put file:///Users/siz/mini_dominium_practice/data/workfront/*.csv @raw.landing.mini_dominium_stage/workfront/ auto_compress=true;
--      put file:///Users/siz/mini_dominium_practice/data/nonproforma/*.csv @raw.landing.mini_dominium_stage/nonproforma/ auto_compress=true;
list @raw.landing.mini_dominium_stage;

-- 5. PROCORE: xom ustun nomlari aynan manbadagidek (nuqtali, mixed-case) -> qo'shtirnoq shart
create or replace table raw.procore.projects (
    "id" varchar, "name" varchar, "project_type" varchar, "status" varchar, "Insertion_TimeStamp" varchar
);
create or replace table raw.procore.change_events (
    "id" varchar, "number" varchar, "title" varchar, "status" varchar, "project_id" varchar,
    "created_at" varchar, "updated_at" varchar,
    "change_order_change_reason.id" varchar, "change_order_change_reason.change_reason" varchar,
    "change_event_status.name" varchar, "Insertion_TimeStamp" varchar
);
create or replace table raw.procore.change_event_custom_fields (
    "id" varchar, "custom_field_definition_id" varchar, "value" varchar, "Insertion_TimeStamp" varchar
);
copy into raw.procore.projects from @raw.landing.mini_dominium_stage/procore/ pattern = '.*projects[.]csv.*';
copy into raw.procore.change_events from @raw.landing.mini_dominium_stage/procore/ pattern = '.*change_events[.]csv.*';
copy into raw.procore.change_event_custom_fields from @raw.landing.mini_dominium_stage/procore/ pattern = '.*change_event_custom_fields[.]csv.*';

-- 6. YARDI (Qlik Replicate juftliklari): TABLE + TABLE__ct
create or replace table raw.yardi_replicate.property (
    "hMy" number, "sCode" varchar, "sName" varchar, "sCity" varchar, "sState" varchar, "iUnits" number, "TYPE" varchar
);
create or replace table raw.yardi_replicate.property__ct (
    "header__change_seq" varchar, "header__change_oper" varchar, "header__operation" varchar,
    "header__timestamp" timestamp_ntz,
    "hMy" number, "sCode" varchar, "sName" varchar, "sCity" varchar, "sState" varchar, "iUnits" number, "TYPE" varchar,
    "dtLastInspection" date
);
create or replace table raw.yardi_replicate.unit (
    "hMy" number, "hProperty" number, "sCode" varchar, "dSqFt" number, "sStatus" varchar
);
create or replace table raw.yardi_replicate.unit__ct (
    "header__change_seq" varchar, "header__change_oper" varchar, "header__operation" varchar,
    "header__timestamp" timestamp_ntz,
    "hMy" number, "hProperty" number, "sCode" varchar, "dSqFt" number, "sStatus" varchar
);
copy into raw.yardi_replicate.property from @raw.landing.mini_dominium_stage/yardi_replicate/ pattern = '.*property[.]csv.*';
copy into raw.yardi_replicate.property__ct from @raw.landing.mini_dominium_stage/yardi_replicate/ pattern = '.*property__ct[.]csv.*';
copy into raw.yardi_replicate.unit from @raw.landing.mini_dominium_stage/yardi_replicate/ pattern = '.*unit[.]csv.*';
copy into raw.yardi_replicate.unit__ct from @raw.landing.mini_dominium_stage/yardi_replicate/ pattern = '.*unit__ct[.]csv.*';

-- 7. PDB (Access property database)
create or replace table raw.propertydata.tblpdb_property (
    txtid varchar, txtpropid varchar, yardihmy varchar, txtpropname varchar, txtstatus varchar, txtmarket varchar,
    ingested_at timestamp_ntz
);
create or replace table raw.propertydata.tblpdb_valueevents (
    txtid varchar, event_date date, event_type varchar, value_usd number(18, 2), forced_sale varchar,
    ingested_at timestamp_ntz
);
copy into raw.propertydata.tblpdb_property from @raw.landing.mini_dominium_stage/propertydata/ pattern = '.*tblpdb_property[.]csv.*';
copy into raw.propertydata.tblpdb_valueevents from @raw.landing.mini_dominium_stage/propertydata/ pattern = '.*tblpdb_valueevents[.]csv.*';

-- 8. WORKFRONT (kunlik to'liq snapshotlar)
create or replace table raw.workfront.prgm (
    id varchar, name varchar, status varchar, plannedcompletiondate varchar, updates varchar,
    "ingestionTimeStamp" varchar
);
copy into raw.workfront.prgm from @raw.landing.mini_dominium_stage/workfront/ pattern = '.*program_snapshots[.]csv.*';

-- 9. NONPROFORMA (deal NPV va milestone sanalari)
create or replace table raw.nonproforma.deal_proforma_npv (
    workfront_program_id varchar, deal_name varchar, proforma_type varchar, file_name varchar,
    file_last_modified timestamp_ntz, npv_usd number(18, 2), is_tax_credit varchar
);
create or replace table raw.nonproforma.deal_milestones (
    workfront_program_id varchar, deal_name varchar,
    ic_approval_date date, signed_pa_date date, bonds_entitlements_date date, closing_date date,
    construction_completion_date date, perm_financing_date date, final_equity_date date,
    ingested_at timestamp_ntz
);
copy into raw.nonproforma.deal_proforma_npv from @raw.landing.mini_dominium_stage/nonproforma/ pattern = '.*deal_proforma_npv[.]csv.*';
copy into raw.nonproforma.deal_milestones from @raw.landing.mini_dominium_stage/nonproforma/ pattern = '.*deal_milestones[.]csv.*';

-- 10. METADATA (25-kunda ingestion notebooki shu jadvallarga log yozadi)
create table if not exists raw.metadata.ingestion_logs (
    "sourceID" varchar, "runID" varchar, "fileName" varchar, "blobPath" varchar, "rowCount" number,
    "extractionTimeStamp" varchar, "ingestionTimeStamp" varchar, "status" varchar,
    "errorMessage" varchar, "extractedBy" varchar, "ingestedBy" varchar
);
create table if not exists raw.metadata.runs (
    "runID" varchar, "sourceID" varchar, "runStartTime" varchar, "runEndTime" varchar, "status" varchar,
    "totalFiles" number, "successfulFiles" number, "failedFiles" number, "initiatedBy" varchar, "comments" varchar
);

-- 11. Tekshiruv: natijalar solutions/answers.md dagi sonlar bilan mos kelishi kerak
select 'procore.projects' as t, count(*) as n from raw.procore.projects                       -- 159
union all select 'procore.change_events', count(*) from raw.procore.change_events             -- 584
union all select 'procore.custom_fields', count(*) from raw.procore.change_event_custom_fields -- 1162
union all select 'yardi.property', count(*) from raw.yardi_replicate.property                 -- 6
union all select 'yardi.property__ct', count(*) from raw.yardi_replicate.property__ct         -- 8
union all select 'yardi.unit', count(*) from raw.yardi_replicate.unit                         -- 48
union all select 'yardi.unit__ct', count(*) from raw.yardi_replicate.unit__ct                 -- 36
union all select 'pdb.property', count(*) from raw.propertydata.tblpdb_property               -- 33
union all select 'pdb.valueevents', count(*) from raw.propertydata.tblpdb_valueevents         -- 17
union all select 'workfront.prgm', count(*) from raw.workfront.prgm                           -- 80
union all select 'nonproforma.npv', count(*) from raw.nonproforma.deal_proforma_npv          -- 26
union all select 'nonproforma.milestones', count(*) from raw.nonproforma.deal_milestones;     -- 14

-- 12. Kredit himoyasi (ACCOUNTADMIN kerak): oyiga 100 kreditdan oshsa warehouse'larni to'xtatadi
-- use role accountadmin;
-- create or replace resource monitor learning_monitor with credit_quota = 100
--     triggers on 75 percent do notify on 100 percent do suspend;
-- alter warehouse ingesting_wh set resource_monitor = learning_monitor;
-- alter warehouse transforming_wh set resource_monitor = learning_monitor;
-- alter warehouse adhoc_analytics_wh set resource_monitor = learning_monitor;
