use test;
go

--create index idx_idiom_lw on idiom(lw) include (word, fw);
--create index idx_idiom_fw on idiom(fw) include (word, lw);
--go

set statistics io off;
set statistics time off;
set nocount on;
go

declare @dt datetime2 = SYSDATETIME();

declare @begin nvarchar(255) = N'阴山背后';--
declare @end   nvarchar(255) = N'济人利物';--

create table #queue (
    qid int not null identity(1, 1) primary key,
    pid int not null,
    lv  int not null,
    word nvarchar(255) not null unique
);

insert into #queue values(0, 1, @begin);

declare @qid  int = 1;
declare @pid  int;
declare @lv   int;
declare @word nvarchar(255);

declare @rowcount int;

while 1 = 1
begin

select @pid  = pid,
       @lv   = lv,
       @word = word
from #queue
where qid = @qid;

set @rowcount = @@rowcount;

--print '>>>>>>>>>>>>>>>>>>>>>'
--print concat('@qid = ', @qid);
--print concat('@pid = ', @pid);
--print concat('@lv = ', @lv);
--print concat('@word = ', @word);

if @rowcount = 1
begin
    if @word = @end
    begin
        with result as (
            select @qid as qid,
                   @pid as pid,
                   @word as word,
                   @lv as lv

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
    end else begin
        insert into #queue
        select @qid, @lv + 1, i.word
        from idiom as i
        where i.fw = right(@word, 1)
          and not exists (
            select *
            from #queue as q
            where q.word = i.word);
    end;
end else begin
    break;
end;

set @qid += 1;
end;

drop table #queue;

print concat('dt = ', datediff(millisecond, @dt, SYSDATETIME()));
go
