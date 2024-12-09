use test;
go

--create index idx_idiom_fw on idiom(fw) include (word, lw);
--go

set statistics io off;
set statistics time off;
set nocount on;
go

declare @dt datetime2 = SYSDATETIME();

declare @begin nvarchar(255) = N'声东击西';
declare @end   nvarchar(255) = N'无与伦比';

create table #queue (
    qid  int not null identity(1, 1) primary key,
    pid  int not null,
    lv   int not null,
    word nvarchar(255) not null unique,
    lw   nchar(1) not null index idx_t_queue_lw
);

create table #curr_qid (
    qid  int not null primary key,
    word nvarchar(255) not null index idx_tcurr_qid_word
);

create table #next_qid (
    qid int not null primary key,
    word nvarchar(255) not null index idx_tnext_qid_word
);

insert into #queue (pid, lv, word, lw)
values(0, 1, @begin, right(@begin, 1));

insert into #curr_qid
values(1, @begin);

while 1 = 1
begin
    if exists (select * from #curr_qid where word = @end)
    begin
        with result as (
            select q.qid, q.pid, q.word, q.lv
            from #queue as q
            inner join #curr_qid as cq
                on q.qid = cq.qid
            where cq.word = @end

            union all

            select q.qid, q.pid, q.word, q.lv
            from #queue as q
            inner join result as r
                on q.qid = r.pid
        )

        select lv, word
        from result
        order by lv;

        break;
    end
    else if exists (select * from #curr_qid)
    begin
        truncate table #next_qid;

        insert into #queue (pid, lv, word, lw)
        output inserted.qid, inserted.word
        into #next_qid
        select min(q.qid),
               min(q.lv) + 1,
               i.word,
               right(i.word, 1)
        from idiom as i
        inner join #queue as q
            on i.fw = q.lw
        inner join #curr_qid as cq
            on q.qid = cq.qid
        where not exists (
            select *
            from #queue as q2
            where q2.word = i.word)
        group by i.word;

        truncate table #curr_qid;
        alter table #next_qid switch to #curr_qid;
    end else begin
        break;
    end;
end;

drop table #queue;
drop table #curr_qid;
drop table #next_qid;

print concat('dt = ', datediff(millisecond, @dt, SYSDATETIME()));
go

