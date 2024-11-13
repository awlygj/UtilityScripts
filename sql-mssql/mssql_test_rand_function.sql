create or alter procedure rand_int
	@start int,
	@end int,
	@out int output
as
begin
set @out = @start + rand() * (@end - @start);
end;
GO

create or alter procedure rand_char
	@out char output
as
begin
	declare @i int;
	execute rand_int 0, 2, @i output;
	if @i = 0
		execute rand_int 65, 91, @i output;
	else
		execute rand_int 97, 123, @i output;
	set @out = char(@i);
end;
GO

create or alter procedure rand_string
	@len int,
	@out varchar(8000) output
as
begin
	declare @a char;
	while @len > 0
	begin
		execute rand_char @a output;
		set @out = concat(@out, @a);
		set @len -= 1;
	end;
end;
GO

create or alter procedure rand_datetime
	@start datetime,
	@end datetime,
	@out datetime output
as
begin
set @out = @start + rand() * cast(@end - @start as float);
end;
GO



set nocount on;
declare @id int = 1000000;
declare @col_a varchar(12);
declare @col_b int;
declare @col_c datetime;
declare @col_d varchar(12);
declare @fk_t2_id int;
begin transaction;
while @id > 0
begin
	set @col_a = null; 
	set @col_b = null;
	set @col_c = null;
	set @col_d = null;
	set @fk_t2_id = null;
	execute rand_string 3, @col_a output;
	execute rand_int 0, 10, @col_b output;
	execute rand_datetime '2023.01.01', '2024.01.01', @col_c output;
	execute rand_string 12, @col_d output;
	execute rand_int 1, 300, @fk_t2_id output;
	insert into t1 values(@id, @col_a, @col_b, @col_c, @col_d, @fk_t2_id);
	if @id % 10000 = 0
	begin
		commit transaction;
		begin transaction;
		print @id;
	end;
	set @id -= 1;
end;
commit transaction;
set nocount off;
GO

set statistics io on;
set statistics time on;
go

set statistics io off;
set statistics time off;
go

set showplan_text on;
GO
set showplan_text off;
GO



select t.name as tbl_name,
	   s.name as stat_name,
	   string_agg(c.name, ', ')
	   		within group(order by sc.stats_column_id) as column_name,
	   sc.object_id,
	   sc.stats_id
from sys.stats as s
inner join sys.stats_columns as sc
	on s.stats_id = sc.stats_id
	and s.object_id = sc.object_id
inner join sys.tables as t
	on s.object_id = t.object_id
inner join sys.columns as c
	on sc.column_id = c.column_id
	and sc.object_id = c.object_id
where t.name in ('t1', 't2', 't3')
group by sc.object_id, sc.stats_id, t.name, s.name
order by sc.object_id, sc.stats_id;
GO


dbcc show_statistics(t2, col_a);
GO


