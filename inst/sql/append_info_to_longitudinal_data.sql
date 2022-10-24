DECLARE ICD10fi_map_to, PURCH_map_to, CANC_map_to, REIMB_map_to  STRING;
DECLARE ICD10fi_precision, ICD9fi_precision, ICD8fi_precision, ATC_precision, NOMESCOfi_precision INT64;
#
# ICD10 registry has four values to choose from with default value
# 1. CODE1_CODE2 - default option that takes values from CODE1 and CODE2 if present and are not equal
# 2. CODE1 - Takes only CODE1 value
# 3. CODE2 - Takes only CODE2 value such that CODE2 != CODE1
# 4. ATC - Takes only CODE3 values such that CODE3 != CODE1
SET ICD10fi_map_to = '@ICD10fi_map_to';
#
# CANC registry has four values to choose from with default value
# 1. MORPO_BEH_TOPO - default where all three codes CODE1, CODE2 and CODE3 will be present
# 2. TOPO - Takes only CODE1 and ignores CODE2 and CODE3
# 3. MORPHO - Takes only CODE2 and ingores CODE1 and CODE3
# 4. BEH - Takes only CODE3 and ingores CODE1 and CODE2
SET CANC_map_to = '@CANC_map_to';
#
# REIMB registry has two values to choose from with a default value
# 1. REIMB - default where only CODE1 is considered which is just ATC code
# 2. ICD - Takes the CODE2 column which is an ICD code of version 10, 9 and 8
SET REIMB_map_to =  '@REIMB_map_to';
#
# PURCH registry has two values to choose from with default value
# 1. ATC - default vocabulary selected using the value in CODE1
# 2. VNR - Takes only CODE3
SET PURCH_map_to = '@PURCH_map_to';
#
SET ICD10fi_precision = @ICD10fi_precision;
SET ICD9fi_precision = @ICD9fi_precision;
SET ICD8fi_precision = @ICD8fi_precision;
SET ATC_precision = @ATC_precision;
SET NOMESCOfi_precision = @NOMESCOfi_precision;
#
WITH service_sector_fg_codes AS (
            SELECT *,
		           CASE
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NULL THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL and CODE3 IS NULL THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NULL AND CODE2 IS NOT NULL and CODE3 IS NULL THEN CODE2
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL and CODE1 != CODE2 and CODE3 IS NULL THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL and CODE1 = CODE2 and CODE3 IS NULL THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NOT NULL and CODE1 = CODE3 THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NOT NULL and CODE1 != CODE3 THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1' AND CODE1 IS NOT NULL THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE2' AND CODE2 IS NOT NULL THEN CODE2
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'ATC' AND CODE3 IS NOT NULL AND CODE1 IS NOT NULL AND CODE1 != CODE3 THEN CODE3
 			                  WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NULL THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NULL AND CODE2 IS NOT NULL and CODE3 IS NULL THEN CODE2
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 != CODE2 THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 = CODE2 THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '8' AND CODE1 IS NOT NULL AND CODE2 IS NULL AND CODE3 IS NULL THEN REGEXP_REPLACE(CODE1,r'\+|\*|\#|\&','')
                        WHEN SOURCE = 'CANC' AND CANC_map_to = 'MORPO_BEH_TOPO' AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE = 'CANC' AND CANC_map_to = 'TOPO' AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE = 'CANC' AND CANC_map_to = 'MORPHO' AND  CODE2 IS NOT NULL THEN CODE2
                        WHEN SOURCE = 'CANC' AND CANC_map_to = 'BEH' AND CODE3 IS NOT NULL THEN CODE3
                        WHEN SOURCE = 'PURCH' AND PURCH_map_to = 'ATC' AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE = 'PURCH' AND PURCH_map_to = 'VNR' AND CODE3 IS NOT NULL THEN CODE3
                        WHEN SOURCE = 'REIMB' AND REIMB_map_to = 'REIMB' THEN CODE1
                        WHEN SOURCE = 'REIMB' AND REIMB_map_to = 'ICD' AND CODE2 IS NOT NULL AND REGEXP_CONTAINS(CODE2,r'^[:alpha:]') THEN CODE2
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL THEN CODE1
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 = CODE2 THEN CODE1
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NULL AND CODE2 IS NOT NULL THEN CODE2
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1' AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE2' AND CODE2 IS NOT NULL THEN CODE2
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'ATC' AND CODE3 IS NOT NULL AND CODE1 IS NOT NULL AND CODE1 != CODE3 THEN CODE3
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICP') AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^OP') AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^MOP') AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^NOM') AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^MFHL') AND CODE1 IS NOT NULL THEN CODE1
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^SFHL') AND CODE1 IS NOT NULL THEN CODE1
                   END AS FG_CODE1,
                   CASE
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NULL AND CODE2 IS NOT NULL and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL and CODE1 != CODE2 and CODE3 IS NULL THEN CODE2
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL and CODE1 = CODE2 and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NOT NULL and CODE1 = CODE3 THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NOT NULL and CODE1 != CODE3 THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1' AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE2' AND CODE2 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'ATC' AND CODE3 IS NOT NULL AND CODE1 IS NOT NULL AND CODE1 != CODE3 THEN NULL
			            WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NULL AND CODE2 IS NOT NULL and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 != CODE2 THEN CODE2
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 = CODE2 THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '8' AND CODE1 IS NOT NULL AND CODE2 IS NULL AND CODE3 IS NULL THEN NULL
                        WHEN SOURCE = 'CANC' AND CANC_map_to = 'MORPO_BEH_TOPO' AND CODE2 IS NOT NULL THEN CODE2
                        WHEN SOURCE = 'PURCH' THEN NULL
                        WHEN SOURCE = 'REIMB' THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 != CODE2 THEN CODE2
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 = CODE2 THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NULL AND CODE2 IS NOT NULL THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1' AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE2' AND CODE2 IS NOT NULL THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'ATC' AND CODE3 IS NOT NULL AND CODE1 IS NOT NULL AND CODE1 != CODE3 THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICP') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^OP') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^MOP') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^NOM') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^MFHL') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^SFHL') AND CODE1 IS NOT NULL THEN NULL
                   END AS FG_CODE2,
                   CASE
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NULL AND CODE2 IS NOT NULL and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL and CODE1 != CODE2 and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL and CODE1 = CODE2 and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1_CODE2' AND CODE1 IS NOT NULL AND CODE2 IS NULL and CODE3 IS NOT NULL and CODE1 != CODE3 THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE1' AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'CODE2' AND CODE2 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'ATC' AND CODE3 IS NOT NULL AND CODE1 IS NOT NULL AND CODE1 != CODE3 THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NULL AND CODE2 IS NOT NULL and CODE3 IS NULL THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 != CODE2 THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' AND CODE1 IS NOT NULL AND CODE2 IS NOT NULL AND CODE1 = CODE2 THEN NULL
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '8' AND CODE1 IS NOT NULL AND CODE2 IS NULL AND CODE3 IS NULL THEN NULL
                        WHEN SOURCE = 'CANC' AND CANC_map_to = 'MORPO_BEH_TOPO' AND CODE3 IS NOT NULL THEN CODE3
                        WHEN SOURCE = 'PURCH' THEN NULL
                        WHEN SOURCE = 'REIMB' THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1_CODE2' THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE1' THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'CODE2' THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'ATC' AND CODE3 IS NOT NULL AND CODE1 IS NOT NULL AND CODE1 != CODE3 THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICP') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^OP') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^MOP') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^NOM') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^MFHL') AND CODE1 IS NOT NULL THEN NULL
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^SFHL') AND CODE1 IS NOT NULL THEN NULL
                   END AS FG_CODE3,
                   CASE
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to IN ('CODE1_CODE2','CODE1','CODE2') THEN 'ICD10fi'
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '10' AND ICD10fi_map_to = 'ATC' THEN 'ATC'
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to IN ('CODE1_CODE2','CODE1','CODE2') THEN 'ICD10fi'
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICD') AND ICD10fi_map_to = 'ATC' THEN 'ATC'
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '9' THEN 'ICD9fi'
                        WHEN SOURCE IN ('INPAT','OUTPAT','DEATH') AND ICDVER = '8' THEN 'ICD8fi'
                        WHEN SOURCE = 'CANC' THEN 'ICDO3'
                        WHEN SOURCE = 'PURCH' AND PURCH_map_to = 'ATC' AND CODE1 IS NOT NULL THEN 'ATC'
                        WHEN SOURCE = 'PURCH' AND PURCH_map_to = 'VNR' AND  CODE3 IS NOT NULL THEN 'VNRfi'
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^ICP') THEN 'ICPC'
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^OP') THEN 'SPAT'
                        WHEN SOURCE = 'PRIM_OUT' AND REGEXP_CONTAINS(CATEGORY, r'^MOP') THEN 'NOMESCOfi'
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^NOM') THEN 'NOMESCOfi'
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^MFHL') THEN 'FHL'
                        WHEN SOURCE IN ('OPER_IN','OPER_OUT') AND REGEXP_CONTAINS(CATEGORY, r'^SFHL') THEN 'FHL'
                        WHEN SOURCE = 'REIMB' AND REIMB_map_to = 'REIMB' THEN 'REIMB'
                        WHEN SOURCE = 'REIMB' AND REIMB_map_to = 'ICD' AND ICDVER = '10' THEN 'ICD10fi'
                        WHEN SOURCE = 'REIMB' AND REIMB_map_to = 'ICD' AND ICDVER = '9' THEN 'ICD9fi'
                        WHEN SOURCE = 'REIMB' AND REIMB_map_to = 'ICD' AND ICDVER = '8' THEN 'ICD8fi'
                   END AS vocabulary_id
            FROM @longitudinal_data_table
            ),
            service_sector_fg_codes_precision AS(
               SELECT FINNGENID, SOURCE,
                      EVENT_AGE, APPROX_EVENT_DAY,
                      CODE1, CODE2, CODE3, CODE4,
                      #CODE5, CODE6, CODE7,
                      ICDVER, CATEGORY, INDEX,
                      vocabulary_id,
                      CASE
                           WHEN vocabulary_id="ICD10fi" THEN SUBSTRING(FG_CODE1,1,ICD10fi_precision)
                           WHEN vocabulary_id="ICD9fi" THEN SUBSTRING(FG_CODE1,1,ICD9fi_precision)
                           WHEN vocabulary_id="ICD8fi" THEN SUBSTRING(FG_CODE1,1,ICD8fi_precision)
                           WHEN vocabulary_id="ATC" THEN SUBSTRING(FG_CODE1,1,ATC_precision)
                           WHEN vocabulary_id="NOMESCOfi" THEN SUBSTRING(FG_CODE1,1,NOMESCOfi_precision)
                           #WHEN vocabulary_id="ICDO3" AND FALSE THEN NULL
                           WHEN FG_CODE1 IS NULL THEN NULL
                           ELSE FG_CODE1
                      END AS FG_CODE1,
                      CASE
                           #WHEN vocabulary_id="ICD10fi" AND FALSE THEN NULL
                           #WHEN vocabulary_id="ICDO3" AND TRUE THEN NULL
                           WHEN vocabulary_id="ICD10fi" THEN SUBSTRING(FG_CODE2,1,ICD10fi_precision)
                           WHEN FG_CODE2 IS NULL THEN NULL
                           ELSE FG_CODE2
                      END AS FG_CODE2,
                      #FG_CODE3
                      CASE
                           #WHEN vocabulary_id="ICDO3" AND TRUE THEN NULL
                           WHEN FG_CODE3 IS NULL THEN NULL
                           ELSE FG_CODE3
                      END AS FG_CODE3
               FROM service_sector_fg_codes
            )
            SELECT ssfgcp.*, fgc.concept_class_id, fgc.name_en, fgc.name_fi
            FROM service_sector_fg_codes_precision AS ssfgcp
            LEFT JOIN @fg_codes_info_table as fgc
            ON ssfgcp.vocabulary_id = fgc.vocabulary_id AND
               ssfgcp.FG_CODE1 IS NOT DISTINCT FROM fgc.FG_CODE1 AND
               ssfgcp.FG_CODE2 IS NOT DISTINCT FROM fgc.FG_CODE2 AND
               ssfgcp.FG_CODE3 IS NOT DISTINCT FROM fgc.FG_CODE3
            #WHERE SOURCE IN ('CANC','REIMB')
            #LIMIT 10
