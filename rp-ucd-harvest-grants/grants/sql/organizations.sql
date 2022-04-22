SET SQLFORMAT CSV
SET FEEDBACK OFF

select
  campus_cd as "campus_cd"
, home_dept_cd as "home_dept_cd"
, home_dept_nm as "home_dept_nm"
, home_dept_abrv_nm as "home_dept_abrv_nm"
, home_dept_addr as "home_dept_addr"
, division_cd as "division_cd"
FROM FINANCE.uc_home_dept_t
WHERE active_ind = 'Y'
ORDER BY campus_cd,home_dept_cd;

DISCONNECT
QUIT
