-- Retrieves the exceptions
-- Suitable for Firebird 3.0 and higher

select
  trim(trailing from EXCEPTION_NAME) as EXCEPTION_NAME,
  MESSAGE,
  COMMENTS
from (
  select
    RDB$EXCEPTION_NAME as EXCEPTION_NAME,
    trim(trailing from RDB$MESSAGE) as MESSAGE,
    RDB$DESCRIPTION as COMMENTS
  from RDB$EXCEPTIONS
) exceptions
