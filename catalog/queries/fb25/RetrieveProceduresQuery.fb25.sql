-- Query to retrieve stored procedures
-- Suitable for Firebird 2.5 and higher (may work on earlier versions),
-- a separate query for Firebird 3 and higher is advisable

-- TODO Include input and output count?

select
  /* always null in Firebird 2.5 and earlier */
  PACKAGE_NAME,
  trim(trailing from PROCEDURE_NAME) as PROCEDURE_NAME,
  PROCEDURE_TYPE,
  PROCEDURE_KIND,
  /* always null for Firebird 2.5 and earlier */
  ENTRY_POINT,
  /* always null for Firebird 2.5 and earlier */
  ENGINE_NAME
  /* contains <body> in CREATE PROCEDURE ... AS <body> */
  PROCEDURE_SOURCE,
  COMMENTS
from (
  select
    null as PACKAGE_NAME,
    RDB$PROCEDURE_NAME as PROCEDURE_NAME,
    case RDB$PROCEDURE_TYPE
      when 1 then 'SELECTABLE'
      when 2 then 'EXECUTABLE'
      else 'LEGACY' -- predates introduction of RDB$PROCEDURE_TYPE; could be either
    end as PROCEDURE_TYPE,
    'PSQL' as PROCEDURE_KIND,
    null as ENTRY_POINT,
    null as ENGINE_NAME,
    RDB$PROCEDURE_SOURCE as PROCEDURE_SOURCE,
    RDB$DESCRIPTION as COMMENTS
  from RDB$PROCEDURES
) procedures
