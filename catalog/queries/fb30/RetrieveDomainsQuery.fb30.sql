-- Retrieves the domains
-- Suitable for Firebird 3.0 and higher

select
  trim(trailing from DOMAIN_NAME) as DOMAIN_NAME,
  SQL_TYPE_NAME,
  /* NUMERIC_PRECISION : use only for DECIMAL/NUMERIC/DECFLOAT
   * Can be 0 for computed numeric/decimal columns. In that case leave 
   * out the type in the computed column definition.
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
  DOMAIN_DEFAULT_SOURCE, -- starts with DEFAULT ..
  DOMAIN_CHECK_CONSTRAINT, -- starts with CHECK ..
  IS_NOT_NULL,
  COMMENTS
from (
  select
    F.RDB$FIELD_NAME as DOMAIN_NAME,
    case F.RDB$FIELD_TYPE
      when 7 /*smallint; sql_short*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1 then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case  when RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'SMALLINT'
            end
          end
      when 8 /*integer; sql_long*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 16 /*bigint; sql_int64*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'INTEGER'
            end
          end
      when 27 /*double precision; sql_double*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when RDB$FIELD_SCALE < 0
              then 'NUMERIC'
              else 'DOUBLE PRECISION'
            end
          end
      when 11 /*double precision; d_float*/
        then case F.RDB$FIELD_SUB_TYPE
          when 1  then 'NUMERIC'
          when 2 then 'DECIMAL'
          else -- should only concern sub_type = 0, but provide fallback
            case when RDB$FIELD_SCALE < 0
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
      -- Firebird 3 types
      when 23 /*boolean; sql_boolean*/
        then 'BOOLEAN'
      -- Firebird 4 types
      when 26 /*extended numerics; sql_dec_fixed*/ /* TODO: address change to int128 */
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
      else '<unknown type>'
    end as SQL_TYPE_NAME,
    F.RDB$FIELD_PRECISION as NUMERIC_PRECISION,
    -1 * F.RDB$FIELD_SCALE as NUMERIC_SCALE,
    /* CHARACTER_LENGTH maybe NULL for system columns, fallback to FIELD_LENGTH */
    coalesce(F.RDB$CHARACTER_LENGTH, F.RDB$FIELD_LENGTH) as "CHAR_LENGTH",
    CHARSET.RDB$CHARACTER_SET_NAME AS CHARACTER_SET_NAME,
    case when COLLATIONS.RDB$COLLATION_NAME = CHARSET.RDB$DEFAULT_COLLATE_NAME 
      then null
      else COLLATIONS.RDB$COLLATION_NAME 
    end as COLLATION_NAME,
    F.RDB$DEFAULT_SOURCE as DOMAIN_DEFAULT_SOURCE,
    F.RDB$VALIDATION_SOURCE AS DOMAIN_CHECK_CONSTRAINT,
    coalesce(F.RDB$NULL_FLAG, 0) = 1 as IS_NOT_NULL,
    F.RDB$DESCRIPTION as COMMENTS
  from RDB$FIELDS F
    left join RDB$CHARACTER_SETS CHARSET
      on F.RDB$CHARACTER_SET_ID = CHARSET.RDB$CHARACTER_SET_ID
    left join RDB$COLLATIONS COLLATIONS
      on COLLATIONS.RDB$CHARACTER_SET_ID = F.RDB$CHARACTER_SET_ID
      and F.RDB$COLLATION_ID = COLLATIONS.RDB$COLLATION_ID
  where F.RDB$FIELD_NAME not starting with 'RDB$'
) domains