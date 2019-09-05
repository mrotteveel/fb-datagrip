-- Select sequences
-- Suitable for Firebird 3.0 and higher

select
  trim(trailing from SEQUENCE_NAME) as SEQUENCE_NAME,
  COMMENTS
from (
  select
    RDB$GENERATOR_NAME as SEQUENCE_NAME,
    RDB$DESCRIPTION as COMMENTS
  from RDB$GENERATORS
  where coalesce(RDB$SYSTEM_FLAG, 0) = 0
) sequences
