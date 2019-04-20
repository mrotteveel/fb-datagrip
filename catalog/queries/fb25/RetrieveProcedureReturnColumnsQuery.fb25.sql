-- Retrieves OUT return columns for procedures
-- Suitable for Firebird 2.5 and higher; alternative query for Firebird 3.0 and higher advisable

-- TODO Report domain name if applicable? Distinguish between domain default/not null and field specific default/not null?
-- TODO Report TYPE OF COLUMN
-- TODO Consider impact of Firebird 3 packages and UDR

select 
  trim(trailing from PROCEDURE_NAME) as PROCEDURE_NAME,
  trim(trailing from RETURN_COLUMN_NAME) as RETURN_COLUMN_NAME,
  SQL_TYPE_NAME,
  /* NUMERIC_PRECISION : use only for DECIMAL/NUMERIC/DECFLOAT
   * Can have a value for other types, should be ignored
   */
  NUMERIC_PRECISION,
  /* NUMERIC_SCALE : use only for DECIMAL/NUMERIC
   * Can have a value for non-NUMERIC/DECIMAL types, should be ignored
   */
  NUMERIC_SCALE, 
  /* CHAR_LENGTH : use only for CHAR/VARCHAR
   */
  "CHAR_LENGTH", 
  CHARACTER_SET_NAME,
  COLLATION_NAME, -- reports NULL for default collation
  COLUMN_DEFAULT_SOURCE, -- starts with DEFAULT ..
  IS_NOT_NULL,
  RETURN_COLUMN_NUMBER,
  COMMENTS
from (
  select 
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
      when 23 /*boolean; sql_boolean*/
        then 'BOOLEAN'
      when 26 /*extended numerics; sql_dec_fixed*/
        then case F.RDB$FIELD_SUB_TYPE
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
    CHARSET.RDB$CHARACTER_SET_NAME AS CHARACTER_SET_NAME,
    case when COLLATIONS.RDB$COLLATION_NAME = CHARSET.RDB$DEFAULT_COLLATE_NAME 
      then null
      else COLLATIONS.RDB$COLLATION_NAME 
    end as COLLATION_NAME
  from RDB$PROCEDURE_PARAMETERS PP 
    inner join RDB$FIELDS F 
      on PP.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME 
    left join RDB$CHARACTER_SETS CHARSET
      on F.RDB$CHARACTER_SET_ID = CHARSET.RDB$CHARACTER_SET_ID
    left join RDB$COLLATIONS COLLATIONS
      on COLLATIONS.RDB$CHARACTER_SET_ID = F.RDB$CHARACTER_SET_ID
      and COLLATIONS.RDB$COLLATION_ID = coalesce(PP.RDB$COLLATION_ID, F.RDB$COLLATION_ID)
  where RDB$PARAMETER_TYPE = 1 -- OUT column
) as RETURN_COLUMNS
order by PROCEDURE_NAME, RETURN_COLUMN_NUMBER
