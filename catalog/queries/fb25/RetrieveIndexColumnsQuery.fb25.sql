-- Retrieves the columns of an index
-- Not applicable to expression indexes
-- Suitable for Firebird 2.5 and higher (likely also works for earlier versions)

select
  trim(trailing from INDEX_NAME) as INDEX_NAME,
  trim(trailing from COLUMN_NAME) as COLUMN_NAME,
  COLUMN_POSITION
from (
  select
    RDB$INDEX_NAME as INDEX_NAME,
    RDB$FIELD_NAME as COLUMN_NAME,
    RDB$FIELD_POSITION + 1 as COLUMN_POSITION
  from RDB$INDEX_SEGMENTS
) indexcolumns
