-----------------------------------------------------------------
-- UDTF: Convert table rows into JSON objects
-- Parameters: ParTable         --> Table (SQL Name) to be converted
--             ParSchema        --> Schema (SQL Name) of the table to be converted
--             ParWhere         --> Optional:  WHERE conditions for reducing the data
--                                             leading WHERE must not be specified
--             ParOrderBy       --> Optional:  ORDER BY clause for returning the data in a predefined sequence
--                                             leading ORDER BY must not be specified
--             ParNamesLower    --> Optional:  Any value > ' ' --> Array and object names in lowercase
-----------------------------------------------------------------
create or replace function Table2JSON_Object(
                           ParTable         varchar(128),
                           ParSchema        varchar(128),
                           ParWhere         varchar(4096) default '',
                           ParOrderBy       varchar(1024) default '',
                           ParNamesLower    varchar(1)    default '')
      returns table(
        ORDINAL_POSITION bigint
      , JSON_DATA        clob(16 M) ccsid 1208
      )
language SQL
modifies SQL data
specific Table2JSON_Object
not fenced
not deterministic
called on null input
no external action
not secured
set option datfmt  = *ISO,
           commit  = *NONE,
           dbgview = *SOURCE,
           decmpt  = *PERIOD,
           dlyprp  = *YES,
           optlob  = *YES

begin
  declare LocColList clob(1 M)   default '';
  declare LocSQLCmd  clob(2 M)   default '';
  declare LocEmpty   varchar(1)  default '';
  declare Row_num bigint;
  declare JSON_obj   clob(16 M) ccsid 1208;

  declare C1 cursor for DynSQL;

  declare continue handler for SQLException
          begin
            declare LocErrText varchar(132) default '';
            get diagnostics condition 1 LocErrText = MESSAGE_TEXT;
            return;
          end;

  set (ParTable, ParSchema) = (Upper(ParTable), Upper(ParSchema));

  set ParNamesLower = case when trim(ParNamesLower) > ''
                           then '1'
                           else ''
                      end;

  if trim(ParWhere) > ''
    then set ParWhere   = ' WHERE '    concat trim(ParWhere);
  end if;

  if trim(ParOrderBy) > ''
    then set ParOrderBY = ' ORDER BY ' concat trim(ParOrderBy);
  end if;

  -- Build a List containing all columns of the specified columns
  -- separated by a comma
  select ListAgg('key ''' concat case when ParNamesLower = '1'
                                      then lower(Column_Name)
                                      else Column_Name
                                 end
                          concat ''' value ' concat Column_Name,
                ', ')
    into LocColList
    from QSYS2.SysColumns
   where ( Table_Schema, Table_Name ) = ( ParSchema, ParTable )
  ;
  if length(trim(LocColList)) = 0 then
    signal SQLSTATE 'TMS95' set Message_Text = 'Table or Schema not Found';
  end if;

  set LocSQLCmd =
      'select JSON_Object(' concat trim(LocColList) concat ')' concat
      '  from ' concat trim(ParSchema) concat '.' concat trim(ParTable) concat
      ParWhere concat
      ParOrderBy;

  prepare DynSQL from LocSQLCmd;
  open C1;

  begin
    declare at_end smallint default 0;
    declare NOT_FOUND condition for '02000';
    declare continue handler for SQLEXCEPTION set at_end = 1;
    declare continue handler for NOT_FOUND set at_end = 1;

    set Row_num = 1;
    fetch from C1 into JSON_obj;

    while ( at_end = 0 ) do
      pipe ( Row_num, JSON_obj );
      set Row_num = Row_num + 1;
      fetch from C1 into JSON_obj;
    end while;
  end;
  close C1;
  return;
end;

begin
  declare continue handler For SQLEXCEPTION begin end;
  label on specific function Table2JSON_Object is 'Convert table rows into JSON objects';

  comment on parameter specific routine Table2JSON_Object(
    ParTable         is 'Table Name',
    ParSchema        is 'Table Schema',
    ParWhere         is 'Additional WHERE conditions (without leading WHERE)',
    ParOrderBy       is 'ORDER BY for sorting the output (without leading ORDER BY)',
    ParNamesLower    is 'Any Value --> convert all column names into lower case'
  );
end;
