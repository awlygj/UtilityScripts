use master;
go

create table #ST_DB_Migration_LIST (
    oserver nvarchar(255) not null,
    nserver nvarchar(255) not null,
    odb     nvarchar(255) not null,
    ndb     nvarchar(255) not null,
    primary key(nserver, ndb)
);

insert into #ST_DB_Migration_LIST values
--('old_server', 'new_server', 'old_database', 'new_database');
('CNZHAPWSQL140', 'CNZHAPWSQL220', 'AEDB', 'AEDB'),
('CNZHAPWSQL140', 'CNZHAPWSQL220', 'SONORA', 'SONORA'),
('CNZHAPWSCL09D', 'CNZHAPWSQL220', 'DB_TOPUP', 'DB_TOPUP'),
('CNZHAPWSCL09D', 'CNZHAPWSQL220', 'eCompassCN', 'eCompassCN'),
('CNZHAPWSCL10D', 'CNZHAPWSQL220', 'ARCHCMPP', 'ARCHCMPP'),
('CNZHAPWSCL10D', 'CNZHAPWSQL220', 'CNCMPOPR', 'CNCMPOPR'),
('CNZHAPWSCL10D', 'CNZHAPWSQL220', 'CNCMPPRD', 'CNCMPPRD'),
('CNZHAPWSCL10D', 'CNZHAPWSQL220', 'DB_NOVA', 'DB_NOVA');

declare @bak_path       nvarchar(max) = N'\\cnsistwscl020\Newsis Backup\FullBackup\';
declare @bak_type       nvarchar(max) = N'_full_backup';
declare @bak_dt         nvarchar(max) = N'_2025_04_15_16_00_00';    --select format(getdate(), '_yyyy_MM_dd_HH_mm_ss');
declare @bak_ext        nvarchar(max) = N'.bak';
declare @bak_desc       nvarchar(max) = N'Windows OSSQL upgrade - 团险Windows OSSQL升级 - plan 历史数据库的一次性迁移';
declare @data_path      nvarchar(max) = N'E:\MSSQL15.MSSQLSERVER\DBFiles\';
declare @keep_file_name int           = 1;

declare @exec_sql_backup  nvarchar(max) = '';
declare @exec_sql_restore nvarchar(max) = '';
declare @exec_sql_move    nvarchar(max) = '';

declare @db_info_flag                               int              = 0;
declare @compatibility_level                        tinyint          = null;
declare @collation_name                             sysname          = null;
declare @user_access_desc                           nvarchar(60)     = null;
declare @is_read_only                               bit              = null;
declare @state_desc                                 nvarchar(60)     = null;
declare @recovery_model_desc                        nvarchar(60)     = null;
declare @is_fulltext_enabled                        bit              = null;
declare @is_trustworthy_on                          bit              = null;
declare @is_db_chaining_on                          bit              = null;
declare @is_master_key_encrypted_by_server          bit              = null;
declare @is_broker_enabled                          bit              = null;
declare @is_cdc_enabled                             bit              = null;
declare @is_encrypted                               bit              = null;
declare @replica_id                                 uniqueidentifier = null;
declare @group_database_id                          uniqueidentifier = null;
declare @default_language_name                      nvarchar(128)    = null;
declare @containment_desc                           nvarchar(60)     = null;
declare @is_memory_optimized_enabled                bit              = null;
declare @is_memory_optimized_elevate_to_snapshot_on bit              = null;
declare @db_size                                    int              = null;

declare @prev_odb nvarchar(max) = '';
declare @oserver  nvarchar(max);
declare @nserver  nvarchar(max);
declare @odb      nvarchar(max);
declare @ndb      nvarchar(max);

declare ST_DB_Migration_LIST cursor for
    select *
    from #ST_DB_Migration_LIST
    where oserver = @@SERVERNAME
    order by odb, nserver, ndb;

open ST_DB_Migration_LIST;

fetch next from ST_DB_Migration_LIST
into @oserver, @nserver, @odb, @ndb;

