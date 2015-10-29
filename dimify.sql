use [Sandbox_Kevin];
go

if object_id('Dimify') is not NULL drop procedure Dimify
go

--if object_id('ColListTblType') is NULL create type ColListTblType as table (colname sysname);
--go

--Dimify: for a specified table and list of columns, creates dimensions for each column
--and creates a dimensioned view of the table

create procedure Dimify (
	@tblname sysname,
	@dimcols ColListTblType READONLY,  --table of column names to be turned into dimensions
	@exclcols ColListTblType READONLY  --table of column names to be excluded from view
 ) as begin


declare @cname sysname
declare colcursor cursor local for select colname from @dimcols

open colcursor;
fetch next from colcursor into @cname

--create dimensions for each of the columns to be dimensioned
while @@fetch_status = 0
begin
	execute crDim @tblname,  @cname
	fetch next from colcursor into @cname
End

close colcursor
deallocate colcursor --so it can be used below.


-- create the view on the raw data
-- done by looping through the columns of the raw data table
--		if the column is in the exclude list, skip it
--	    if the column is in the dimension column list, put out the the dim<x>_id and update the from string
--      otherwise just out out the column name in the select list

declare @cmdbuf nvarchar(4000)  -- will hold the create view command string
declare @sellist nvarchar(4000) -- the selection list of columns in the select statement
declare @fromlist nvarchar(4000) -- the from list for the select statement
declare @crlft nvarchar(3) = char(13)+char(10)+char(9) -- carriage return, linefeed, tab

set @fromlist = char(13)+char(10)+'FROM ' + @tblname
set @sellist = ' '

declare colcursor cursor local for
          select column_name from information_schema.columns where table_name = @tblname
open colcursor;
fetch next from colcursor into @cname

while @@fetch_status = 0
begin
	if (@cname NOT IN (select colname from @exclcols))  begin -- not excluded so deal with it
			if (@cname IN (select colname from @dimcols))  begin  -- deal with it as a dimension column
				-- put out the index column
				set @sellist += @crlft+ '[Dim'+@cname+'].[' + @cname + '_id] as [' + @cname + '_id],' --note trailing comma
				set @fromlist += @crlft+ 'INNER JOIN [Dim' + @cname + '] on [' + @tblname + '].[' + @cname + '] = [Dim' + @cname +'].[' + @cname +']'
				end
			else begin -- regular old column
				-- just put out the columname
				set @sellist += @crlft + '[' + @tblname + '].[' + @cname + '] as [' + @cname + '],' --note trailing comma
				end
			end
	fetch next from colcursor into @cname
end
--loop above ends with a trailing comma on @sellist
set @sellist = left(@sellist, len(@sellist)-1)

-- blow away the view if it exists
set @cmdbuf =
       'if object_id(''v' + @tblname + ''') is not NULL drop view [v' + @tblname +'];'
print @cmdbuf
execute sp_executesql @cmdbuf;


set @cmdbuf = 
	'CREATE VIEW [v' + @tblname + '] as' + char(13)+char(10)+'SELECT ' + @sellist + @fromlist

print @cmdbuf
execute sp_executesql @cmdbuf;

end --  procedure dimify