use [Sandbox_Kevin];
go

--Dimify: for a specified table and list of columns, creates dimensions for each column
--and creates a dimensioned view of the table

if object_id('Dimify') is not NULL drop procedure Dimify
go

--if object_id('ColListTblType') is NULL create type ColListTblType as table (colname sysname);
--go


create procedure Dimify (
	@tblname sysname,
	@dimcols ColListTblType READONLY,  --table of column names to be turned into dimensions
	@exclcols ColListTblType READONLY  --table of column names to be excluded from view
 ) as begin

declare @cmdbuf nvarchar(4000)  -- will hold text of sql statement to be passed to sp_executesql
declare @cname sysname
declare colcursor cursor local for select colname from @dimcols

--loop through the cols to be dimensioned and use existing or create new dimensions
open colcursor;
fetch next from colcursor into @cname
while @@fetch_status = 0
begin
	-- create the dimension if it doesn't already exist
	if object_id('Dim'+@cname) is NULL execute crDim @tblname,  @cname

	--create the unique value view for this table's column
	execute crDimView @tblname, @cname

	--create the merge update procedure for this table & dimenstion
	execute crDimPrc @tblname, @cname
	
	--load the data in via the 'merge' sproc for this table and dimension
	set @cmdbuf = '[dimprc_' + @tblname + 'Dim'+@cname+']'
	execute sp_executesql @cmdbuf

	fetch next from colcursor into @cname
End

close colcursor
deallocate colcursor --so it can be used below.


-- create the dimensioned view on the raw data:
-- done by looping through the columns of the raw data table
--		if the column is in the exclude list, skip it
--	    if the column is in the dimension column list, put out the the dim<x>_id and update the FROM string
--      otherwise just out out the column name in the select list

declare @sellist nvarchar(4000) -- the column list for the SELECT statement
declare @fromlist nvarchar(4000) -- the FROM part of the select statement
declare @crlft nvarchar(3) = char(13)+char(10)+char(9) -- carriage return, linefeed, tab

set @fromlist = char(13)+char(10)+ 'FROM ' + @tblname
set @sellist  = char(13)+char(10)+ 'SELECT '

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
			else begin -- deal with it as a fact column
				-- just put out the columname
				set @sellist += @crlft + '[' + @tblname + '].[' + @cname + '] as [' + @cname + '],' --note trailing comma
				end
			end
	fetch next from colcursor into @cname
end
--lose the trailing comma on the select list
set @sellist = left(@sellist, len(@sellist)-1) + ' '

-- blow away the view if it exists
set @cmdbuf =
       'if object_id(''v' + @tblname + ''') is not NULL drop view [v' + @tblname +'];'
print @cmdbuf
execute sp_executesql @cmdbuf;


set @cmdbuf = 
	'CREATE VIEW [v' + @tblname + '] as'  + @sellist + @fromlist

print @cmdbuf
execute sp_executesql @cmdbuf;

end --  procedure dimify