-- Query to retrieve stored procedures
-- Suitable for Firebird 3.0 and higher

-- TODO Include input and output count?

select
  trim(trailing from PACKAGE_NAME) as PACKAGE_NAME,
  trim(trailing from PROCEDURE_NAME) as PROCEDURE_NAME,
  PROCEDURE_TYPE,
  PROCEDURE_KIND,
  /* UDR, and PSQL functions in packages have no source;
   * contains <body> in CREATE PROCEDURE ... AS <body> */
  PROCEDURE_SOURCE,
  COMMENTS
from (
  select
    RDB$PACKAGE_NAME as PACKAGE_NAME,
    RDB$PROCEDURE_NAME as PROCEDURE_NAME,
    case RDB$PROCEDURE_TYPE
      when 1 then 'SELECTABLE'
      when 2 then 'EXECUTABLE'
      else 'LEGACY' -- predates introduction of RDB$PROCEDURE_TYPE; could be either
    end as PROCEDURE_TYPE,
    case 
      when RDB$ENGINE_NAME is not null then 'UDR'
      else 'PSQL'
    end as PROCEDURE_KIND,
    RDB$PROCEDURE_SOURCE as PROCEDURE_SOURCE,
    RDB$DESCRIPTION as COMMENTS
  from RDB$PROCEDURES
  where coalesce(RDB$PRIVATE_FLAG, 0) = 0
) procedures
order by PACKAGE_NAME, PROCEDURE_NAME