while @@fetch_status = 0
begin
    --database info
    if @prev_odb <> @odb
    begin
        select
            @compatibility_level                        = compatibility_level,
            @collation_name                             = collation_name,
            @user_access_desc                           = user_access_desc,
            @is_read_only                               = is_read_only,
            @state_desc                                 = state_desc,
            @recovery_model_desc                        = recovery_model_desc,
            @is_fulltext_enabled                        = is_fulltext_enabled,
            @is_trustworthy_on                          = is_trustworthy_on,
            @is_db_chaining_on                          = is_db_chaining_on,
            @is_master_key_encrypted_by_server          = is_master_key_encrypted_by_server,
            @is_broker_enabled                          = is_broker_enabled,
            @is_cdc_enabled                             = is_cdc_enabled,
            @is_encrypted                               = is_encrypted,
            @replica_id                                 = replica_id,
            @group_database_id                          = group_database_id,
            @default_language_name                      = default_language_name,
            @containment_desc                           = containment_desc,
            @is_memory_optimized_enabled                = is_memory_optimized_enabled,
            @is_memory_optimized_elevate_to_snapshot_on = is_memory_optimized_elevate_to_snapshot_on
        from sys.databases
        where name = @odb;

        set @db_info_flag = @@rowcount;

        select @db_size = sum(mf.size) * 8
        from sys.master_files as mf
        inner join sys.databases as d
            on mf.database_id = d.database_id
        where d.name = @odb;
    end

    --backup
    if @prev_odb <> @odb
    begin
        set @exec_sql_backup = N'\
BACKUP DATABASE ' + @odb + N'
TO DISK = ''' + @bak_path + @oserver + N'_' + @odb + @bak_type + @bak_dt + @bak_ext + N'''
WITH COMPRESSION,
     DESCRIPTION = ''' + @bak_desc + N''',
     NAME = ''' + @oserver + N'_' + @odb + @bak_type + @bak_dt + N''',
     MEDIADESCRIPTION = ''' + @bak_desc + N''',
     MEDIANAME = ''' + @oserver + N'_' + @odb + @bak_type + @bak_dt + N''',
     FORMAT,
     STATS = 20;';
    end;

    --restore
    set @exec_sql_move = (
    select N'     move ''' + LogicalName +
               N''' to ''' + @data_path + iif(@keep_file_name = 1, physical_name, @ndb + TailName) +
           N''',' + char(10)
    from (
        select LogicalName,
               physical_name,
               case when type = 0 and FTId = 1 then '.mdf'
                    when type = 1 and FTId = 1 then '_log.ldf'
                    when type = 0 then concat('_', FTId, '.ndf')
                    when type = 1 then concat('_', FTId, '_log.ldf')
               end as TailName
        from (
            select mf.name as LogicalName,
                   reverse(substring(reverse(mf.physical_name),
                                     1,
                                     charindex('\', reverse(mf.physical_name)) - 1)) as physical_name,
                   mf.type,
                   row_number() over(partition by mf.type order by mf.file_id) as FTId
            from sys.master_files as mf
            inner join sys.databases as d
                on mf.database_id = d.database_id
            where d.name = @odb
        ) as t
    ) as t
    for xml path(''));

    set @exec_sql_restore = N'\
RESTORE DATABASE ' + @ndb + N'
FROM DISK = ''' + @bak_path + @oserver + N'_' + @odb + @bak_type + @bak_dt + @bak_ext + N'''
WITH RECOVERY,
' + @exec_sql_move + N'\
     FILE = 1,
     MEDIANAME = ''' + @oserver + N'_' + @odb + @bak_type + @bak_dt + N''',
     STATS = 20;';

    if @prev_odb <> @odb
    begin
        print '-- *Info: Server[' + @oserver + '], Database[' + @odb + '].';
        if @db_info_flag = 0
        begin
            raiserror('Get Database Info Error, Database Not Found!', 16, 1);
        end else begin
            print concat('-- *DB Size: ', format(@db_size, '###,###,###,###'), ' KIB',
                            case when @db_size / 1024 / 1024 / 1024 > 0 then concat(' (', @db_size / 1024.0 / 1024 / 1024, 'TIB)')
                                 when @db_size / 1024 / 1024 > 0 then concat(' (', @db_size / 1024.0 / 1024, 'GIB)')
                                 when @db_size / 1024 > 0 then concat(' (', @db_size / 1024.0, 'MIB)')
                            end);
            print concat('-- *Compatibility Level: ', @compatibility_level);
            print concat('-- *State: ', @state_desc);
            print concat('-- *User Access: ', @user_access_desc);
            print concat('-- *Read Only: ', iif(@is_read_only = 1, 'Yes', 'No'));
            print concat('-- *Recovery Model: ', @recovery_model_desc);
            print concat('-- *Collation Name: ', @collation_name);
            print concat('-- *Default Language: ', @default_language_name);
            print concat('-- *AllwaysOn Group Database ID: ', @group_database_id);
            print concat('-- *AllwaysOn Replica ID: ', @replica_id);
            print concat('-- *Encrypted: ', iif(@is_encrypted = 1, 'Yes', 'No'));
            print concat('-- *Master Key Encrypted By Server: ', iif(@is_master_key_encrypted_by_server = 1, 'Yes', 'No'));
            print concat('-- *Memory Optimized: ', iif(@is_memory_optimized_enabled = 1, 'Yes', 'No'));
            print concat('-- *Memory Optimized Elevate To Snapshot: ', iif(@is_memory_optimized_elevate_to_snapshot_on = 1, 'Yes', 'No'));
            print concat('-- *CDC: ', iif(@is_cdc_enabled = 1, 'Yes', 'No'));
            print concat('-- *Fulltext: ', iif(@is_fulltext_enabled = 1, 'Yes', 'No'));
            print concat('-- *Service Broker: ', iif(@is_broker_enabled = 1, 'Yes', 'No'));
            print concat('-- *Trustworthy: ', iif(@is_trustworthy_on = 1, 'Yes', 'No'));
            print concat('-- *DB Chaining: ', iif(@is_db_chaining_on = 1, 'Yes', 'No'));
            print concat('-- *Containment: ', @containment_desc);
        end
        print '';
    end

    if @prev_odb <> @odb
    begin
        print '-- *Backup: Server[' + @oserver + '], Database[' + @odb + '].';
        if @exec_sql_backup is null or
           @exec_sql_backup = ''
        begin
            raiserror('Backup SQL Text Generate Error!', 16, 1);
        end else begin
            print '-- *Generate SQL Text:';
            print @exec_sql_backup;
            print '-- *Generate SQL Text End.';
        end
        print '';
    end

    print '-- *Restore: Server[' + @oserver + ']>>[' + @nserver + '], Database[' + @odb + ']>>[' + @ndb + '].';
    if @exec_sql_restore is null or
       @exec_sql_restore = ''
    begin
        raiserror('Restore SQL Text Generate Error!', 16, 1);
    end else begin
        print '-- *Generate SQL Text:';
        print @exec_sql_restore;
        print '-- *Generate SQL Text End.';
    end
    print '';

LOOP_NEXT:
    set @exec_sql_backup                            = '';
    set @exec_sql_restore                           = '';
    set @exec_sql_move                              = '';

    set @db_info_flag                               = 0;
    set @compatibility_level                        = null;
    set @collation_name                             = null;
    set @user_access_desc                           = null;
    set @is_read_only                               = null;
    set @state_desc                                 = null;
    set @recovery_model_desc                        = null;
    set @is_fulltext_enabled                        = null;
    set @is_trustworthy_on                          = null;
    set @is_db_chaining_on                          = null;
    set @is_master_key_encrypted_by_server          = null;
    set @is_broker_enabled                          = null;
    set @is_cdc_enabled                             = null;
    set @is_encrypted                               = null;
    set @replica_id                                 = null;
    set @group_database_id                          = null;
    set @default_language_name                      = null;
    set @containment_desc                           = null;
    set @is_memory_optimized_enabled                = null;
    set @is_memory_optimized_elevate_to_snapshot_on = null;
    set @db_size                                    = null;

    set @prev_odb                                   = @odb;

    fetch next from ST_DB_Migration_LIST
    into @oserver, @nserver, @odb, @ndb;
end

close ST_DB_Migration_LIST;
deallocate ST_DB_Migration_LIST;
drop table #ST_DB_Migration_LIST;
go

select t.*, d.name, d.compatibility_level, 'ALTER DATABASE ' + t.ndb + ' SET COMPATIBILITY_LEVEL = 160;'
from #ST_DB_Migration_LIST as t
left outer join sys.databases as d
    on d.name = t.odb
where t.oserver = @@servername
order by t.odb;

select *
from #ST_DB_Migration_LIST as t
left outer join sys.databases as d
    on d.name = t.ndb
where t.nserver = @@servername
order by t.ndb;


execute sys.xp_fixeddrives;
execute sys.xp_fileexist '\\cnsistwscl020\Newsis Backup\FullBackup\';
