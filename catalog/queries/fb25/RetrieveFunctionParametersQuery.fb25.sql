-- Query to retrieve functions
-- Suitable for Firebird 2.5 (may work on earlier versions)

select 
  /* always null in Firebird 2.5 and earlier */
  PACKAGE_NAME,
  trim(trailing from FUNCTION_NAME) as FUNCTION_NAME,
  PARAMETER_NAME,
  SQL_TYPE_NAME,
  /* NUMERIC_PRECISION : use only for DECIMAL/NUMERIC
   * Can have a value for other types, should be ignored
   */
  NUMERIC_PRECISION,
  /* NUMERIC_SCALE : use only for DECIMAL/NUMERIC
   * Can have a value for non-NUMERIC/DECIMAL types, should be ignored
   */
  NUMERIC_SCALE,
  /* CHAR_LENGTH : use only for CHAR/VARCHAR */
  "CHAR_LENGTH",
  CHARACTER_SET_NAME,
  /* 1-based parameter number, can in theory have gaps */
  PARAMETER_NUMBER
from (
  select 
    null as PACKAGE_NAME,
    FUN.RDB$FUNCTION_NAME as FUNCTION_NAME,
    /* UDF parameters are positional, no name */
    null as PARAMETER_NAME,
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
      else '<unknown type>'
    end as SQL_TYPE_NAME,
    FUNA.RDB$FIELD_PRECISION as NUMERIC_PRECISION,
    -1 * FUNA.RDB$FIELD_SCALE as NUMERIC_SCALE,
    /* fallback to FIELD_LENGTH */
    coalesce(FUNA.RDB$CHARACTER_LENGTH, FUNA.RDB$FIELD_LENGTH) as "CHAR_LENGTH",
    trim(trailing from CHARSET.RDB$CHARACTER_SET_NAME) as CHARACTER_SET_NAME,
    FUNA.RDB$ARGUMENT_POSITION as PARAMETER_NUMBER
  from RDB$FUNCTIONS FUN
    inner join RDB$FUNCTION_ARGUMENTS FUNA
      on FUNA.RDB$FUNCTION_NAME = FUN.RDB$FUNCTION_NAME and FUNA.RDB$ARGUMENT_POSITION <> FUN.RDB$RETURN_ARGUMENT
    left join RDB$CHARACTER_SETS CHARSET
        on FUNA.RDB$CHARACTER_SET_ID = CHARSET.RDB$CHARACTER_SET_ID
) function_parameters
