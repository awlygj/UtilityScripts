--============================= blocked & locks ================================
use testAG;
go
select @@SERVERNAME;
go
select r1.session_id, 
	   s.program_name, 
	   r1.status, 
	   r1.command, 
	   r1.blocking_session_id, 
	   r1.wait_type, 
	   r1.wait_resource
from sys.dm_exec_requests as r1
left outer join sys.dm_exec_requests as r2
	on r1.session_id = r2.blocking_session_id
inner join sys.dm_exec_sessions as s
	on r1.session_id = s.session_id
where r1.blocking_session_id <> 0
	or r2.session_id is not null
;
go
select request_session_id,
	   request_mode,
	   request_type,
	   request_status,
	   resource_type,
	   resource_database_id,
	   resource_associated_entity_id
from sys.dm_tran_locks
where resource_database_id = db_id()
  --and resource_type = 'object'
  --and resource_associated_entity_id = 1966630049
  and request_session_id in (78, 103)
order by resource_type, resource_associated_entity_id;

--=============================== statistics ===================================
select a.object_id,
       OBJECT_NAME(a.object_id) as table_name,
       a.stats_id,
       a.name as stats_name,
       a.has_filter,
       a.filter_definition,
       b.stats_column_id,
       COL_NAME(b.object_id, b.column_id) as column_name
from sys.stats as a
inner join sys.stats_columns as b
    on a.object_id = b.object_id
    and a.stats_id = b.stats_id
where OBJECT_NAME(a.object_id) = 'table_name'
  and exists (select *
              from sys.stats_columns as c
              where a.object_id = c.object_id
                and a.stats_id = c.stats_id
                and COL_NAME(c.object_id, c.column_id) = 'column_name')
order by a.stats_id, b.stats_column_id
;

select a.object_id,
       OBJECT_NAME(a.object_id) as table_name,
       a.stats_id,
       a.name as stats_name,
       b.last_updated,
       b.rows,
       b.rows_sampled,
       b.steps,
       b.unfiltered_rows,
       b.modification_counter,
       b.persisted_sample_percent
from sys.stats as a
cross apply sys.dm_db_stats_properties(a.object_id, a.stats_id) as b
where OBJECT_NAME(a.object_id) = 'table_name'
  and a.name = 'stat_name'
;

select a.object_id,
       OBJECT_NAME(a.object_id) as table_name,
       a.stats_id,
       a.name as stats_name,
       b.step_number,
       b.range_high_key,
       b.range_rows,
       b.equal_rows,
       b.distinct_range_rows,
       b.average_range_rows,
       case when (c.val > lag(b.range_high_key) over(order by b.step_number)
                  or lag(b.range_high_key) over(order by b.step_number) is null)
             and c.val <= b.range_high_key then c.val end as value_on
from sys.stats as a
cross apply sys.dm_db_stats_histogram(a.object_id, a.stats_id) as b
cross join (values('value')) as c(val)
where OBJECT_NAME(a.object_id) = 'table_name'
  and a.name = 'stat_name'
order by b.step_number;


DBCC SHOW_STATISTICS (table_name, stat_name);

--==============================================================================
set statistics profile on;
set statistics io on;
set statistics time on;
go

set statistics profile off;
set statistics io off;
set statistics time off;
go

set showplan_text on;
go

set showplan_text off;
go


exec sp_helpindex '';
exec sp_help '';
exec sp_helpstats'';

