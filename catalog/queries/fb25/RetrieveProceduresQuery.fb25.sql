-- Query to retrieve stored procedures
-- Suitable for Firebird 2.5 and higher (may work on earlier versions),
-- a separate query for Firebird 3 and higher is advisable

-- TODO Consider impact of Firebird 3 packages and UDR
-- TODO Include input and output count?

select
  trim(leading from PROCEDURE_NAME) as PROCEDURE_NAME,
  PROCEDURE_TYPE,
  PROCEDURE_SOURCE, -- contains <body> in CREATE PROCEDURE ... AS <body>
  COMMENTS
from (
  select
    RDB$PROCEDURE_NAME as PROCEDURE_NAME,
    case RDB$PROCEDURE_TYPE
      when 1 then 'SELECTABLE'
      when 2 then 'EXECUTABLE'
      else 'LEGACY' -- predates introduction of RDB$PROCEDURE_TYPE; could be either
    end as PROCEDURE_TYPE,
    RDB$PROCEDURE_SOURCE as PROCEDURE_SOURCE,
    RDB$DESCRIPTION as COMMENTS
  from RDB$PROCEDURES
) procedures
