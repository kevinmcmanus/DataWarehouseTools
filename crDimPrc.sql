
if object_id('crDimPrc') is not NULL drop procedure crDimPrc;
go

Create procedure crDimPrc
	@tblname sysname,
	@colname sysname
as Begin

declare @cmdbuf nvarchar(4000);
declare @crlft nvarchar(3) = char(13)+char(10)+char(9) -- carriage return, linefeed, tab

declare @viewname sysname, @dimname sysname, @procname sysname,  @mycol sysname;
set @dimname = '[Dim' + @colname + ']'
set @viewname = '[v' + @tblname + @colname + ']'
set @procname = '[dimprc_' + @tblname + 'Dim' + @colname + ']'
set @mycol = '[' + @colname + ']'

--[re]create the sproc:
set @cmdbuf =
       'if object_id(''' + substring(@procname,2,len(@procname)-2) + ''') is not NULL drop procedure ' + @procname +';'
execute sp_executesql @cmdbuf;

set @cmdbuf =	         ' CREATE PROCEDURE ' +@procname + ' AS set nocount on'
			+	@crlft + ' MERGE ' + @dimname
            +	@crlft + ' USING ' + @viewname
            +   @crlft + ' ON ' + @dimname + '.' + @mycol + ' = ' + @viewname + '.' + @mycol
            +   @crlft + ' WHEN not matched by target then'
            +   @crlft + ' INSERT ( ' + @mycol + ')'
            +   @crlft + ' VALUES ( ' + @mycol + ');'
            +   @crlft + ' select @@rowcount as ''' + substring(@dimname,2,len(@dimname)-2) + 'RowsModified'''

--out put a clean up statement
print 'drop procedure ' + @procname
print @cmdbuf

execute sp_executesql @cmdbuf;

end