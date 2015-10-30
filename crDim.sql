use [Sandbox_Kevin];
go

if object_id('crDim') is not NULL drop procedure crDim;
go

--for the specified column in the spec'd table, create:
--	a view that produces the unique values: vDim<colname>
--  a table to hold the unique values: Dim<colname>
--  a stored procedure to merge in new values: dimprc_Dim<colname>
--no longer: then load the table with the unique values -- this is now the caller's responsibility

Create procedure crDim
	@tblname sysname,
	@colname sysname
as Begin

declare @cmdbuf nvarchar(4000);
declare @crlft nvarchar(3) = char(13)+char(10)+char(9) -- carriage return, linefeed, tab

declare @viewname sysname, @dimname sysname, @procname sysname,  @mycol sysname;
set @dimname = '[Dim' + @colname + ']'
set @viewname = '[v' + @colname + ']'
set @procname = '[dimprc_Dim' + @colname + ']'
set @mycol = '[' + @colname + ']'

--create the view
set @cmdbuf =
       'if object_id(''' + substring(@viewname,2,len(@viewname)-2) + ''') is not NULL drop view ' + @viewname +';'
execute sp_executesql @cmdbuf;

set @cmdbuf =
       'create view '+ @viewname + ' as select distinct '+ @mycol
	 +		' from ' + @tblname + ';';
execute sp_executesql @cmdbuf;

--now make the dim table, but first get the type string for the col to be dim'd
declare @colTypeStr sysname
select @colTypeStr = dbo.getColType(@tblname, @colname)

set @cmdbuf =
       'if object_id(''' + substring(@dimname,2,len(@dimname)-2) + ''') is not NULL drop table ' + @dimname +';'
execute sp_executesql @cmdbuf;

set @cmdbuf = 
      'create table ' + @dimname + ' ( '
	+ '[' + @colname + '_id] int primary key IDENTITY(1,1) NOT NULL,'
	+  @mycol + ' ' + @colTypeStr + ' index [x_' + @colname + ']'
	+ ')'

execute sp_executesql @cmdbuf;


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

print @cmdbuf
execute sp_executesql @cmdbuf;

end

