-- BASICS

-- 1. Compare Arrays

-- Operators (>, <, >=, <=)
select
array[1, 2, 3] = array[1,2,4] as compare1, -- arrays are equel 
array[1, 2, 3] <> array[1,2,4] as compare2; -- arrays are not equal

-- Containment operators (@>. <@).

-- This reads as array['a', 'b', 'c'] contains array['a', 'b', 'b', 'a']
select array['a', 'b', 'c'] @> array['a', 'b', 'b', 'a'] as contains;
-- this reads as array[1, 1, 4] is contained by array[4, 3, 2, 1]
select array[1, 1, 4] <@ array[4, 3, 2, 1] as is_contained_by;

-- Overlap operator (&&)

select
array[1, 2] && array[2, 3] as overlap1,
array[1, 2] && array[3, 4] as overlap2;

-- 2. Concatentate Strings

-- Operator (||)
select 'Join these ' || 'strings with a number ' || 23;

select first_name||' '||last_name as customer_name from customer limit 5;

-- One disadvantage of using the || operator is a null value in any of the columns being joined together will result in a null value.

select 'Null with ||' || 'will make ' || 'everything disappear' || null;

-- Using `concat()` will transform the nulls into empty strings when concatenating

select concat('Concat() handles', null, ' nulls better', null);


-- 3. Convert the Case of a String

-- The most basic case conversion functions are `lower()` and `upper()`. Usage is pretty straightforwar;

select lower('Turn this into 1OwerCase');
select upper('capiTalize THis');

--  Another useful case conversion function is `initcap()`. which capitalizes the first character of each word and lowers the case of everything else. 
select 
    first_name,
    last_name,
    initcap(concat(first_name, ' ', last_name)) as name
from customer
limit 5;

-- 4. Create an Array

create table contacts (
    first_name varchar,
    last_name varchar,
    phone_numbers varchar[]
);

create table player_scores (
    player_number integer,
    round_scores integer[]
);

create table student_scores (
	student_number integer,
	test_scores decimal[][]
);


create table contacts (
	first_name varchar,
	last_name varchar,
	phone_numbers varchar array
);

create table player_scores (
	player_number integer,
	round_scores integer array[10]
);

-- 5. Insert Data Into an Array

insert into contacts (first_name, last_name, phone_numbers)
values ('Jakit', 'Jawhaa', ARRAY ['999-876-5432','999-123-4567']);

insert into player_scores (player_number, round_scores)
values (10001, ARRAY [95, 92, 96, 97, 98] );

-- multi-dimension arrays must have same array lengths for the inner dimensions
insert into student_scores (student_number, test_scores)
values (20001, ARRAY [[1, 95], [2, 94], [3, 98]]);

-- 6. Modify Arrays 

-- Overwriting an Array
-- overwrite all scores for a player_scors
update player_scores set round_scores='{92,93,94,96,98}' where player_number=10002;

-- change only the score for the second round for player 10001
update player_scores set round_scores[2]=94 where player_number=10001;

-- Prepend and Append to an Array
update player_scores set round_scores = array_prepend(0, round_scores);
update player_scores set round_scores = array_append(round_scores, 100);

-- Concatenate Multiple
select array_cat('{1, 2}', ARRAY[3, 4]) as concatenated_arrays
-- The || operator can be used as a much simpler alternative to array_prepend(), array_append() and array_cat():
select 1 || array[2, 3, 4] as element_prepend;
select array['a', 'b', 'c'] || array['d', 'e', 'f'] as concat_array;
select array[1, 2] || array[[4, 5],[6, 7]] as concat_2d_array;

-- Removal from an Array
select array_remove(round_scores,94) as removed_94 from player_scores;
select array_remove(ARRAY[1,2,3,2,5], 2) as removed_2s;

--  Replace Elements in Array
select array_replace(ARRAY[1,2,3,2,5], 2, 10) as two_becomes_ten;

-- Fill an Array
-- In other words, update the player_scores table with a new record for player_number 10003. All 5 of her scores will be 95.
insert into player_scores (player_number, round_scores) values (10003, array_fill(95,array[5]));
-- Similarly, you update the player_scores table with a new record for player_number 10004. However, his 5 scores of 90, will begin in position 3 in the array. 
insert into player_scores (player_number, round_scores) values (10003, array_fill(95,array[5]));
-- To shows that the scores array for player 10004 started with element position 3, simply query:
select
  round_scores[1],
  round_scores[2],
  round_scores[3]
from player_scores
where player_number in (10003, 10004);

-- 7. Query Arrays

select first_name, last_name, phone_numbers from contacts;
select player_number, round_scores[1] from player_scores;
select * from player_scores where round_scores[1] >= 95;
-- ANY/SOME and ALL . ANY and its synonym SOME will return a row if at least one element satisfies the condition. ALL
select * from player_scores where 95 < any (roundscores);
select * from player_scores where 92 <= all (round_scores);
-- Using unnest() expands an array to multiple rows. The non-array columns get repeated for each row.
select first_name, last_name, unnest(phone_numbers) from contacts;

-- 8. Replace Substrings
select replace('This is old, really old', 'old', 'new');

-- 9. Trim Strings

-- The `trim()` function removes specified characters or spaces from a string
select trim(leading '1' from '111hello111');
select trim(trailing '1' from '111hello111211');
select trim(both 'abc' from 'abcbabccchellocbaabc');

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name
LIMIT 10;

-- 10. string_agg()

`string_agg()` combines non-null values into one string, separated by the delimter character that you specify in the second parameter.

--  For example, in the Sakila database there's a city and a country table. if you want to show the available cities per country in one line, separated by commas:
select country, string_agg(city, ',') as cities from country join city using(country_id) group by country limit 4;

-- Removing duplicates in our output string
select country, string_add(distinct city, ',') as cities from country join city using (country_id) group by country limit 4;

-- Ordering the contents within the output string
select country, string_agg(distinct city, ',' order by city asc) as cities from country join city using (country_id) group by country limit 4;

-- 10 substring()

-- Syntax
-- substring(original_string [from <starting_position>] [for <number_of_characters>])
select substring('Learning SQL is essential.' from 10);
select substring('Learning SQL is essential.' for 13);

-- 11 Substring() with Reqular Expressions

-- Syntax
substring(string from pattern) -- using POSIX regular expressions
substring(string from pattern for escape_char)  -- using SQL regular expressions
select substring('Learning SQL is essential.' from '\w*ss\w*');

-- 12 Insert

-- Assuming the users table has only three columns: first_name, last_name, and email, and in that order
insert into users values ('John', 'Doe', 'john@doe.com');
insert into users (first_name) values ('John');
insert into users (preferences) values ('{ "beta": true }');

-- If we already recorded this webhook, do nothing
insert into stripe_webhooks (event_id) values ('evt_123') on conflict do nothing;

-- Assuming you have a unique index on email
insert into users (email, name) values ('john@doe.com', 'Jane Doe') on conflict (email) do update set name = excluded.name; -- excluded.name refers to the 'Jane Doe' value

-- 13 Update

-- All rows
update users set updated_at = new();
-- Some rows
update users set updated_at = now() where id = 1;

-- 14 Delete
delete from users where id = 1;