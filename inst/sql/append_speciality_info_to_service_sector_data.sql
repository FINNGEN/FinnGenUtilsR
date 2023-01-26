#
#
# @service_sector_data_table :
# full path to the table in service_sector format >v2
#
# @fg_codes_info_table :
# full path to the table with the codes info
#
# @new_colums_sufix :
# string indicating a prefix to add to the appended columns, default="".


WITH service_sector_fg_codes_preprocessed AS(
  SELECT *,
    CASE
      WHEN SOURCE IN ('INPAT','OUTPAT','OPER_IN', 'OPER_OUT') THEN CODE6
      ELSE NULL
    END AS FG_CODE6
     FROM @service_sector_data_table
  )

# join longitudinal table with pre formated
SELECT
  ssfgpre.*,
  fgc.concept_class_id AS speciality_concept_class_id@new_colums_sufix,
  fgc.name_en AS speciality_name_en@new_colums_sufix,
  fgc.name_fi AS speciality_name_fi@new_colums_sufix,
  fgc.code AS speciality_code@new_colums_sufix,
  fgc.omop_concept_id AS speciality_omop_concept_id@new_colums_sufix
FROM service_sector_fg_codes_preprocessed AS ssfgpre
LEFT JOIN ( SELECT * FROM @fg_codes_info_table WHERE vocabulary_id = "MEDSPECfi")  as fgc
ON ssfgpre.FG_CODE6 IS NOT DISTINCT FROM fgc.FG_CODE6
