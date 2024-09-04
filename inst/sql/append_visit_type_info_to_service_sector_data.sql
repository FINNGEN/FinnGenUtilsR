--
--
-- service_sector_data_table :
-- full path to the table in service_sector format >v2
--
-- fg_codes_info_table :
-- full path to the table with the codes info
--
-- vocab_omop_concept_relationship :
-- full path to the vocabulary omop concep_relationship table for a datafreeze release
--
-- vocab_omop_concept :
-- full path to the vocabulary omop concep table for a datafreeze release
--
-- prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector
-- Some hilmo visits are including both coding systems, SRC|ServiceSector and SRC|Contact|Urgency, if TRUE the second is used
--
-- new_colums_sufix :
-- string indicating a prefix to add to the appended columns, default="".


WITH visit_type_fg_codes_preprocessed AS(
  SELECT *,
    CASE
      WHEN SOURCE IN ('PRIM_OUT') THEN CODE5
      WHEN SOURCE IN ('INPAT','OUTPAT','OPER_IN', 'OPER_OUT', 'PRIM_OUT') AND
           ( ( CODE5 IS NOT NULL AND CODE8 IS NULL AND CODE9 IS NULL ) OR
             ( CODE5 IS NOT NULL AND (CODE8 IS NOT NULL OR CODE9 IS NOT NULL) ) AND NOT @prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector )
            THEN CODE5
      ELSE NULL
    END AS FG_CODE5,
    CASE
      WHEN SOURCE IN ('PRIM_OUT') THEN CODE6
      ELSE NULL
    END AS FG_CODE6,
     CASE
      WHEN SOURCE IN ('INPAT','OUTPAT','OPER_IN', 'OPER_OUT')  AND
           ( ( (CODE8 IS NOT NULL OR CODE9 IS NOT NULL) AND CODE5 IS NULL ) OR
             ( (CODE8 IS NOT NULL OR CODE9 IS NOT NULL) AND CODE5 IS NOT NULL ) AND @prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector )
            THEN CODE8
      ELSE NULL
    END AS FG_CODE8,
    CASE
      WHEN SOURCE IN ('INPAT','OUTPAT','OPER_IN', 'OPER_OUT') AND
           ( ( (CODE8 IS NOT NULL OR CODE9 IS NOT NULL) AND CODE5 IS NULL ) OR
             ( (CODE8 IS NOT NULL OR CODE9 IS NOT NULL) AND CODE5 IS NOT NULL ) AND @prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector )
            THEN CODE9
      ELSE NULL
    END AS FG_CODE9,
    CASE
      WHEN CODE4 IS NOT NULL AND SAFE_CAST(CODE4 AS INT64) >= 1 THEN DATE_ADD(APPROX_EVENT_DAY, INTERVAL CAST(CODE4 AS INT64) DAY)
      ELSE APPROX_EVENT_DAY
    END AS approx_end_day
    FROM @service_sector_data_table
),
-- join longitudinal table with pre formated
visits_from_registers_with_source_visit_type_id AS (
  SELECT
    ssfgpre.*,
    fgc.omop_concept_id AS visit_type_omop_concept_id
  FROM visit_type_fg_codes_preprocessed AS ssfgpre
  LEFT JOIN @fg_codes_info_table as fgc
  ON ssfgpre.SOURCE IS NOT DISTINCT FROM fgc.SOURCE AND
     ssfgpre.FG_CODE5 IS NOT DISTINCT FROM fgc.FG_CODE5 AND
     ssfgpre.FG_CODE6 IS NOT DISTINCT FROM fgc.FG_CODE6 AND
     ssfgpre.FG_CODE8 IS NOT DISTINCT FROM fgc.FG_CODE8 AND
     ssfgpre.FG_CODE9 IS NOT DISTINCT FROM fgc.FG_CODE9
--WHERE SOURCE IN ('CANC','REIMB')
--LIMIT 10
),
-- Change the formated codes for which visit_type_omop_concept_id iS NULL
-- The idea is to capture all visits even when service sector codes were not mapped to standard visit concepts.
-- The visit will be mapped using SOURCE instead of service sector codes
visits_from_registers_with_source_and_standard_visit_type_id AS (
  SELECT DISTINCT
         vfrwsvti.FINNGENID,
         vfrwsvti.SOURCE,
         vfrwsvti.EVENT_AGE,
         vfrwsvti.APPROX_EVENT_DAY,
         vfrwsvti.approx_end_day,
         vfrwsvti.CODE1, vfrwsvti.CODE2, vfrwsvti.CODE3, vfrwsvti.CODE4,
         vfrwsvti.CODE5, vfrwsvti.CODE6, vfrwsvti.CODE8, vfrwsvti.CODE9,
         vfrwsvti.ICDVER, vfrwsvti.CATEGORY,
         vfrwsvti.INDEX,
         CASE
              WHEN ssmap.concept_id_2 IS NULL AND vfrwsvti.SOURCE IN ('INPAT','OUTPAT','OPER_IN','OPER_OUT','PRIM_OUT')  THEN NULL
              ELSE vfrwsvti.FG_CODE5
         END AS FG_CODE5,
         CASE
              WHEN ssmap.concept_id_2 IS NULL AND vfrwsvti.SOURCE = 'PRIM_OUT' THEN NULL
              ELSE vfrwsvti.FG_CODE6
         END AS FG_CODE6,
         CASE
              WHEN ssmap.concept_id_2 IS NULL AND vfrwsvti.SOURCE IN ('INPAT','OUTPAT','OPER_IN','OPER_OUT') THEN NULL
              ELSE vfrwsvti.FG_CODE8
         END AS FG_CODE8,
         CASE
              WHEN ssmap.concept_id_2 IS NULL AND vfrwsvti.SOURCE IN ('INPAT','OUTPAT','OPER_IN','OPER_OUT') THEN NULL
              ELSE vfrwsvti.FG_CODE9
         END AS FG_CODE9
  FROM visits_from_registers_with_source_visit_type_id AS vfrwsvti
  LEFT JOIN (
    SELECT cr.concept_id_1, cr.concept_id_2, c.concept_name
    FROM @vocab_omop_concept_relationship AS cr
    JOIN @vocab_omop_concept AS c
    ON cr.concept_id_2 = c.concept_id
    WHERE cr.relationship_id = 'Maps to' AND c.domain_id IN ('Visit','Metadata')
  ) AS ssmap
  ON
    CAST(vfrwsvti.visit_type_omop_concept_id AS INT64) = ssmap.concept_id_1
),
-- Add the non-standard code
-- Add the new column suffix
visits_from_registers_with_source_and_standard_visit_type_null_id AS (
  SELECT
  vfrwssti.FINNGENID,
  vfrwssti.SOURCE,
  vfrwssti.EVENT_AGE,
  vfrwssti.APPROX_EVENT_DAY,
  vfrwssti.approx_end_day,
  vfrwssti.CODE1, vfrwssti.CODE2, vfrwssti.CODE3, vfrwssti.CODE4,
  vfrwssti.CODE5, vfrwssti.CODE6, vfrwssti.CODE7, vfrwssti.CODE8, vfrwssti.CODE9,
  vfrwssti.ICDVER, vfrwssti.CATEGORY,
  vfrwssti.INDEX,
  vfrwssti.FG_CODE5, vfrwssti.FG_CODE6, vfrwssti.FG_CODE7, vfrwssti.FG_CODE8, vfrwssti.FG_CODE9,
  fgc.concept_class_id AS visit_type_concept_class_id@new_colums_sufix,
  fgc.name_en AS visit_type_name_en@new_colums_sufix,
  fgc.name_fi AS visit_type_name_fi@new_colums_sufix,
  fgc.code AS visit_type_code@new_colums_sufix,
  fgc.omop_concept_id AS visit_type_omop_concept_id@new_colums_sufix
  FROM visits_from_registers_with_source_and_standard_visit_type_id AS vfrwssti
  LEFT JOIN ( SELECT SOURCE,
                     FG_CODE5,
                     FG_CODE6,
                     FG_CODE8,
                     FG_CODE9,
                     code,
                     concept_class_id,
                     name_en,
                     name_fi,
                     omop_concept_id
              FROM @fg_codes_info_table
              WHERE vocabulary_id = 'FGVisitType') AS fgc
  ON vfrwssti.SOURCE IS NOT DISTINCT FROM fgc.SOURCE AND
     vfrwssti.FG_CODE5 IS NOT DISTINCT FROM fgc.FG_CODE5 AND
     vfrwssti.FG_CODE6 IS NOT DISTINCT FROM fgc.FG_CODE6 AND
     vfrwssti.FG_CODE8 IS NOT DISTINCT FROM fgc.FG_CODE8 AND
     vfrwssti.FG_CODE9 IS NOT DISTINCT FROM fgc.FG_CODE9
)
-- Check if the standard visit concept_is falls in Inpatient visit, Emergency Room Visit, Emergency Room and Inpatient Visit and
-- Outpatient Visit. All these visits involve a physician.
-- Within these visits there are repeat visits which is not interesting as they are follow-up visit.
SELECT vfrwssvtni.*EXCEPT(approx_end_day),
       CASE
            WHEN ssmap.concept_id_2 IN (9201, 8717, 8892, 8971, 581384, 38004285, 38004274, 32760,
                                        9203, 8870, 581381,
                                        262,
                                        9202, 38004207, 581479, 38004693, 8964, 8949, 38004453, 8966, 8716, 38004702, 38004677, 8858, 8905, 8584, 581477,
                                        581380, 8756, 8977, 38004696, 32261, 8761, 8941, 8960, 8782, 38003620
                                       ) AND
                NOT CONTAINS_SUBSTR(vfrwssvtni.visit_type_name_en, 'repeat visit') THEN 'Diagnostic visit'
            ELSE 'Non-diagnostic visit'
       END AS diagnostic_relevance
