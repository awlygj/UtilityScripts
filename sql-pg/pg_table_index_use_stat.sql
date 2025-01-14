select quote_ident(sut.schemaname) || '.' || quote_ident(sut.relname) as table_name,
       to_char(c.reltuples, '999,999,999,999,999,999') as estimate_table_rows,
       pg_size_pretty(pg_table_size  ((quote_ident(sut.schemaname) || '.' || quote_ident(sut.relname))::regclass)) as table_size,
       to_char(sut.seq_scan, '999,999,999,999,999,999') as seq_scan,
       to_char(sut.seq_tup_read, '999,999,999,999,999,999') as seq_tup_read,
       to_char(sout.heap_blks_read, '999,999,999,999,999,999') as heap_blks_read,
       to_char(sout.heap_blks_hit, '999,999,999,999,999,999') as heap_blks_hit,
       pg_size_pretty(pg_indexes_size((quote_ident(sut.schemaname) || '.' || quote_ident(sut.relname))::regclass)) as indexes_size,
       to_char(sut.idx_scan, '999,999,999,999,999,999') as idx_scan,
       to_char(sut.idx_tup_fetch, '999,999,999,999,999,999') as idx_tup_fetch,
       to_char(sout.idx_blks_read, '999,999,999,999,999,999') as idx_blks_read,
       to_char(sout.idx_blks_hit, '999,999,999,999,999,999') as idx_blks_hit
       --toast_blks_read,
       --toast_blks_hit,
       --tidx_blks_read,
       --tidx_blks_hit,
       --pg_size_pretty(c.relpages::bigint * 8 * 1024) as relpages,
from pg_stat_user_tables as sut
inner join pg_class c
    on sut.relid = c.oid
left outer join pg_statio_user_tables as sout
    on sut.relid = sout.relid
--where sut.seq_scan <> 0
--  and c.reltuples > 100000
--order by sut.seq_tup_read / sut.seq_scan desc
order by sut.seq_tup_read desc
limit 40
;

