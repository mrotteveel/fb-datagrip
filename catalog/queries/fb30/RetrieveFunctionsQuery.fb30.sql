-- Query to retrieve functions
-- Suitable for Firebird 3.0 and higher

select 
  trim(trailing from PACKAGE_NAME) as PACKAGE_NAME,
  trim(trailing from FUNCTION_NAME) as FUNCTION_NAME,
  FUNCTION_KIND,
  /* only non-null for legacy UDF */
  MODULE_NAME,
  /* null for PSQL functions */
  ENTRYPOINT,
  /* null for legacy UDF and PSQL functions */
  ENGINE_NAME,
  RETURN_SQL_TYPE_NAME,
  RETURN_NUMERIC_PRECISION,
  RETURN_NUMERIC_SCALE,
  /* CHAR_LENGTH : use only for CHAR/VARCHAR
   */
  RETURN_CHAR_LENGTH,
  RETURN_CHARACTER_SET_NAME,
  /* UDR, legacy UDF, and PSQL functions in packages have no source;
   * contains <body> in CREATE FUNCTION ... AS <body>
   */
  FUNCTION_SOURCE
from (
  select 
    FUN.RDB$PACKAGE_NAME as PACKAGE_NAME,
    FUN.RDB$FUNCTION_NAME as FUNCTION_NAME,
    case 
      when FUN.RDB$LEGACY_FLAG = 1 then 'UDF'
      when FUN.RDB$ENGINE_NAME is not null then 'UDR'
      else 'PSQL'
    end as FUNCTION_KIND,
    trim(trailing from FUN.RDB$MODULE_NAME) as MODULE_NAME,
    trim(trailing from FUN.RDB$ENTRYPOINT) as ENTRYPOINT,
    trim(trailing from FUN.RDB$ENGINE_NAME) as ENGINE_NAME,
    case coalesce(FUNA.RDB$FIELD_TYPE, F.RDB$FIELD_TYPE)
      when 7 /*smallint; sql_short*/
        then case coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
          when 1 then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when coalesce(FUNA.RDB$FIELD_SCALE, F.RDB$FIELD_SCALE) < 0
              then 'NUMERIC'
              else 'SMALLINT'
            end
          end
      when 8 /*integer; sql_long*/
        then case coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when coalesce(FUNA.RDB$FIELD_SCALE, F.RDB$FIELD_SCALE) < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 16 /*bigint; sql_int64*/
        then case coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when coalesce(FUNA.RDB$FIELD_SCALE, F.RDB$FIELD_SCALE) < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 27 /*double precision; sql_double*/
        then case coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when coalesce(FUNA.RDB$FIELD_SCALE, F.RDB$FIELD_SCALE) < 0
              then 'NUMERIC'
              else 'DOUBLE PRECISION'
            end
          end
      when 11 /*double precision; d_float*/
        then case coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when coalesce(FUNA.RDB$FIELD_SCALE, F.RDB$FIELD_SCALE) < 0
              then 'NUMERIC'
              else 'DOUBLE PRECISION'
            end
          end
      when 10 /*real/float; sql_float*/
        then 'FLOAT' -- actually REAL
      when 14 /*char; sql_text*/
        then 'CHAR'
      when 37 /*varchar; sql_varying*/
        then 'VARCHAR'
      when 35 /*timestamp; sql_timestamp*/
        then 'TIMESTAMP'
      when 13 /*time; sql_type_time*/
        then 'TIME'
      when 12 /*date; sql_type_date*/
        then 'DATE'
      when 261 /*blob; sql_blob*/
        then case coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
          when 0 then 'BLOB SUB_TYPE BINARY'
          when 1 then 'BLOB SUB_TYPE TEXT'
          else 'BLOB SUB_TYPE ' || coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
        end
      when 9 /*array/quad*/
        then 'ARRAY' -- not supported by Jaybird
      -- Firebird 3 types
      when 23 /*boolean; sql_boolean*/
        then 'BOOLEAN'
      -- Firebird 4 types
      when 26 /*extended numerics; sql_dec_fixed*/ /* TODO: address change to int128 */
        then case coalesce(FUNA.RDB$FIELD_SUB_TYPE, F.RDB$FIELD_SUB_TYPE)
          when 1 then 'NUMERIC'
          when 2 then 'DECIMAL'
          else 'NUMERIC'
        end
      when 24 /*decfloat; sql_dec16*/
        then 'DECFLOAT'
      when 25 /*decfloat; sql_dec34*/
        then 'DECFLOAT'
      when 28 /*time with time zone; sql_time_tz*/
        then 'TIME WITH TIME ZONE'
      when 29 /*timestamp with time zone; sql_timestamp_tz*/
        then 'TIMESTAMP WITH TIME ZONE'
      else '<unknown type>'
    end as RETURN_SQL_TYPE_NAME,
    coalesce(FUNA.RDB$FIELD_PRECISION, F.RDB$FIELD_PRECISION) as RETURN_NUMERIC_PRECISION,
    -1 *coalesce(FUNA.RDB$FIELD_SCALE, F.RDB$FIELD_SCALE) as RETURN_NUMERIC_SCALE,
    /* fallback to FIELD_LENGTH */
    coalesce(FUNA.RDB$CHARACTER_LENGTH, F.RDB$CHARACTER_LENGTH, FUNA.RDB$FIELD_LENGTH, F.RDB$FIELD_LENGTH) as RETURN_CHAR_LENGTH,
    trim(trailing from CHARSET.RDB$CHARACTER_SET_NAME) AS RETURN_CHARACTER_SET_NAME,
    RDB$FUNCTION_SOURCE as FUNCTION_SOURCE
  from RDB$FUNCTIONS FUN
    inner join RDB$FUNCTION_ARGUMENTS FUNA
      on FUNA.RDB$FUNCTION_NAME = FUN.RDB$FUNCTION_NAME 
      and FUNA.RDB$PACKAGE_NAME is not distinct from FUN.RDB$PACKAGE_NAME 
      and FUNA.RDB$ARGUMENT_POSITION = FUN.RDB$RETURN_ARGUMENT
    left join RDB$FIELDS F
      on F.RDB$FIELD_NAME = FUNA.RDB$FIELD_SOURCE
    left join RDB$CHARACTER_SETS CHARSET
        on CHARSET.RDB$CHARACTER_SET_ID = coalesce(FUNA.RDB$CHARACTER_SET_ID, F.RDB$CHARACTER_SET_ID)
  where coalesce(FUN.RDB$PRIVATE_FLAG, 0) = 0
) functions
