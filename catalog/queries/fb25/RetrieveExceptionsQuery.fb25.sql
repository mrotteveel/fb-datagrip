-- Retrieves the exceptions
-- Suitable for Firebird 2.5 and higher (likely also works for earlier versions)

select
  trim(trailing from EXCEPTION_NAME) as EXCEPTION_NAME,
  MESSAGE,
  COMMENTS
from (
  select
    RDB$EXCEPTION_NAME as EXCEPTION_NAME,
    RDB$MESSAGE as MESSAGE,
    RDB$DESCRIPTION as COMMENTS
  from RDB$EXCEPTIONS
) exceptions