SET SQLFORMAT CSV
SET FEEDBACK OFF

with
award_pis as (
select distinct
    cast(pi.cgprpsl_nbr as integer) as cgprpsl_nbr
    , pi.PERSON_UNVL_ID
    , person.PRNCPL_NM AS prncpl_nm
    , person.PERSON_NM AS person_nm
    , person.email_addr as person_email
    , CASE pi.CGAWD_PRMPRJDR_IND
        WHEN 'Y' THEN 'PI'
        ELSE 'KP' END as grant_role
FROM FINANCE.CG_AWD_PRJDR_T pi
JOIN FINANCE.RICE_UC_KRIM_PERSON_MV person
    ON person.PRNCPL_ID = pi.PERSON_UNVL_ID
WHERE
    pi.ROW_ACTV_IND='Y'
),
award_fund as (
  select distinct awd.CGPRPSL_NBR,awdext.UC_LOC_CD,awdext.UC_FUND_NBR
  FROM FINANCE.CG_AWD_T awd
  JOIN FINANCE.UC_CG_AWD_EXT_T awdext
     ON awdext.CGPRPSL_NBR = awd.CGPRPSL_NBR
),
account_pis as (
select distinct
 cast(award_fund.CGPRPSL_NBR as integer) as cgprpsl_nbr,
 account.account_nbr,
 account.uc_fund_nbr,
 account.cg_pi_prncpl_id,
 account.acct_assoc_prncpl_id,
 person.prncpl_nm as prncpl_nm,
 person.person_nm as person_nm,
 person.email_addr as person_email,
 'ACCT-COPI' as grant_role,
 acct_person.prncpl_nm as acct_nm
from award_fund
join FINANCE.UC_CA_ACCOUNT_EXT_T account
  ON award_fund.UC_FUND_NBR=account.UC_FUND_NBR
JOIN FINANCE.RICE_UC_KRIM_PERSON_MV person
    ON person.PRNCPL_ID = account.cg_pi_prncpl_id
JOIN FINANCE.RICE_UC_KRIM_PERSON_MV acct_person
    ON acct_person.PRNCPL_ID = account.acct_assoc_prncpl_id
),
effort_roles as (
select distinct
cast(awd.cgprpsl_nbr as integer) as cgprpsl_nbr,
person.prncpl_nm as prncpl_nm,
person.person_nm as person_nm,
person.email_addr as person_email,
CASE ec.EMPLOYEE_ROLE_ID WHEN 'PI' THEN 'COPI'
ELSE ec.EMPLOYEE_ROLE_ID END as grant_role
from award_fund awd
JOIN FINANCE.CS_EFFORT_COMMITTMENT ec
    ON ec.OP_LOC_CODE = awd.UC_LOC_CD
    AND ec.OP_FUND_NUM = awd.UC_FUND_NBR
JOIN FINANCE.RICE_UC_KRIM_PERSON_MV person
    ON person.PPS_ID = ec.EMPLOYEE_ID
),
combined_roles as (
select distinct /* csv */
  COALESCE(award_pis.cgprpsl_nbr,effort_roles.cgprpsl_nbr,account_pis.cgprpsl_nbr) as "cgprpsl_nbr",
  COALESCE(award_pis.prncpl_nm,effort_roles.prncpl_nm,account_pis.prncpl_nm) as "prncpl_nm",
 COALESCE(award_pis.person_nm,effort_roles.person_nm,account_pis.person_nm) as "person_nm",
 COALESCE(award_pis.person_email,effort_roles.person_email,account_pis.person_email) as "person_email",
 CASE award_pis.grant_role WHEN 'PI' THEN 'PI'
    ELSE COALESCE(effort_roles.grant_role,account_pis.grant_role,award_pis.grant_role) END as "grant_role"
  from award_pis
  FULL OUTER JOIN account_pis
  ON award_pis.cgprpsl_nbr=account_pis.cgprpsl_nbr
  AND award_pis.prncpl_nm=account_pis.prncpl_nm
  FULL OUTER JOIN effort_roles
  ON award_pis.cgprpsl_nbr=effort_roles.cgprpsl_nbr
  AND award_pis.prncpl_nm=effort_roles.prncpl_nm
)
/*
-- This combines them
-- select "cgprpsl_nbr","prncpl_nm",listagg("grant_role",'; ') as "roles"
-- from combined_roles order by "cgprpsl_nbr","prncpl_nm"
-- fetch first 5 rows only;
*/
select *
from combined_roles
order by "cgprpsl_nbr","prncpl_nm","grant_role"
;

DISCONNECT
QUIT
