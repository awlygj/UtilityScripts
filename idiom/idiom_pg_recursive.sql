with recursive vars as (
    select '破釜沉舟' as head,
           '卧薪尝胆' as tail
), cte as (
    select word,
           fw,
           lw,
           0 as le, 
           '>' || word || '>' as path
    from idiom
    where word = (select head from vars)  

    union all

    select i.word,
           i.fw,
           i.lw,
           cte.le + 1 as le,
           cte.path || i.word || '>' as path
    from idiom as i
    inner join cte
        on i.fw = cte.lw
    where cte.path not like '%>' || i.word ||'>%'
       or cte.word <> (select tail from vars)
 )

select trim('>' from path) as path
from cte
where word = (select tail from vars)
limit 1;

