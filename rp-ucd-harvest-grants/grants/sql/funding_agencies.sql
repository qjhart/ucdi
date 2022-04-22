SET FEEDBACK OFF
SET SQLFORMAT CSV

with
wanted_awards as (
select distinct awd.CGPRPSL_NBR
FROM FINANCE.CG_AWD_T awd
JOIN FINANCE.CG_AWD_PRJDR_T pi
    ON pi.CGPRPSL_NBR = awd.CGPRPSL_NBR
    AND pi.CGAWD_PRMPRJDR_IND = 'Y'
    AND pi.ROW_ACTV_IND = 'Y'
JOIN FINANCE.CG_AWD_ORG_T aorg
    ON aorg.CGPRPSL_NBR = awd.CGPRPSL_NBR
    AND aorg.ROW_ACTV_IND = 'Y'
    AND aorg.CGAWD_PRM_ORG_IND = 'Y'
JOIN FINANCE.UC_CG_AWD_ORG_EXT_T aorgext
    ON aorgext.CGPRPSL_NBR = aorg.CGPRPSL_NBR
    AND aorgext.FIN_COA_CD = aorg.FIN_COA_CD
    AND aorgext.ORG_CD = aorg.ORG_CD
),
f as (
 select distinct cg_agency_nbr
 from finance.award join wanted_awards using (CGPRPSL_NBR)
   union
 select distinct awd.cg_fedpt_agncy_nbr as cg_agency_nbr
 from finance.award awd join wanted_awards using (CGPRPSL_NBR)
)
select /* csv */
cg_agency_nbr,cg_agency_full_nm as agency
from f join cg_agency_t
using (cg_agency_nbr)
ORDER BY cg_agency_nbr;

DISCONNECT
QUIT
