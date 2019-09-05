-- Retrieves OUT return columns for procedures
-- Suitable for Firebird 2.5

-- TODO Report domain name if applicable? Distinguish between domain default/not null and field specific default/not null?
-- TODO Report TYPE OF COLUMN

select 
  /* always null in Firebird 2.5 and earlier */
  PACKAGE_NAME,
  trim(trailing from PROCEDURE_NAME) as PROCEDURE_NAME,
  trim(trailing from RETURN_COLUMN_NAME) as RETURN_COLUMN_NAME,
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
  COLUMN_DEFAULT_SOURCE, -- starts with = ..
  IS_NOT_NULL,
  RETURN_COLUMN_NUMBER,
  COMMENTS
from (
  select 
    null as PACKAGE_NAME,
    PP.RDB$PROCEDURE_NAME as PROCEDURE_NAME,
    PP.RDB$PARAMETER_NAME as RETURN_COLUMN_NAME,
    case F.RDB$FIELD_TYPE
      when 7 /*smallint; sql_short*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1 then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case  when F.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'SMALLINT'
            end
          end
      when 8 /*integer; sql_long*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when F.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 16 /*bigint; sql_int64*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when F.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 27 /*double precision; sql_double*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when F.RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'DOUBLE PRECISION'
            end
          end
      when 11 /*double precision; d_float*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when F.RDB$FIELD_SCALE < 0
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
        then case F.RDB$FIELD_SUB_TYPE
          when 0 then 'BLOB SUB_TYPE BINARY'
          when 1 then 'BLOB SUB_TYPE TEXT'
          else 'BLOB SUB_TYPE ' || F.RDB$FIELD_SUB_TYPE
        end
      when 9 /*array/quad*/
        then 'ARRAY' -- not supported by Jaybird
      else '<unknown type>'
    end as SQL_TYPE_NAME,
    F.RDB$FIELD_PRECISION as NUMERIC_PRECISION,
    -1 * F.RDB$FIELD_SCALE as NUMERIC_SCALE,
    /* fallback to FIELD_LENGTH */
    coalesce(F.RDB$CHARACTER_LENGTH, F.RDB$FIELD_LENGTH) as "CHAR_LENGTH",
    PP.RDB$DESCRIPTION as COMMENTS,
    coalesce(PP.RDB$DEFAULT_SOURCE, F.RDB$DEFAULT_SOURCE) as COLUMN_DEFAULT_SOURCE,
    PP.RDB$PARAMETER_NUMBER + 1 as RETURN_COLUMN_NUMBER,
    case when PP.RDB$NULL_FLAG = 1 or F.RDB$NULL_FLAG = 1 
      then 'T' 
      else 'F' 
    end as IS_NOT_NULL,
    trim(trailing from CHARSET.RDB$CHARACTER_SET_NAME) AS CHARACTER_SET_NAME
  from RDB$PROCEDURE_PARAMETERS PP 
    inner join RDB$FIELDS F 
      on PP.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME 
    left join RDB$CHARACTER_SETS CHARSET
      on F.RDB$CHARACTER_SET_ID = CHARSET.RDB$CHARACTER_SET_ID
  where PP.RDB$PARAMETER_TYPE = 1 -- OUT column
) as RETURN_COLUMNS
order by PROCEDURE_NAME, RETURN_COLUMN_NUMBER
