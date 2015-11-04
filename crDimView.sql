if object_id('crDimView') is not NULL drop procedure crDimView;
go

--for the specified column in the spec'd table, create:
--	a view that produces the unique values: vDim<tablename><colname>


Create procedure crDimView
	@tblname sysname,
	@colname sysname
as Begin

declare @cmdbuf nvarchar(4000);
declare @crlft nvarchar(3) = char(13)+char(10)+char(9) -- carriage return, linefeed, tab

declare @viewname sysname, @dimname sysname, @procname sysname,  @mycol sysname;
set @dimname = '[Dim' + @colname + ']'
set @viewname = '[v' + @tblname + @colname + ']'
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
print 'drop view ' + @viewname

end