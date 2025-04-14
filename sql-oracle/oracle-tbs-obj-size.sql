column TBS_NAME format a24
select
a.tablespace_name as TBS_NAME,
round(a.used_space*c.BLOCK_SIZE/1024/1024,2) as DB_DATA_SIZE_MB,
sum(b.bytes/1024/1024) as OS_DBF_SIZE_MB,
round((a.tablespace_size*c.BLOCK_SIZE/1024/1024),2) as MAX_TBS_SIZE_MB,
round(a.used_percent,2) AS PCT,
c.BLOCK_SIZE
from dba_tablespace_usage_metrics a, dba_data_files b, dba_tablespaces c
where a.TABLESPACE_NAME=b.TABLESPACE_NAME
and a.TABLESPACE_NAME = c.TABLESPACE_NAME
group by a.tablespace_name,a.used_space,a.tablespace_size,a.used_percent,c.BLOCK_SIZE
order by PCT desc;

column TABLESPACE_NAME format a24
column SEGMENT_NAME format a36
column SEGMENT_TYPE format a16
select *
from (
select
TABLESPACE_NAME,
SEGMENT_NAME,
SEGMENT_TYPE,
sum(bytes)/1024/1024 as size_mb
from dba_segments
group by
TABLESPACE_NAME,
SEGMENT_NAME,
SEGMENT_TYPE
order by size_mb desc
) a
where rownum <= 500;
