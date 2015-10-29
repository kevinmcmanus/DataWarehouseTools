use [Sandbox_Kevin];
go

if object_id('crDim') is not NULL drop procedure crDim;
go

--for the specified column in the spec'd table, create:
--	a view that produces the unique values: vDim<colname>
--  a table to hold the unique values: Dim<colname>
--then load the table with the unique values

Create procedure crDim
	@tblname sysname,
	@colname sysname
as Begin

declare @cmdbuf nvarchar(4000);

--create the view
declare @viewname sysname, @dimname sysname;
set @dimname = 'Dim' + @colname
set @viewname = 'v' + @dimname

set @cmdbuf =
       'if object_id(''' + @viewname + ''') is not NULL drop view [' + @viewname +'];'
execute sp_executesql @cmdbuf;

set @cmdbuf =
       'create view ['+ @viewname + '] as select distinct ['+@colname+ ']'
	 +		' from [' + @tblname + '];';
execute sp_executesql @cmdbuf;

--now make the dim table, but first get the type string for the col to be dim'd
declare @colTypeStr sysname
select @colTypeStr = dbo.getColType(@tblname, @colname)

set @cmdbuf =
       'if object_id(''' + @dimname + ''') is not NULL drop table [' + @dimname +'];'
execute sp_executesql @cmdbuf;

set @cmdbuf = 
      'create table [' + @dimname + '] ( '
	+ '[' + @colname + '_id] int primary key IDENTITY(1,1) NOT NULL,'
	+ '[' + @colname + '] ' + @colTypeStr + ' index [x_' + @colname + ']'
	+ ')'

execute sp_executesql @cmdbuf;

--load the data into the new table
--insert into DimCountry select country from vDimCountry
set @cmdbuf =
	  'insert into [' + @dimname + '] select [' + @colname + '] from [' + @viewname + ']'
execute sp_executesql @cmdbuf;

end

