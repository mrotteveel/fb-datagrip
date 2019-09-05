-- Select indices for table
-- Suitable for Firebird 3.0 and higher

select 
  trim(trailing from INDEX_NAME) as INDEX_NAME,
  trim(trailing from TABLE_NAME) as TABLE_NAME,
  IS_UNIQUE,
  DIRECTION, -- ASCENDING or DESCENDING
  IS_EXPRESSION_INDEX, -- an expression index has no columns
  EXPRESSION_SOURCE, -- contains '(<expression>)' part of COMPUTED BY (<expression)
  IS_ACTIVE,
  COMMENTS
from (
  select
    i.RDB$INDEX_NAME as INDEX_NAME,
    i.RDB$RELATION_NAME as TABLE_NAME,
    coalesce(i.RDB$UNIQUE_FLAG, 0) = 1 as IS_UNIQUE,
    case when i.RDB$INDEX_TYPE = 1
      then 'DESCENDING'
      else 'ASCENDING'
    end as DIRECTION,
    i.RDB$SEGMENT_COUNT = 0 as IS_EXPRESSION_INDEX,
    i.RDB$EXPRESSION_SOURCE as EXPRESSION_SOURCE,
    coalesce(i.RDB$INDEX_INACTIVE, 0) = 1 as IS_ACTIVE,
    i.RDB$DESCRIPTION as COMMENTS
  from RDB$INDICES as i
  where not exists(
    -- exclude indices part of primary key, foreign key or unique key
    select 1 
    from RDB$RELATION_CONSTRAINTS rc
    where rc.RDB$RELATION_NAME = i.RDB$RELATION_NAME
    and rc.RDB$INDEX_NAME = i.RDB$INDEX_NAME
  )
) indices
