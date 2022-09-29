-- 1. Exclude Current or Partial Weeks

-- Let's say you have a simple query that groups by week and looks back at the last 4 weeks:
select 
    date_trunc('week', created_at), -- or hour, day, month, year 
    count(1)
from users
where created_at > now() - interval '4 weeks'
group by 1;

-- To avoid this dip(and the inevitable questions from your manager), use the date_trunc() function in the where clause:
select
  date_trunc('week', created_at),
  count(1)
from users
where date_trunc('week', created_at) != date_trunc('week', now())
and created_at > now() - interval '4 weeks'
group by 1;

-- There's one more problem. If you ran this query mid-week, the starting point of your "look back period" would be in the middle of the week 4 weeks ago. To guard against incomplete weeks in the beginning of your time range, date_trunc() can help again:
select
  date_trunc('week', created_at),
  count(1)
from users
where date_trunc('week', created_at) != date_trunc('week', now())
and created_at > date_trunc('week',now()) - interval '4 weeks'
group by 1;

-- Instead of looking back 4 weeks from now(), your query look backs 4 weeks from the beginning of current week. See the difference in below:
select now(); -- Result: 2020-02-05 19:38:26.423589+00
select date_trunc('week',now()); -- Result: 2020-02-03 00:00:00+00

-- 2. Use BETWEEN Correctly

-- Imagine you were chief safety inspector at a local trampoline park (bonus points if that is your job in real life). You might write a query like this to get a report of accidents in December:
SELECT * FROM accidents WHERE created_at BETWEEN '2019-12-01' AND '2019-12-31'

-- This query would omit any mishaps the whole day of December 31. Why? Your query only looks from midnight on Dec 1 to midnight on Dec 31. Any bump, abrasion, or mid-air collision that occurred after midnight on the 31st won't be in your results. The query above is the same as:
SELECT *
FROM accidents
WHERE created_at >= '2019-12-01 00:00:00.000000'
AND created_at <= '2019-12-31 00:00:00.000000'

SELECT *
FROM accidents
WHERE created_at >= '2019-12-01'
AND created_at < '2020-01-01'

-- 3. Query Date and Time

-- Get the date and time time right now:
select now(); -- date and time
select current_date; -- date
select current_time; -- time

-- Find rows between two absolute timestamps:
select count(1)
from events
where time between '2018-01-01' and '2018-01-31'

-- Find rows creatted within the last week:
select count(1)
from events
where time > now() - interval '1 week'; -- or '1 week'::interval, as you like

-- Find rows created between one and two weeks ago:
select count(1)
from events
where time between (now() - '1 week'::interval) and (now() - '2 weeks'::interval);

-- Extracting part of a timestamp:
select date_part('minute', now()); -- or hour, day, minute

-- Get the day of the week from a timestamp:
-- returns 0-6 (integer), where 0 is Sunday and 6 is Saturday
select date_part('dow', now());

-- returns a string like monday, tuesday, etc
select to_char(now(), 'day');

-- Converting a timestamp to a unix timestamp (integer seconds);
select date_part('epoch', now());

-- Calculate the difference between two timestamps;
-- Difference in seconds
select date_part('epoch', delivered_at) - date_part('epoch', shipped_at); -- or minute, hour, week, day, etc

-- Alternatively, you can do this with `extract`
select extract(epoch from delivered_at) - extract(epoch from shipped_at);

-- 4. Group by Time

-- When you want to group by minute, hour, day, week, etc. it's tempting to just group by your timestamp column, however, then you'll get one group per second, which is likely not what you want. instead, you need to "truncate" your timestamp to the granularity you want, like minute, hour, day, week, etc. The postgreSQL function you need here is `date_trunc`.
select
  date_trunc('minute', created_at), -- or hour, day, week, month, year
  count(1)
from users
group by 1

-- 5. Round Timestamps

-- Rounding/truncating timestamps are especially useful when you're grouping by time The function you need here is `date_trunc`:

select date_trunc('second', now()) -- or minute, hour, day, month

-- 6. Convert UTC to Local Time Zone

-- if you have a timestamp without time zone column and you're storing timestamps as UTC, you need to tell PostgreSQL that, and then tell it to convert it to your local time zone.
select created_at at time zone 'utc' at time zone 'america/los_angeles' from users;

-- to be more concise, you can also use the abbreviation for the time zone:
select created_at at time zone 'utc' at time zone 'pst' from users;

-- To see the list of time zones PostgreSQL supports:
select * from pg_timezone_names;