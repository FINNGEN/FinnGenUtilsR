--
--
-- omop_schema:
-- schema where the omop tables are stored
--
-- fg_codes_info_table :
-- full path to the table with the codes info
--
-- gap_days :
-- INTEGER capturing gap days between drug exposure, default=30.


WITH drug_era AS (
SELECT ROW_NUMBER() OVER (ORDER BY ctefinal.person_id) AS drug_era_id,
       ctefinal.person_id,
       ctefinal.drug_concept_id AS drug_concept_id,
       MIN(ctefinal.drug_exposure_start_date) AS drug_era_start_date,
       ctefinal.era_end_date AS drug_era_end_date,
       COUNT(*) AS drug_exposure_count,
       DATE_DIFF(ctefinal.era_end_date, MIN(ctefinal.drug_exposure_start_date),DAY) as era_period
FROM (
  SELECT d.person_id,
       d.drug_concept_id,
       d.drug_type_concept_id,
       d.drug_exposure_start_date,
       MIN(ctend.end_date) AS era_end_date
  FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY de.person_id) AS row_num,
           de.person_id AS person_id,
           de.drug_type_concept_id AS drug_type_concept_id,
           de.drug_exposure_start_date AS drug_exposure_start_date,
           COALESCE(de.drug_exposure_end_date, DATE_ADD(de.drug_exposure_start_date, INTERVAL de.days_supply DAY), de.drug_exposure_start_date) AS drug_exposure_end_date,
           de.drug_source_concept_id AS drug_concept_id
    FROM @schema_omop.drug_exposure AS de
    WHERE de.drug_source_concept_id != 0
  ) AS d
  INNER JOIN (
    WITH temp AS (
      SELECT rawdata.person_id,
             rawdata.drug_concept_id,
             rawdata.event_date, rawdata.event_type,
             rawdata.start_ordinal,
             MAX(start_ordinal) OVER (PARTITION BY rawdata.person_id, rawdata.drug_concept_id
            ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal_new,
         -- this pulls the current START down from the prior rows so that the NULLs
         -- from the END DATES will contain a value we can compare with
         ROW_NUMBER() OVER (PARTITION BY rawdata.person_id, rawdata.drug_concept_id
                ORDER BY event_date, event_type) AS overall_ord
            -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
        FROM (
           SELECT person_id, drug_concept_id,
                  drug_exposure_start_date AS event_date,
                  -1 AS event_type,
                  ROW_NUMBER() OVER (PARTITION BY person_id, drug_concept_id ORDER BY drug_exposure_start_date) AS start_ordinal
            FROM (
              SELECT ROW_NUMBER() OVER (ORDER BY de.person_id) AS row_num,
                     de.person_id AS person_id,
                     de.drug_type_concept_id AS drug_type_concept_id,
                     de.drug_exposure_start_date AS drug_exposure_start_date,
                     COALESCE(de.drug_exposure_end_date, DATE_ADD(de.drug_exposure_start_date, INTERVAL de.days_supply DAY), de.drug_exposure_start_date) AS drug_exposure_end_date,
                     de.drug_source_concept_id AS drug_concept_id
              FROM @schema_omop.drug_exposure AS de
              WHERE de.drug_source_concept_id != 0
            )
            UNION ALL
            SELECT person_id,
       drug_concept_id,
       DATE_ADD(drug_exposure_end_date, INTERVAL @gap_days DAY) AS event_date, 1 AS event_type, NULL
            FROM (
              SELECT ROW_NUMBER() OVER (ORDER BY de.person_id) AS row_num,
                     de.person_id AS person_id,
                     de.drug_type_concept_id AS drug_type_concept_id,
                     de.drug_exposure_start_date AS drug_exposure_start_date,
                     COALESCE(de.drug_exposure_end_date, DATE_ADD(de.drug_exposure_start_date, INTERVAL de.days_supply DAY), de.drug_exposure_start_date) AS drug_exposure_end_date,
                     de.drug_source_concept_id AS drug_concept_id
              FROM @schema_omop.drug_exposure AS de
              WHERE de.drug_source_concept_id != 0
            )
            ORDER BY person_id, drug_concept_id, event_date
        ) AS rawdata
        ORDER BY rawdata.person_id, rawdata.drug_concept_id, rawdata.event_date
    )
    SELECT *, DATE_ADD(event_date, INTERVAL -@gap_days DAY) AS end_date
    FROM temp
    WHERE (2 * start_ordinal_new) - overall_ord = 0
    ORDER BY drug_concept_id, event_date
  ) AS ctend
  ON d.person_id = ctend.person_id AND
     d.drug_concept_id = ctend.drug_concept_id AND
     ctend.end_date >= d.drug_exposure_start_date
  GROUP BY d.row_num,
           d.person_id,
           d.drug_concept_id,
           d.drug_type_concept_id,
           d.drug_exposure_start_date
  ) AS ctefinal
  GROUP BY ctefinal.person_id,
           ctefinal.drug_concept_id,
           ctefinal.drug_type_concept_id,
           ctefinal.era_end_date
  ORDER BY ctefinal.person_id, ctefinal.drug_concept_id
)
SELECT t.drug_era_id,
       p.person_source_value AS FINNGENID,
       vnrs.concept_code AS VNR,
       t.drug_era_start_date, t.drug_era_end_date,
       t.drug_exposure_count, t.era_period,
       vnrs.concept_name AS MedicineName, vnrs.ATC
FROM drug_era AS t
LEFT JOIN (
  SELECT c.concept_id, c.concept_code, c.concept_name, fv.ATC
  FROM @schema_omop.concept AS c
  LEFT JOIN @fg_codes_info_table AS fv
  ON LPAD(SAFE_CAST(fv.VNR AS STRING),6,'0') = c.concept_code
) AS vnrs
ON vnrs.concept_id = t.drug_concept_id
LEFT JOIN @schema_omop.person AS p
ON p.person_id = t.person_id
ORDER BY drug_era_id;
