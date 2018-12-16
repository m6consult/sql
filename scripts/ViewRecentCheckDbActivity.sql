set nocount on;
use msdb;

declare @databaseName nvarchar(128) = N'';

if OBJECT_ID('tempdb..#databaseCheckDbResults') is not null
begin
	drop table #databaseCheckDbResults;
end

create table #databaseCheckDbResults (
	databaseName nvarchar(128),
	databaseState nvarchar(60),
	lastCheckDbDate datetime
)

if OBJECT_ID('tempdb..#dbinfoResults') is not null
begin
	drop table #dbinfoResults;
end

create table #dbinfoResults (
	parentObject varchar(100),
	object varchar(100),
	field varchar(100),
	value varchar(100)
)

insert #databaseCheckDbResults (databaseName, databaseState)
select d.name, state_desc
from sys.databases d
where d.name not in (N'tempdb')
order by d.name

declare cd cursor for
select d.name
from sys.databases d
where d.name not in (N'tempdb')
order by d.name

open cd

fetch next from cd
into @databaseName

while @@FETCH_STATUS = 0
begin

	DECLARE @sql NVARCHAR(1000) = N'';

	set @sql = 'DBCC DBINFO (' + quotename(@databaseName, '''') + ') WITH TABLERESULTS;'

	delete from #dbinfoResults

	insert into #dbinfoResults
	exec (@sql)

	update #databaseCheckDbResults
	set lastCheckDbDate
		= (
			select convert(datetime, value)
			from #dbinfoResults
			where parentObject = 'DBINFO STRUCTURE:'
			and field = 'dbi_dbccLastKnownGood'
		)
	where databaseName = @databaseName

	fetch next from cd
	into @databaseName

end

close cd
deallocate cd

select * from #databaseCheckDbResults
order by databaseName

drop table #databaseCheckDbResults
drop table #dbinfoResults
