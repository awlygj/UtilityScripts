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

declare @bak_path       nvarchar(max) = N'\\CNZHAPWSQL220\DB_Backup\';
declare @restore_path   nvarchar(max) = N'E:\DB_Backup\';
declare @data_path      nvarchar(max) = N'E:\MSSQL15.MSSQLSERVER\DBFiles\';
declare @bak_type       nvarchar(max) = N'_full_backup';
declare @bak_dt         nvarchar(max) = N'_2025_04_15_16_00_00';    --select format(getdate(), '_yyyy_MM_dd_HH_mm_ss');
declare @bak_ext        nvarchar(max) = N'.bak';
declare @bak_desc       nvarchar(max) = N'Windows OSSQL upgrade - 团险Windows OSSQL升级 - plan 历史数据库的一次性迁移';
declare @keep_file_name int           = 1;

declare @exec_sql_backup   nvarchar(max) = '';
declare @exec_sql_restore  nvarchar(max) = '';
declare @exec_sql_move     nvarchar(max) = '';
declare @exec_sql_filename nvarchar(max) = '';

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

print '--Use SQLCMD to Run Generated SQL Script.'
print '--sqlcmd -Slocalhost -E -dmaster -HGanjun -N -C -h80 -s"|" -w65535 -W -k2 -e -u -p -I -m-1 -b -g'
print '';
print '';

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

    set @exec_sql_filename = @oserver + N'_' + @odb + @bak_type + @bak_dt;

    --backup
    if @prev_odb <> @odb
    begin
        set @exec_sql_backup = N'\
BACKUP DATABASE ' + @odb + N'
TO DISK = N''' + @bak_path + @exec_sql_filename + @bak_ext + N'''
WITH COMPRESSION,
     DESCRIPTION = N''' + @bak_desc + N''',
     NAME = N''' + @exec_sql_filename + N''',
     MEDIADESCRIPTION = N''' + @bak_desc + N''',
     MEDIANAME = N''' + @exec_sql_filename + N''',
     FORMAT,
     STATS = 1;';
    end;

    --restore
    set @exec_sql_move = (
    select N'     move N''' + LogicalName +
               N''' to N''' + @data_path + iif(@keep_file_name = 1, physical_name, @ndb + TailName) +
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
FROM DISK = N''' + @restore_path + @exec_sql_filename + @bak_ext + N'''
WITH RECOVERY,
' + @exec_sql_move + N'\
     FILE = 1,
     MEDIANAME = N''' + @exec_sql_filename + N''',
     STATS = 1;';

    if @prev_odb <> @odb
    begin
        print '-- *Info: Server[' + @oserver + '], Database[' + @odb + '].';
        if @db_info_flag = 0
        begin
            raiserror('Get Database Info Error, Database Not Found!', 16, 1);
        end else begin
            print concat('-- *DB Size: ', format(@db_size, '###,###,###,###'), ' KIB',
                            case when @db_size / 1024 / 1024 / 1024 > 0 then concat(' (', @db_size / 1024.0 / 1024 / 1024, ' TIB)')
                                 when @db_size / 1024 / 1024 > 0 then concat(' (', @db_size / 1024.0 / 1024, ' GIB)')
                                 when @db_size / 1024 > 0 then concat(' (', @db_size / 1024.0, ' MIB)')
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
            print ':connect ' + @oserver + '';
            print '';
            print 'use master;';
            print 'go'
            print '';
            print 'if @@SERVERNAME <> ''' + @oserver + ''''
            print '    raiserror(''The Server[%s] is not [' + @oserver + ']!'', 16, 1, @@SERVERNAME);';
            print '';
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
        print ':connect ' + @nserver + '';
        print '';
        print 'use master;';
        print 'go'
        print '';
        print 'if @@SERVERNAME <> ''' + @nserver + ''''
        print '    raiserror(''The Server[%s] is not [' + @nserver + ']!'', 16, 1, @@SERVERNAME);';
        print '';
        print @exec_sql_restore;
        print '';
        print ':!! del "' + @restore_path + @exec_sql_filename + @bak_ext + '"';
        print '';
        print '-- *Generate SQL Text End.';
    end
    print '';

LOOP_NEXT:
    set @exec_sql_backup                            = '';
    set @exec_sql_restore                           = '';
    set @exec_sql_move                              = '';
    set @exec_sql_filename                          = '';

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

select d.name as db_name,
       dek.encryption_state,
       c.name as certificate_name,
       dek.encryptor_thumbprint
from sys.certificates as c
left outer join sys.dm_database_encryption_keys as dek
    on dek.encryptor_thumbprint = c.thumbprint
left outer join sys.databases as d
    on dek.database_id = d.database_id
order by encryptor_thumbprint;

SELECT *
FROM sys.symmetric_keys
WHERE name = '##MS_DatabaseMasterKey##';


USE master;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<UseStrongPasswordHere>';
GO
BACKUP MASTER KEY TO FILE = 'path_to_file' ENCRYPTION BY PASSWORD = 'password';
GO

CREATE CERTIFICATE MyServerCert
WITH SUBJECT = 'My DEK Certificate',
     EXPIRY_DATE = '99991231';
GO

BACKUP Certificate MyServerCert
TO FILE = 'MyServerCert_backup'
WITH Private KEY (
    FILE = 'MyServerCert_Priv_key_backup',
    ENCRYPTION BY Password = 'password');
GO

CREATE CERTIFICATE MyServerCert
FROM FILE = 'MyServerCert_backup'    
WITH PRIVATE KEY (
    FILE = 'MyServerCert_Priv_key_backup',
    DECRYPTION BY PASSWORD = 'password');
GO

USE AdventureWorks2022;
GO

CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO

ALTER DATABASE AdventureWorks2022 SET ENCRYPTION ON;
GO
