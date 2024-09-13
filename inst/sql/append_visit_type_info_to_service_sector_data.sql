--
--
-- service_sector_data_table :
-- full path to the table in service_sector format >v2
--
-- fg_codes_info_table :
-- full path to the table with the codes info
--
-- prioritise_SRC_Contact_Urgency_over_SRC_Service_Sector
-- Some hilmo visits are including both coding systems, SRC|ServiceSector and SRC|Contact|Urgency, if TRUE the second is used
--
-- add_is_follow_up_visit :
-- boolean indicating if a new column should be added to the output table indicating if the visit is a follow up visit
--
-- add_is_clinic_visist :
-- boolean indicating if a new column should be added to the output table indicating if the visit is a clinic visit
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
     FROM @service_sector_data_table
  )

-- join longitudinal table with pre formated
SELECT
  ssfgpre.*,
  fgc.concept_class_id AS visit_type_concept_class_id@new_colums_sufix,
  fgc.name_en AS visit_type_name_en@new_colums_sufix,
  fgc.name_fi AS visit_type_name_fi@new_colums_sufix,
  fgc.code AS visit_type_code@new_colums_sufix,
  fgc.omop_concept_id AS visit_type_omop_concept_id@new_colums_sufix {@add_is_clinic_visist} ? {,
  CASE
    WHEN fgc.extra_info = 'clinic_visit' THEN TRUE
    WHEN fgc.extra_info = 'non_clinic_visit' THEN FALSE
    ELSE NULL
  END AS is_clinic_visit@new_colums_sufix} {@add_is_follow_up_visit} ? {,
  CASE
    WHEN fgc.name_en IS NULL THEN NULL
    WHEN fgc.SOURCE NOT IN ('INPAT', 'OUTPAT', 'OPER_IN', 'OPER_OUT', 'PRIM_OUT') THEN NULL
    WHEN CONTAINS_SUBSTR(fgc.name_en, 'repeat visit') THEN TRUE
    ELSE FALSE
  END AS is_follow_up_visit@new_colums_sufix}
  FROM visit_type_fg_codes_preprocessed AS ssfgpre
LEFT JOIN @fg_codes_info_table as fgc
ON ssfgpre.SOURCE IS NOT DISTINCT FROM fgc.SOURCE AND
   ssfgpre.FG_CODE5 IS NOT DISTINCT FROM fgc.FG_CODE5 AND
   ssfgpre.FG_CODE6 IS NOT DISTINCT FROM fgc.FG_CODE6 AND
   ssfgpre.FG_CODE8 IS NOT DISTINCT FROM fgc.FG_CODE8 AND
   ssfgpre.FG_CODE9 IS NOT DISTINCT FROM fgc.FG_CODE9
--WHERE SOURCE IN ('CANC','REIMB')
--LIMIT 10