FROM visits_from_registers_with_source_and_standard_visit_type_null_id AS vfrwssvtni
LEFT JOIN (
  SELECT cr.concept_id_1, cr.concept_id_2, c.concept_name
  FROM @vocab_omop_concept_relationship AS cr
  JOIN @vocab_omop_concept AS c
  ON cr.concept_id_2 = c.concept_id
  WHERE cr.relationship_id = 'Maps to' AND c.domain_id IN ('Visit','Metadata')
) AS ssmap
ON CAST(vfrwssvtni.visit_type_omop_concept_id AS INT64) = ssmap.concept_id_1
-- remove hilmo inpat visits that are inpatient with ndays=1 or ourtpatient with ndays>1
WHERE NOT (
            (vfrwssvtni.SOURCE IN ('INPAT','OPER_IN') AND
             vfrwssvtni.APPROX_EVENT_DAY = vfrwssvtni.approx_end_day AND
             REGEXP_CONTAINS(ssmap.concept_name,r'^(Inpatient|Rehabilitation|Other|Substance|Emergency Room and Inpatient Visit)'))
            OR
            (vfrwssvtni.SOURCE IN ('INPAT','OPER_IN') AND
             vfrwssvtni.APPROX_EVENT_DAY < vfrwssvtni.approx_end_day AND
             REGEXP_CONTAINS(ssmap.concept_name,r'^(Outpatient|Ambulatory|Home|Emergency Room Visit|Case Management Visit)'))
          )
