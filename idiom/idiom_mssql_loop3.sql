use test;
go

/* create schema
create index idx_idiom_fw_lw on idiom(fw, lw) include (word);
go

drop table if exists idiomr;

create table idiomr (
    head nchar(1) not null,
    tail nchar(1) not null,
    primary key (head, tail),
);

insert into idiomr(head, tail)
select distinct fw, lw
from idiom;

delete a
output deleted.*
from idiomr as a
where not exists (
    select *
    from idiomr as b
    where a.tail = b.head);

delete a
output deleted.*
from idiomr as a
where not exists (
    select *
    from idiomr as b
    where a.head = b.tail);
*/

set statistics io off;
set statistics time off;
set nocount on;
go

declare @begin nvarchar(255) = N'破绽百出';--
declare @end   nvarchar(255) = N'出尔反尔';--

declare @terminate table (
    item nchar(1) not null primary key);

declare @fisrt nchar(1) = right(@begin, 1);
declare @find  nchar(1) = left(@end, 1);
declare @path  nvarchar(4000) = @fisrt;
declare @item  nchar(1) = @fisrt;
declare @nitem nchar(1) = '';

if @fisrt = @find
begin
    select @begin as word, 1 as id
    union all
    select @end, 2;
end else begin
while 1 = 1
begin
    select top 1 @nitem = tail
    from idiomr
    where head = @item
      and tail > @nitem
      and charindex(tail, @path) = 0
      and not exists (select * from @terminate where item = tail)
    ORDER BY tail;

    if @@rowcount = 1
    begin
        if @nitem = @find
        begin
            set @path += @nitem;
            break;
        end else begin
            set @path += @nitem;
            set @item = @nitem;
            set @nitem = '';
        end;
    end else begin
        if @item = @fisrt
        begin
            set @path = null;
            break;
        end else begin
            insert into @terminate values(@item);
            set @nitem = @item;
            set @item = substring(@path, len(@path) - 1, 1);
            set @path = left(@path, len(@path) - 1);
        end;
    end;
end;

with result as (
    select 1 as idxh,
           2 as idxt,
           substring(@path, 1, 1) as head,
           substring(@path, 2, 1) as tail,
           1 as lv
    where @path is not null

    union all

    select idxh + 1,
           idxt + 1,
           substring(@path, idxh + 1, 1),
           substring(@path, idxt + 1, 1),
           lv + 1
    from result
    where result.idxt + 1 <= len(@path)
)

select word, row_number() over(order by id) as id
from (
    select *
    from (
        select @begin as word, 0 as id
        union all
        select @end, 2147483647
    ) as a
    where @path is not null

    union all

    select w.word, r.lv
    from result as r
    cross apply (
        select word
        from (
            select word,
                   row_number() over(order by word) as rn,
                   count(*) over() as cnt
            from idiom as i
            where i.fw = r.head
              and i.lw = r.tail
        ) as i
        where rn = 1 + cast(rand() * cnt as int)
    ) as w
) as a
order by id
option(maxrecursion 0);
end;
GO
