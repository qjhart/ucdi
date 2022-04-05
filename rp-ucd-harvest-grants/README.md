# Grants

This directory makes grants and associated data needed for the Aggie Experts
Private Grants Feed.

``` bash
make clean grants.json.gz
```

The clean removes intermediate csv files then will fetch the table, using
eg. `grants.sql` and then convert to ttl using eg. `grants.rq`

The following data is created for grants:
- grants.ttl = All the awards for the UC
- funding_agencies = Short Description of the funding agency giving grant
- fin_coa.ttl = Description of the various Chart of Accounts for UCD
- contributors.ttl = Additional (Non-PI) roles for the grants.

These are combined into a single graph.json files with the
`<http://experts.ucdavis.edu/fis/>` graph name.

## Contributors

Currently, it's difficult to get all the grant contributors.  The finance
information does not include all roles in the submitted grant.  Instead, we have
a number of tables that have some information.

- each grant has multiple entries in the FINANCE.CG_AWD_PRJDR_T table. Only one
  is marked as CGAWD_PRMPRJDR_IND = 'Y'.  This is used as the overall PI.  When
  they are marked as = 'N', then we assume they have some non-PI role (KP).

- each grant is awarded a UC_FUND_NBR via the UC_CG_AWD_EXT_T table.
  UC_FUND_NBRs are used in the effort reporting table to identify who works on
  federal funded projects.  We use this table to identify roles for these
  federal awards.

- Each fund can have multiple accounts, in the UC_CA_ACCOUNT_EXT_T table.  For
  each account, we can find the account principal in the `CG_PI_PRNCPL_ID`.  If
  they are different than the PI, we can assume these individuals also had a
  role in the award.

We combine these as follows:  The person identified with `CGAWD_PRMPRJDR_IND
='Y'` is the only person that will be listed as a PI.  For any other person
listed in the above tables, they will be assigned as follows:
- If they have any ERS roles, they will be assigned those; however PI's will be
  changed to COPIs. PDIRs will remain, so a project could have a PI and a PDIR,
  as different people
- If they manage an account, they will be added with a `GrantAccountManager`
  type
- If they are only listed in the `CG_AWD_PRJDR_T` table with 'CGAWD_PRMPRJDR_IND
  = 'N'', they'll b assigned as Key Personnel 'KP'

  Using these roles, we have the following number of roles per type,

  ``` text
experts:schema#GrantAccountManagerRole 18413
experts:schema#GrantCoPrincipalInvestigatorRole 7035
experts:schema#GrantCoreLeaderRole 96
experts:schema#GrantKeyPersonnelRole 892
experts:schema#GrantOtherRole 2153
experts:schema#GrantPrincipalInvestigatorRole 39537
experts:schema#GrantProgramDirectorRole 158
experts:schema#GrantProjectLeaderRole 214
vivo:AdminRole 30271
vivo:CoPrincipalInvestigatorRole 7035
vivo:Grant 43726
vivo:LeaderRole 372
vivo:PrincipalInvestigatorRole 39537
vivo:ResearcherRole 21561
    ```


# Changes

## 2022-03-14

### Removal of pi_role in grant

``` sparql
# This is now in the contributors section
  ?grant vivo:relates ?pi_role.
	?pi_role a vivo:PrincipalInvestigatorRole, ucdrp:GrantPrincipalInvestigatorRole;
		        vivo:relatedBy ?grant;
	        obo:RO_000052 ?person;
         ucdrp:role_person_name ?person_nm;
         rdfs:label ?person_nm;
       .

  ?person vivo:relatedBy ?grant;
	        obo:RO_000053 ?pi_role;
         ucdrp:casId ?prncpl_nm;
         .

# Then in the where clause
BIND(URI(CONCAT(str(experts:), "pi_role/", md5(?prncpl_nm), "-", ?cgprpsl_nbr)) as ?pi_role)
```

# Documentation

