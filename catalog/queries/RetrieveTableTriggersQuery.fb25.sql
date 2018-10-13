-- Select triggers for tables and views
-- Suitable for Firebird 2.5 and higher

-- NOTE: Only selects user triggers

select
  trim(trailing from TABLE_NAME) as TABLE_NAME,
  trim(trailing from TRIGGER_NAME) as TRIGGER_NAME,
  IS_ACTIVE,
  PHASE,
  SLOT_1 || coalesce(' or ' || SLOT_2, '') || coalesce(' or ' || SLOT_3, '') as MUTATION_TYPES,
  "POSITION",
  TRIGGER_SOURCE, -- contains <code> (including 'AS') after CREATE TRIGGER ... <code>
  COMMENTS
from (
  select
    TABLE_NAME,
    TRIGGER_NAME,
    IS_ACTIVE,
    PHASE,
    case BIN_SHR(BIN_AND(NORMALIZED_TRIGGER_TYPE, 0x06), 1)
      when 1 then 'INSERT'
      when 2 then 'UPDATE'
      when 3 then 'DELETE'
      else null
    end as SLOT_1,
    case BIN_SHR(BIN_AND(NORMALIZED_TRIGGER_TYPE, 0x18), 3) 
      when 1 then 'INSERT'
      when 2 then 'UPDATE'
      when 3 then 'DELETE'
      else null
    end as SLOT_2,
    case BIN_SHR(BIN_AND(NORMALIZED_TRIGGER_TYPE, 0x60), 5) 
      when 1 then 'INSERT'
      when 2 then 'UPDATE'
      when 3 then 'DELETE'
      else null
    end as SLOT_3,
    "POSITION",
    TRIGGER_SOURCE,
    COMMENTS
  from (
    select
      RDB$RELATION_NAME as TABLE_NAME,
      RDB$TRIGGER_NAME as TRIGGER_NAME,
      case when RDB$TRIGGER_INACTIVE = 1
        then 'F'
        else 'T'
      end AS IS_ACTIVE,
      case when BIN_AND(RDB$TRIGGER_TYPE, 1) = 1
        then 'BEFORE'
        else 'AFTER'
      end as PHASE,
      RDB$TRIGGER_TYPE + BIN_AND(RDB$TRIGGER_TYPE, 1) as NORMALIZED_TRIGGER_TYPE,
      RDB$TRIGGER_SEQUENCE as "POSITION",
      RDB$TRIGGER_SOURCE as TRIGGER_SOURCE,
      RDB$DESCRIPTION as COMMENTS
    from RDB$TRIGGERS
    where RDB$SYSTEM_FLAG = 0 -- user trigger
  ) trigger_info
) triggers
