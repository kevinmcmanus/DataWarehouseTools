use [Sandbox_Kevin];
go

if object_id('getColType') is not NULL drop function getColType
go

--SELECT DATA_TYPE 
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE 
--     TABLE_NAME = 'yourTableName' AND 
--     COLUMN_NAME = 'yourColumnName'




Create function getColType(
	@tblname sysname,
	@colname sysname
	) returns varchar(32)
as Begin

declare @tname varchar(32), @tlen int

select @tname = data_type from information_schema.columns where table_name = @tblname and column_name = @colname
select @tlen = character_maximum_length from information_schema.columns where table_name = @tblname and column_name = @colname


set @tname = @tname + '(' + LTRIM(STR(@tlen,10)) + ')'

return(@tname)

end