-- Retrieve views for database
-- Suitable for Firebird 2.5 and higher

select 
  trim(trailing from TABLE_NAME) as VIEW_NAME,
  VIEW_SOURCE, -- only contains the <query> (including WITH CHECK OPTION if present) after the CREATE VIEW .... AS <query>
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
    RDB$VIEW_SOURCE VIEW_SOURCE
    RDB$DESCRIPTION as COMMENTS
  from RDB$RELATIONS
) RELATIONS
where TABLE_TYPE = 'VIEW'
