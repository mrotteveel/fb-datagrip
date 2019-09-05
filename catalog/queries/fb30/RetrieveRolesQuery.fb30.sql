-- Retrieves the roles
-- Suitable for Firebird 3.0 and higher

select
  trim(trailing from ROLE_NAME) as ROLE_NAME,
  COMMENTS
from (
  select
    RDB$ROLE_NAME as ROLE_NAME,
    RDB$DESCRIPTION as COMMENTS
  from RDB$ROLES
) roles
