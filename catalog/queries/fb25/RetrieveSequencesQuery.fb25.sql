-- Select sequences
-- Suitable for Firebird 2.5 and higher (likely also earlier versions)

select
  trim(trailing from SEQUENCE_NAME) as SEQUENCE_NAME,
  COMMENTS
from (
  select
    RDB$GENERATOR_NAME as SEQUENCE_NAME,
    RDB$DESCRIPTION as COMMENTS
  from RDB$GENERATORS
  where RDB$SYSTEM_FLAG = 0
) sequences