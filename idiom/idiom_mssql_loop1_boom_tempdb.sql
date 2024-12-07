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

declare @path_id int;
declare @word    nvarchar(255);
declare @tail    nchar(1);
declare @lv      int;
declare @path    nvarchar(max);

declare @new_word nvarchar(255);
declare @new_tail nchar(1);

create table #path (
    path_id int not null identity(1, 1) primary key,
    word    nvarchar(255) not null,
    tail    nchar(1) not null,
    lv      int not null,
    path    nvarchar(max) not null
);

set @path_id = 1;
set @word    = @begin;
set @tail    = right(@begin, 1);
set @lv      = 0;
set @path    = '>' + @begin + '>';

insert into #path (word, tail, lv, path)
values (@word, @tail, @lv, @path);

while 1 = 1
begin
    declare idiom cursor for
        select word, lw
        from idiom
        where fw = @tail;

    open idiom;

    fetch next from idiom
    into @new_word, @new_tail;

    while @@FETCH_STATUS = 0
    begin
        if @new_word = @end
        begin
            select ltrim(@path + @new_word, '>') as path,
                   @lv + 1 as Level;

            close idiom;
            deallocate idiom;
            goto OUT;
        end else begin
            if charindex('>' + @new_word + '>', @path) = 0
                insert into #path (word, tail, lv, path)
                values (@new_word, @new_tail, @lv + 1, @path + @new_word + '>');
        end;

        fetch next from idiom
        into @new_word, @new_tail;
    end;

    close idiom;
    deallocate idiom;

    set @path_id += 1;

    select @word = word,
           @tail = tail,
           @lv   = lv,
           @path = path
    from #path
    where path_id = @path_id;

    if @@ROWCOUNT = 0
        goto OUT;
end;

out:

drop table #path;
GO
