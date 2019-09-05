-- Retrieve views for database
-- Suitable for Firebird 3.0 and higher

select 
  trim(trailing from TABLE_NAME) as VIEW_NAME,
  VIEW_SOURCE, -- only contains the <query> (including WITH CHECK OPTION if present) after the CREATE VIEW .... AS <query>
  COMMENTS
from (
  select 
    RDB$RELATION_NAME as TABLE_NAME,
    RDB$VIEW_SOURCE VIEW_SOURCE,
    RDB$DESCRIPTION as COMMENTS
  from RDB$RELATIONS
  where RDB$RELATION_TYPE = 1 or RDB$RELATION_TYPE is null and RDB$VIEW_BLR is not null
) relations
