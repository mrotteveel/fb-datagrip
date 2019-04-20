-- Retrieves the roles
-- Suitable for Firebird 2.5 and higher (likely also works for earlier versions)

select
  trim(trailing from ROLE_NAME) as ROLE_NAME,
  COMMENTS
from (
  select
    RDB$ROLE_NAME as ROLE_NAME,
    RDB$DESCRIPTION as COMMENTS
  from RDB$ROLES
) roles