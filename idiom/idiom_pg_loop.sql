do
language plpgsql
$body$
declare
    _begin     text = '和颜悦色';
    _end       text = '声东击西';

    _path_id int;
    _word    text;
    _tail    text;
    _lv      int;
    _path    text;

    _new_word text;
    _new_tail text;
begin
    create temporary table path (
        path_id serial not null primary key,
        word text not null,
        tail text not null,
        lv int not null,
        path text not null
    ) on commit drop;

    _path_id = 1;
    _word    = _begin;
    _tail    = right(_begin, 1);
    _lv      = 0;
    _path    = '>' || _begin || '>';

    insert into path (word, tail, lv, path)
    values (_word, _tail, _lv, _path);

    <<OUT>>
    loop
        for _new_word, _new_tail in
            select word, lw
            from idiom
            where fw = _tail
        loop
            if _new_word = _end then
                raise notice 'path: %; Level: %',
                    ltrim(_path || _new_word, '>'),
                    _lv + 1;
                
                exit OUT;
            else
                if position('>' || _new_word || '>' in _path) = 0 then
                    insert into path (word, tail, lv, path)
                    values (_new_word, _new_tail, _lv + 1, _path || _new_word || '>');
                end if;
            end if;
        end loop;

        _path_id = _path_id + 1;

        select word, tail, lv, path
        into _word, _tail, _lv, _path
        from path
        where path_id = _path_id;

        if NOT FOUND then
            exit;
        end if;
    end loop;
end;
$body$;

