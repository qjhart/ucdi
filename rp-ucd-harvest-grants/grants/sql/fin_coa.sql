SET SQLFORMAT CSV
SET FEEDBACK OFF

select
  fin_coa_cd as "fin_coa_cd"
, ver_nbr
, fin_coa_desc as "fin_coa_desc"
FROM FINANCE.ca_chart_t
WHERE fin_coa_active_cd = 'Y'
ORDER BY fin_coa_cd;

DISCONNECT
QUIT
