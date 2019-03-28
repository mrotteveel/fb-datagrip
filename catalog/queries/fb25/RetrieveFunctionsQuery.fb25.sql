-- Query to retrieve functions
-- Suitable for Firebird 2.5 (may work on earlier versions),
-- a separate query for Firebird 3 and higher is advisable

-- TODO Consider impact of Firebird 3 packages, stored functions and UDR

select 
  trim(trailing from FUNCTION_NAME) as FUNCTION_NAME,
  FUNCTION_TYPE,
  MODULE_NAME,
  ENTRYPOINT,
  RETURN_SQL_TYPE_NAME,
  RETURN_NUMERIC_PRECISION,
  RETURN_NUMERIC_SCALE,
  /* CHAR_LENGTH : use only for CHAR/VARCHAR
   */
  RETURN_CHAR_LENGTH,
  RETURN_CHARACTER_SET_NAME,
  /* FB2.5 and earlier UDF have no source in db */
  null as FUNCTION_SOURCE
from (
  select 
    FUN.RDB$FUNCTION_NAME as FUNCTION_NAME,
    'UDF' as FUNCTION_TYPE
    FUN.RDB$MODULE_NAME as MODULE_NAME,
    FUN.RDB$ENTRYPOINT as ENTRYPOINT,
    case FUNA.RDB$FIELD_TYPE
      when 7 /*smallint; sql_short*/
        then case FUNA.RDB$FIELD_SUB_TYPE
          when 1 then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when FUNA.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'SMALLINT'
            end
          end
      when 8 /*integer; sql_long*/
        then case FUNA.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when FUNA.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 16 /*bigint; sql_int64*/
        then case FUNA.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when FUNA.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 27 /*double precision; sql_double*/
        then case FUNA.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when FUNA.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'DOUBLE PRECISION'
            end
          end
      when 11 /*double precision; d_float*/
        then case FUNA.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when FUNA.RDB$FIELD_SCALE < 0
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
        then case FUNA.RDB$FIELD_SUB_TYPE
          when 0 then 'BLOB SUB_TYPE BINARY'
          when 1 then 'BLOB SUB_TYPE TEXT'
          else 'BLOB SUB_TYPE ' || FUNA.RDB$FIELD_SUB_TYPE
        end
      when 9 /*array/quad*/
        then 'ARRAY' -- not supported by Jaybird
      when 23 /*boolean; sql_boolean*/
        then 'BOOLEAN'
      when 26 /*extended numerics; sql_dec_fixed*/
        then case FUNA.RDB$FIELD_SUB_TYPE
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
    end as RETURN_SQL_TYPE_NAME,
    FUNA.RDB$FIELD_PRECISION as RETURN_NUMERIC_PRECISION,
    -1 * FUNA.RDB$FIELD_SCALE as RETURN_NUMERIC_SCALE,
    /* fallback to FIELD_LENGTH */
    coalesce(FUNA.RDB$CHARACTER_LENGTH, FUNA.RDB$FIELD_LENGTH) as RETURN_CHAR_LENGTH,
    CHARSET.RDB$CHARACTER_SET_NAME AS RETURN_CHARACTER_SET_NAME
  from RDB$FUNCTIONS FUN
    inner join RDB$FUNCTION_ARGUMENTS FUNA
      on FUNA.RDB$FUNCTION_NAME = FUN.RDB$FUNCTION_NAME and FUNA.RDB$ARGUMENT_POSITION = FUN.RDB$RETURN_ARGUMENT
    left join RDB$CHARACTER_SETS CHARSET
        on FUNA.RDB$CHARACTER_SET_ID = CHARSET.RDB$CHARACTER_SET_ID
  where FUN.RDB$SYSTEM_FLAG = 0
) functions
order by FUNCTION_NAME