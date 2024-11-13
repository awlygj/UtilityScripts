--PostgreSQL test random script
--Random Integer
create or replace function random_int (s int, e int)
returns integer
language sql
volatile
leakproof
returns null on null input
parallel safe
cost 1
as $$select s +  trunc((e - s) * random());$$;

--Random String
create or replace function random_str (len int, all_char int = 0, fix_len int = 1, min_len int = 1)
returns text
language plpgsql
volatile
leakproof
returns null on null input
parallel safe
cost 1
as $$
declare
    ulchar_Or_number int;
    random_number int;
    out_str text = '';
    char_tmp text;
begin
    if len < 1 then
        return null;
    end if;

    if min_len > len then
        return null;
    end if;

    if fix_len = 0 then
        len = random_int(min_len, len + 1);
    elsif fix_len = 1 then
        null;
    else
        return null;
    end if;

    for i in 1 .. len loop
        if all_char = 0 then
            random_number = random_int(0, 2);
            if random_number = 0 then
                ulchar_Or_number = 65;
            else
                ulchar_Or_number = 97;
            end if;
        elsif all_char = 1 then
            random_number = random_int(0, 3);
            if random_number = 0 then
                ulchar_Or_number = 48;
            elsif random_number = 1 then
                ulchar_Or_number = 65;
            else
                ulchar_Or_number = 97;
            end if;
        elsif all_char = 2 then
            ulchar_Or_number = 32;
        else
            return null;
        end if;

        if ulchar_Or_number = 48 then
            char_tmp = chr(ulchar_Or_number + random_int(0, 10));
        elsif ulchar_Or_number in (65, 97) then
            char_tmp = chr(ulchar_Or_number + random_int(0, 26));
        else
            char_tmp = chr(ulchar_Or_number + random_int(0, 95));
        end if;
        
        out_str = out_str || char_tmp;
    end loop;
    
    return out_str;
end;
$$;

--Random Timestamp
create or replace function random_timestamp (s timestamp, e timestamp)
returns timestamp
language sql
volatile
leakproof
returns null on null input
parallel safe
cost 1
as $$select s + (e - s) * random();$$;
