-- Retrieve tables for database
-- Suitable for Firebird 3.0 and higher
-- NOTE: It might be simpler to just use `DatabaseMetaData.getTables`

select 
  trim(trailing from TABLE_NAME) as TABLE_NAME, 
  TABLE_TYPE, 
  COMMENTS
from (
  select 
    RDB$RELATION_NAME as TABLE_NAME,
    case
        when RDB$RELATION_TYPE = 0 or RDB$RELATION_TYPE is null and RDB$VIEW_BLR is null 
        then case 
            when RDB$SYSTEM_FLAG = 1 
            then 'SYSTEM TABLE' 
            else 'TABLE' 
        end
        when RDB$RELATION_TYPE = 1 or RDB$RELATION_TYPE is null and RDB$VIEW_BLR is not null 
        then 'VIEW'
        when RDB$RELATION_TYPE = 2 
        then 'TABLE' -- external table
        when RDB$RELATION_TYPE = 3 
        then 'SYSTEM TABLE'
        when RDB$RELATION_TYPE in (4, 5) 
        then 'GLOBAL TEMPORARY'
        else 'TABLE' -- assume default, should not occur though
    end as TABLE_TYPE,
    RDB$DESCRIPTION as COMMENTS
  from RDB$RELATIONS
) relations
where TABLE_TYPE <> 'VIEW'
