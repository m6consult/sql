set nocount on;
use msdb;

declare @databaseName nvarchar(128) = N'';

if OBJECT_ID('tempdb..#databaseBackupResults') is not null
begin
	drop table #databaseBackupResults;
end

create table #databaseBackupResults (
	databaseName nvarchar(128),
	databaseState nvarchar(60),
	databaseRecoveryModel nvarchar(60),
	lastFullBackupDate datetime,
	backupFull_CountIn90Days int,
	backupDiff_CountIn90Days int,
	backupTLog_CountIn90Days int
)

insert #databaseBackupResults (databaseName, databaseState, databaseRecoveryModel)
select d.name, state_desc, recovery_model_desc
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

	update #databaseBackupResults
	set lastFullBackupDate
		= (
			select max(backup_start_date)
			from dbo.backupset
			where database_name = @databaseName
			and type = 'D'
		)
	where databaseName = @databaseName

	update #databaseBackupResults
	set backupFull_CountIn90Days
		= (
			select count(*)
			from dbo.backupset
			where database_name = @databaseName
			and type = 'D'
			and backup_start_date >= DATEADD(day, -90, GETDATE())
		)
	where databaseName = @databaseName

	update #databaseBackupResults
	set backupDiff_CountIn90Days
		= (
			select count(*)
			from dbo.backupset
			where database_name = @databaseName
			and type = 'I'
			and backup_start_date >= DATEADD(day, -90, GETDATE())
		)
	where databaseName = @databaseName

	update #databaseBackupResults
	set backupTLog_CountIn90Days
		= (
			select count(*)
			from dbo.backupset
			where database_name = @databaseName
			and type = 'L'
			and backup_start_date >= DATEADD(day, -90, GETDATE())
		)
	where databaseName = @databaseName

	fetch next from cd
	into @databaseName

end

close cd
deallocate cd

select * from #databaseBackupResults
order by databaseName

drop table #databaseBackupResults
