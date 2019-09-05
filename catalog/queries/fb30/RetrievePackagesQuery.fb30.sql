-- Select packages
-- Suitable for Firebird 3.0 and higher

select
  trim(trailing from PACKAGE_NAME) as PACKAGE_NAME,
  /* contains <body> from CREATE PACKAGE ... AS <body> */
  PACKAGE_HEADER_SOURCE,
  /* contains <body> from CREATE PACKAGE BODY ... AS <body> */
  PACKAGE_BODY_SOURCE,
  COMMENTS
from (
  select 
    P.RDB$PACKAGE_NAME as PACKAGE_NAME,
    P.RDB$PACKAGE_HEADER_SOURCE as PACKAGE_HEADER_SOURCE,
    P.RDB$PACKAGE_BODY_SOURCE as PACKAGE_BODY_SOURCE,
    P.RDB$DESCRIPTION as COMMENTS
  from RDB$PACKAGES P
) packages
