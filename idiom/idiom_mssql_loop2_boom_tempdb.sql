use test;
go

--create index idx_idiom_lw on idiom(lw) include (word, fw);
--create index idx_idiom_fw on idiom(fw) include (word, lw);
--go

set statistics io off;
set statistics time off;
set nocount on;
go

declare @begin nvarchar(255) = N'声东击西';
declare @end   nvarchar(255) = N'卧薪尝胆';

declare @lv int = 0;

create table #path (
    word    nvarchar(255) not null,
    tail    nchar(1) not null,
    lv      int not null,
    path    nvarchar(max) not null
);

create clustered index idx_tmp_path on #path (lv, word);

insert into #path (word, tail, lv, path)
values (@begin, right(@begin, 1), @lv, '>' + @begin + '>');

while not exists(
            select *
            from #path
            where lv = @lv
              and word = @end)
begin
    insert into #path (word, tail, lv, path)
    select i.word,
           i.lw,
           p.lv + 1,
           concat(path, i.word, '>') 
    from #path as p
    inner join idiom as i
        on p.tail = i.fw
    where p.lv = @lv
      and charindex('>' + i.word + '>', p.path) = 0;

    if @@ROWCOUNT = 0
    begin
        set @lv = null;
        break;
    end else begin
        set @lv += 1;
    end;
end;

select top 1
    trim('>' from path) as path,
    lv + 1 as num
from #path
where lv = @lv
  and word = @end;

drop table #path;
GO