The [FISDS Documentation](https://fisds.ucdavis.edu/ds/tools/tabledoc/toc.cfm)
gives good detail on the tables and columns.  The [direct
access](https://servicehub.ucdavis.edu/servicehub?id=ucd_kb_article&sysparm_article=KB0002497)
page also gives some helpful overview.

## Connection Information

We have found the best method of connecting to these data are with the full
connection string, as in:

``` bash
 ~/sqlcl/bin/sql  'agexpert_app/${password}@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(COMMUNITY=TCP.ucdavis.edu)(PROTOCOL=TCP)(Host=fis-dss.ucdavis.edu)(Port=1521)))(CONNECT_DATA=(SID=dsprod)(GLOBAL_NAME=fis_ds_prod.ucdavis.edu)))'
```

This is managed in the Makefile, where you can test with `make interactive`.
The connection information is stored in a secrets file, that holds the exact
connection information.


## Detailed Grant Info
### PI Name

The original query used a coalesce of two tables to choose the PI to be used.
These are  FINANCE.RICE_UC_KRIM_PERSON_MV per, and
FINANCE.RICE_KRIM_ENTITY_CACHE_T, but both of these require that the
CG_AWD_PRJDR_T table be joined to the award.

the query below shows that yes, we do need this setup.

``` sql
with
wanted_award_person as (
select distinct awd.CGPRPSL_NBR,pi.PERSON_UNVL_ID as PRNCPL_ID
FROM FINANCE.AWARD awd
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
WHERE awd.FISCAL_YEAR=2022
AND awd.FISCAL_PERIOD='01'
),
pi as (
select /* csv */
wa.PRNCPL_ID,per.PRNCPL_NM,c.PRNCPL_NM,
case when (wa.PRNCPL_ID = per.PRNCPL_ID) then 'T' else 'F' end  as person,
case when (wa.PRNCPL_ID = c.PRNCPL_ID) then 'T' else 'F' end as entity,
case when (per.PRNCPL_NM = c.PRNCPL_NM) then 'T' else 'F' end as equal
from wanted_award_person wa
LEFT OUTER JOIN FINANCE.RICE_UC_KRIM_PERSON_MV per
    ON per.PRNCPL_ID = wa.PRNCPL_ID
LEFT OUTER JOIN FINANCE.RICE_KRIM_ENTITY_CACHE_T c
    ON c.PRNCPL_ID = wa.PRNCPL_ID
    )
select person,entity,equal,count(*) as count
from pi group by person,entity,equal
order by count desc;

   PERSON    ENTITY    EQUAL    COUNT
_________ _________ ________ ________
T         T         T           37269
F         T         F            1473
T         F         F             467
F         F         F             122
T         T         F               2

```

In fact, there are a few bad examples in there.

``` sql
with
wanted_award_person as (
select distinct awd.CGPRPSL_NBR,pi.PERSON_UNVL_ID as PRNCPL_ID
FROM FINANCE.AWARD awd
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
WHERE awd.FISCAL_YEAR=2022
AND awd.FISCAL_PERIOD='01'
),
pi as (
select /* csv */
wa.PRNCPL_ID,per.PRNCPL_NM,c.PRNCPL_NM,
case when (wa.PRNCPL_ID = per.PRNCPL_ID) then 'T' else 'F' end  as person,
case when (wa.PRNCPL_ID = c.PRNCPL_ID) then 'T' else 'F' end as entity,
case when (per.PRNCPL_NM = c.PRNCPL_NM) then 'T' else 'F' end as equal
from wanted_award_person wa
LEFT OUTER JOIN FINANCE.RICE_UC_KRIM_PERSON_MV per
    ON per.PRNCPL_ID = wa.PRNCPL_ID
LEFT OUTER JOIN FINANCE.RICE_KRIM_ENTITY_CACHE_T c
    ON c.PRNCPL_ID = wa.PRNCPL_ID
    )
select *
from pi
where person='T' and entity='T' and equal='F';

   PRNCPL_ID    PERSON_NM      ENTITY_NM    PERSON    ENTITY    EQUAL
____________ ____________ ______________ _________ _________ ________
1080528      msmeza       nasim.fazel    T         T         F
95381        maxine       X#133200       T         T         F

```

So that looks like we want to use PERSONS first and ENTITY_CACHE second


# Other Finance Queries

Here are some other examples we have run

## Sub Fund Group Type

Vessela was interested in what the sub_fund_grp_cd terms meant.  These
definitions are found in the `ca_sub_fund_grp_t` table.  The `/*csv*/` is a
shortcut for
[SQLFORMAT](https://oracle-base.com/articles/misc/sqlcl-format-query-results-with-the-set-sqlformat-command) commands.

``` sql
spool sub_fund_grp_t.csv
select /*csv*/ *
from ca_sub_fund_grp_t
order by sub_fund_grp_cd;
spool off
```

# Old Query Information

Previously, we were looking at the award table, where we needed to update the
data based on the fiscal time period.  We have switched to looking at the
overall awd_t table, which only carries the current award information.

The Most of the info here is no longer required.

### Do grants change?

A new entry is made in the award table for every fiscal period.  Since we only
want one of these, we dra
In order to understand the data, we need to understand the fiscal_periods, so we
can use the proper one.  There is a table that converts the fiscal_period to month

``` sql
 select * from month_conversion;
```

But we can also get the fiscal periods with this command

``` bash
FISCAL_PERIOD=`date --date='now() +6 months' +%m`
FISCAL_YEAR=`date --date='now() +6 months' +%Y`
```

### Grant fiscal closures

From a fiscal point of view, awards can change during their lifetime.  For
example, here we can see grants that have changed the most in that last five years.

``` sql
with awards as (
    select awd.FISCAL_YEAR as year,awd.cgprpsl_nbr as nbr,awd.CGAWD_TOT_AMT as tot,
    TO_CHAR(awd.CGAWD_BEG_DT, 'YYYY-MM-DD') AS startd,
    TO_CHAR(awd.CGAWD_END_DT, 'YYYY-MM-DD') AS endd
    from FINANCE.AWARD awd
    WHERE awd.FISCAL_YEAR in ( 2018,2019,2020,2021,2022 )
    and awd.FISCAL_PERIOD = '03'
  ),
  diff as (
   select distinct nbr,tot,endd
   from awards
  ),
  count as ( select nbr,count(*) as cnt
  from diff
  group by nbr
  )
select * from count order by cnt desc fetch first 5 rows only;

```

From that we can see how individual accounts have changed over the fiscal
period.


``` sql
with awards as (
select awd.FISCAL_YEAR,awd.cgprpsl_nbr,awd.CGAWD_TOT_AMT as total,
TO_CHAR(awd.CGAWD_BEG_DT, 'YYYY-MM-DD') AS "start_date",
TO_CHAR(awd.CGAWD_END_DT, 'YYYY-MM-DD') AS "end_date"
from FINANCE.AWARD awd
WHERE
awd.FISCAL_PERIOD = '03'
)
select * from awards where
cgprpsl_nbr in (117054,116469) and FISCAL_YEAR>=2018
order by cgprpsl_nbr,fiscal_year;

```

``` text
  FISCAL_YEAR    CGPRPSL_NBR     TOTAL    start_date      end_date
______________ ______________ _________ _____________ _____________
          2015         109136           2013-08-01    2014-07-31
          2016         109136           2013-08-01    2015-07-31
          2017         109136           2013-08-01    2017-07-31
          2018         109136           2013-08-01    2018-07-31
          2019         109136    350000 2013-08-01    2018-07-31
          2020         109136    420000 2013-08-01    2020-07-31
          2021         109136    420000 2013-08-01    2021-07-31
          2022         109136    420000 2013-08-01    2021-12-31

```


### Additional tables

The complete query from FIS shows that we have a number of natural joins to the
data, guard items also exist  These reduce the number of grants
that we show, but actually as well increase the end_date, the data fills out
more and more (eg 2000->2005)

``` sql
with f as (
 select awd.cgprpsl_nbr as cgprpsl_nbr
,case when (awd.CGPRPSL_NBR=kfs.CGPRPSL_NBR) then 'T' else 'F' end as kfs
,case when (awd.CGPRPSL_NBR=pi.CGPRPSL_NBR) then 'T' else 'F' end as pi
,case when (awd.CGPRPSL_NBR=org.CGPRPSL_NBR) then 'T' else 'F' end as org
,pi.CGAWD_PRMPRJDR_IND as pi_pr
,pi.ROW_ACTV_IND as pi_ac
,org.ROW_ACTV_IND as org_ac
,org.CGAWD_PRM_ORG_IND as org_pr
from finance.award awd
left join FINANCE.CG_AWD_PRJDR_T pi on awd.cgprpsl_nbr= pi.CGPRPSL_NBR
left join FINANCE.CG_AWD_ORG_T org on awd.cgprpsl_nbr= org.CGPRPSL_NBR
left join FINANCE.CG_AWD_T kfs on awd.cgprpsl_nbr=kfs.cgprpsl_nbr
where FISCAL_YEAR=2022 and FISCAL_PERIOD='01'
and  TO_CHAR(awd.CGAWD_END_DT, 'YYYY') > 1970
and TO_CHAR(awd.CGAWD_END_DT, 'YYYY') <= 2000
)
select kfs,pi,org,pi_pr,pi_ac,org_pr,org_ac,count(*)
from f
group by kfs,pi,org,pi_pr,pi_ac,org_pr,org_ac
order by count(*) desc;

   KFS    PI    ORG    PI_PR    PI_AC    ORG_PR    ORG_AC    COUNT(*)
______ _____ ______ ________ ________ _________ _________ ___________
T      F     F                                                   1975
T      T     T      Y        Y        Y         Y                 447
T      T     T      Y        N        Y         N                  13
T      T     T      N        Y        Y         Y                  11
T      T     F      Y        Y                                      8
T      T     T      Y        Y        N         N                   7
T      T     T      N        N        Y         Y                   5
T      T     T      Y        Y        Y         N                   3
T      T     T      N        N        N         Y                   3
T      T     T      Y        Y        N         Y                   3
T      T     T      Y        N        Y         Y                   3
T      T     T      N        N        Y         N                   2
T      T     T      N        N        N         N                   1
T      T     F      N        Y                                      1

```

``` sql
with f as (
  2   select awd.cgprpsl_nbr as cgprpsl_nbr
  3  ,case when (awd.CGPRPSL_NBR=kfs.CGPRPSL_NBR) then 'T' else 'F' end as kfs
  4  ,case when (awd.CGPRPSL_NBR=pi.CGPRPSL_NBR) then 'T' else 'F' end as pi
  5  ,case when (awd.CGPRPSL_NBR=org.CGPRPSL_NBR) then 'T' else 'F' end as org
  6  ,pi.CGAWD_PRMPRJDR_IND as pi_pr
  7  ,pi.ROW_ACTV_IND as pi_ac
  8  ,org.ROW_ACTV_IND as org_ac
  9  ,org.CGAWD_PRM_ORG_IND as org_pr
 10  from finance.award awd
 11  left join FINANCE.CG_AWD_PRJDR_T pi on awd.cgprpsl_nbr= pi.CGPRPSL_NBR
 12  left join FINANCE.CG_AWD_ORG_T org on awd.cgprpsl_nbr= org.CGPRPSL_NBR
 13  left join FINANCE.CG_AWD_T kfs on awd.cgprpsl_nbr=kfs.cgprpsl_nbr
 14  where FISCAL_YEAR=2022 and FISCAL_PERIOD='01'
 15  )
 16  select kfs,pi,org,pi_pr,pi_ac,org_pr,org_ac,count(*)
 17  from f
 18  group by kfs,pi,org,pi_pr,pi_ac,org_pr,org_ac
 19* order by count(*) desc;

   KFS    PI    ORG    PI_PR    PI_AC    ORG_PR    ORG_AC    COUNT(*)
______ _____ ______ ________ ________ _________ _________ ___________
T      T     T      Y        Y        Y         Y               39300
T      F     F                                                   3047
T      T     T      N        Y        Y         Y                1415
T      T     T      N        N        Y         Y                 806
T      T     F      Y        Y                                    560
T      T     T      Y        Y        N         N                 433
T      T     T      Y        Y        N         Y                 164
T      T     T      N        N        N         N                  95
T      T     F      N        Y                                     79
T      T     T      N        Y        N         Y                  57
T      T     T      Y        N        Y         Y                  44
T      T     T      N        N        N         Y                  35
T      T     T      Y        N        Y         N                  26
T      T     T      N        Y        N         N                  23
T      T     T      Y        Y        Y         N                  16
T      T     T      Y        N        N         Y                   3
T      T     T      N        N        Y         N                   2
T      T     T      Y        N        N         N                   2

```




### Original Complete Query

This query was given to us as a starter query for comparison

``` sql
SELECT
    awd.CGPRPSL_NBR AS "localAwardId"--Kuali Financials Award primary key
    , awd.CGAWD_PROJ_TTL AS "Award Title"
    , awd.CG_AGENCY_NBR AS "Agency Nbr"
    , awd.CG_AGENCY_FULL_NM AS "Agency"
    , awd.FPT_AGENCY_FULL_NM AS "Federal Pass Thru Agency Name"
    , awd.CGAWD_BEG_DT AS "Start Date"
    , awd.CGAWD_END_DT AS "End Date"
    , COALESCE(awd.CG_AGENCY_AWD_NBR,awd.ROOT_AWARD_NBR) AS "sponsorAwardId"
    , awd.CGAWD_TOT_AMT AS "totalAwardAmount"
    , awd.CGAWD_DRCT_CST_AMT AS "grantDirectCosts" --this is slightly suspicious as it matches total award amount; direct costs should come from General Ledger
    , awd.SUB_FUND_GRP_CD --SubFund Group Code
    , sfg.SUB_FUND_GRP_DESC -- Subfund group desc
    , awd.CG_CFDA_NBR --CFDA number
    , kfsawd.INSTRMNT_TYP_CD
    , itt.INSTRMNT_TYP_DESC
    , pi.PERSON_UNVL_ID AS "PI Principal ID"
    , awdext.FUND_MANAGER_PRNCPL_ID AS "Fund Manager ID"
    , COALESCE(per.PRNCPL_NM, c.PRNCPL_NM) AS PRNCPL_NM ---- Principal Investigator kereberos
    , COALESCE(per.ENTITY_ID, c.ENTITY_ID) AS "Entity ID"
    , COALESCE(per.PERSON_NM,c.PRSN_NM) AS "PI Name"
    , per.EMAIL_ADDR AS "PI Email" -- Principal Investigator Email
    , aorg.FIN_COA_CD --Award Org Chart
    , aorg.ORG_CD -- Award Org Name
    , oh.ORG_NAME -- Award Org Name
    , oh.ORG_HIERARCHY_LEVEL --Award Org level
    , oh.CHART_NUM_LEVEL_4 --School/College Chart
    , oh.ORG_ID_LEVEL_4 -- School/College Org Code
    , oh.ORG_NAME_LEVEL_4 -- School/College Org Name
    , aorgext.DEPT_ADMIN_PRNCPL_ID --Department Admin ID
    , COALESCE(per1.PERSON_NM,c1.PRSN_NM) AS "Department Admin Name"
    , awd.DS_LAST_UPDATE_DATE AS awd_lst_updt_dt --Award record last update date
    , awd.UC_AWD_TYP_CD
    , ec.EMPLOYEE_ID
    , per2.PERSON_NM AS "Effort Committment Name"
    , ec.EMPLOYEE_ROLE_ID
    , ec.STATUS_CODE
FROM FINANCE.AWARD awd
JOIN FINANCE.CG_AWD_T kfsawd
    ON kfsawd.CGPRPSL_NBR = awd.CGPRPSL_NBR
JOIN FINANCE.UC_CG_AWD_EXT_T awdext
    ON awdext.CGPRPSL_NBR = kfsawd.CGPRPSL_NBR
JOIN FINANCE.CG_INSTRMNT_TYP_T itt
    ON itt.INSTRMNT_TYP_CD = kfsawd.INSTRMNT_TYP_CD
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
JOIN FINANCE.ORGANIZATION_HIERARCHY oh
    ON oh.CHART_NUM = aorg.FIN_COA_CD
    AND oh.ORG_ID = aorg.ORG_CD
    AND oh.FISCAL_YEAR = awd.FISCAL_YEAR
    AND oh.FISCAL_PERIOD = awd.FISCAL_PERIOD
JOIN FINANCE.CA_SUB_FUND_GRP_T sfg
    ON sfg.SUB_FUND_GRP_CD = awd.SUB_FUND_GRP_CD
LEFT OUTER JOIN FINANCE.RICE_UC_KRIM_PERSON_MV per
    ON per.PRNCPL_ID = pi.PERSON_UNVL_ID
LEFT OUTER JOIN FINANCE.RICE_KRIM_ENTITY_CACHE_T c
    ON c.PRNCPL_ID = pi.PERSON_UNVL_ID
LEFT OUTER JOIN FINANCE.RICE_UC_KRIM_PERSON_MV per1
    ON per1.PRNCPL_ID = aorgext.DEPT_ADMIN_PRNCPL_ID
LEFT OUTER JOIN FINANCE.RICE_KRIM_ENTITY_CACHE_T c1
    ON c1.PRNCPL_ID = aorgext.DEPT_ADMIN_PRNCPL_ID
LEFT OUTER JOIN FINANCE.CS_EFFORT_COMMITTMENT ec
    ON ec.OP_LOC_CODE = awdext.UC_LOC_CD
    AND ec.OP_FUND_NUM = awdext.UC_FUND_NBR
LEFT OUTER JOIN FINANCE.RICE_UC_KRIM_PERSON_MV per2
    ON per2.PPS_ID = ec.EMPLOYEE_ID
WHERE awd.FISCAL_YEAR = 2021
    AND awd.FISCAL_PERIOD = '11'
```
