/* 编译器可能有bug, 不知道为什么Lazy Spool这个节点被阻塞了,
 * 之后的filter和top都拿不到元组, 然后tempdb就爆了.
 * ******垃圾微软******
 */

use test;
go

--create index idx_idiom_lw on idiom(lw) include (word, fw);
--create index idx_idiom_fw on idiom(fw) include (word, lw);
--go

with vars as (
    select '破釜沉舟' as head,
           '卧薪尝胆' as tail
), cte as (
    select word,
           fw,
           lw,
           0 as le,
           cast('>' + word + '>' as nvarchar(max)) as path
    from idiom
    where word = (select head from vars)

    union all

    select i.word,
           i.fw,
           i.lw,
           cte.le + 1 as le,
           cte.path + i.word + '>' as path
    from idiom as i
    inner join cte
        on i.fw = cte.lw
    where charindex('>' + i.word + '>', cte.path) = 0
       or cte.word <> (select tail from vars)
)

select top 1
    trim('>' from path) as path
from cte
where word = (select tail from vars)
option(maxrecursion 0);
GO
