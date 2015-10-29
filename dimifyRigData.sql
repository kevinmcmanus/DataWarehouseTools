
declare @tblname sysname
declare @colnames ColListTblType -- where the column names will be specified
declare @excludecolumns ColListTblType -- columns to exclude from the resulting view

-- specify your table name and column names here!
set NOCOUNT ON
set @tblname = 'RawRigData'
insert into @colnames (colname) values
		   ('Country')
         , ('County')
         , ('Basin')
		 , ('Trajectory')
         , ('DrillFor')
		 , ('Location')
		 , ('WellDepth')
		 , ('State/Province')

--excluded columns
insert into @excludecolumns (colname) values
	 ('Year')
	,('Month')
	,('Week')
--set NOCOUNT OFF

--do the deed
execute dimify @tblname, @colnames, @excludecolumns
