SET FEEDBACK OFF
--SET SQLFORMAT JSON-FORMATTED
SET SQLFORMAT CSV

with awards as (
SELECT
    cast(awd.cgprpsl_nbr as integer) AS "cgprpsl_nbr"
    , COALESCE(per.PRNCPL_NM, c.PRNCPL_NM) AS "prncpl_nm"
    , COALESCE(per.PERSON_NM, c.PRSN_NM) AS "person_nm"
    , awd.CGAWD_PROJ_TTL AS "title"
    , ROUND(awd.CGAWD_TOT_AMT,0) "grant_amount"
    , ROUND(awd.CGAWD_DRCT_CST_AMT,0) "direct_costs"
    , ROUND(awd.CGAWD_INDR_CST_AMT,0) "indirect_costs"
    , awd.CG_AGENCY_NBR AS "agency_nbr"
    , awd.CG_FEDPT_AGNCY_NBR AS "fpt_agency_nbr"
    , aorgext.DEPT_ADMIN_PRNCPL_ID as "dept_admin_id"
    , CASE WHEN awd.CGAWD_PURPOSE_CD = 'A' THEN 'INSTRUCTION'
        WHEN awd.CGAWD_PURPOSE_CD = 'C' THEN 'RESEARCH'
        WHEN awd.CGAWD_PURPOSE_CD = 'F' THEN 'SERVICE/OTHER'
        WHEN awd.CGAWD_PURPOSE_CD = 'G' THEN 'ACADEMIC SUPPORT'
        WHEN awd.CGAWD_PURPOSE_CD = 'H' THEN 'STUDENT SERVICES'
        WHEN awd.CGAWD_PURPOSE_CD = 'S' THEN 'SCHOLARSHIPS / FELLOWSHIPS'
        WHEN awd.CGAWD_PURPOSE_CD = 'X' THEN 'DEFAULT'
    END AS "grant_type"
    , REGEXP_REPLACE(awd.CG_AGENCY_AWD_NBR, '[ \t\r\n\f]+','-') "grantor_award_id"
    , TO_CHAR(awd.CGAWD_BEG_DT, 'YYYY-MM-DD') AS "start_date"
    , TO_CHAR(awd.CGAWD_END_DT, 'YYYY-MM-DD') AS "end_date"
    , aorg.FIN_COA_CD as "fin_coa_cd"
    , per.prmry_dept_cd as "pi_dept_cd"
    , adm.prmry_dept_cd as "admin_dept_cd"
FROM FINANCE.CG_AWD_T awd
JOIN FINANCE.CG_AWD_PRJDR_T pi
    ON pi.CGPRPSL_NBR = awd.CGPRPSL_NBR
    AND pi.CGAWD_PRMPRJDR_IND = 'Y'
    AND pi.ROW_ACTV_IND = 'Y'
    AND awd.CGAWD_PURPOSE_CD != 'S'
JOIN FINANCE.CG_AWD_ORG_T aorg
    ON aorg.CGPRPSL_NBR = awd.CGPRPSL_NBR
    AND aorg.ROW_ACTV_IND = 'Y'
    AND aorg.CGAWD_PRM_ORG_IND = 'Y'
JOIN FINANCE.UC_CG_AWD_ORG_EXT_T aorgext
    ON aorgext.CGPRPSL_NBR = aorg.CGPRPSL_NBR
    AND aorgext.FIN_COA_CD = aorg.FIN_COA_CD
    AND aorgext.ORG_CD = aorg.ORG_CD
LEFT OUTER JOIN FINANCE.RICE_UC_KRIM_PERSON_MV per
    ON per.PRNCPL_ID = pi.PERSON_UNVL_ID
LEFT OUTER JOIN FINANCE.RICE_KRIM_ENTITY_CACHE_T c
    ON c.PRNCPL_ID = pi.PERSON_UNVL_ID
LEFT OUTER JOIN FINANCE.RICE_UC_KRIM_PERSON_MV adm
    ON adm.PRNCPL_ID = aorgext.DEPT_ADMIN_PRNCPL_ID
)
/*
-- We are excluding scholarship awards
*/
select /* csv */
awd.*,
HD.HOME_DEPT_NM as "pi_dept_nm",
AD.HOME_DEPT_NM as "admin_dept_nm"
from awards awd
LEFT OUTER JOIN FINANCE.UC_HOME_DEPT_T HD
 ON awd."pi_dept_cd"=HD.HOME_DEPT_CD
LEFT OUTER JOIN FINANCE.UC_HOME_DEPT_T AD
 ON awd."admin_dept_cd"=AD.HOME_DEPT_CD
ORDER BY "cgprpsl_nbr";

DISCONNECT
QUIT
