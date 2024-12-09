--create index idx_idiom_fw on idiom (fw) include (word, lw);

create temporary table _result (
    lv   int  not null primary key,
    word text not null
);

do
language plpgsql
$body$
declare
    _begin text = N'声东击西';
    _end   text = N'无与伦比';

    _qid   int[] = '{1}'::int[];
begin
    create temporary table _queue (
        qid  serial not null primary key,
        pid  int    not null,
        lv   int    not null,
        word text   not null unique
    ) on commit drop;

    insert into _queue (pid, lv, word)
    values(0, 1, _begin);

    while array_length(_qid, 1) > 0 loop
        with recursive result as (
            select qid, pid, word, lv
            from _queue
            where qid = any (_qid)
              and word = _end

            union all

            select q.qid, q.pid, q.word, q.lv
            from _queue as q
            inner join result as r
                on q.qid = r.pid
        )

        insert into _result
        select lv, word
        from result;
                
        if found then
            exit;
        end if;

        with ist as (
            insert into _queue (pid, lv, word)
            select min(q.qid),
                   min(q.lv) + 1,
                   i.word
            from idiom as i
            inner join _queue as q
                on i.fw = right(q.word, 1)
            where q.qid = any (_qid)
              and not exists (
                    select *
                    from _queue as q2
                    where q2.word = i.word)
            group by i.word
            returning qid
        )
        select array_agg(qid)
        into _qid
        from ist;

    end loop;
end;
$body$;

select *
from _result
order by lv;

drop table _result;

