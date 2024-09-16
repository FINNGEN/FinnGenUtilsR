--
--
-- data_table :
-- full path to the table with the data to append the concept info
--
-- omop_schema :
-- schema where the omop tables are stored
--
-- new_colums_sufix :
-- string indicating a prefix to add to the appended columns, default="".
--

-- join data_table table with omop_schema concept table to append concept info
SELECT
  dt.*,
  c.concept_name AS omop_concept_name@new_colums_sufix
FROM @data_table AS dt
LEFT JOIN @omop_schema.concept AS c
ON dt.omop_concept_id = c.concept_id

