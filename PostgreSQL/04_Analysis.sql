-- 1. Use nullif()

-- The `nullif()` function returns a null valuem if a the value of the field/column defined by the first parameter equals that of the second. Otherwise, it will return the original value. Here's an example below:
select name, platform, nullif(platform, 'Did not specify') as platform_mod from users;

-- Note that `nullif()` is only capable of replacing one value with null. if you need to replace multiple values, you can use the CASE function.
select
  name,
  platform,
  case
    when platform = 'Mac' then null
    when platform = 'Windows' then null
    when platform = 'Linux' then null
    else platform
  end as platform_mod
from users;
 
-- 2. Use Lateral Joins

-- Once upon a time, my queries were a mess. I didn't know how to use lateral joins, so i would copy-and-paste the same calcuations over and over again in my queries
-- Co-workers were starting to talk.

-- Lateral joins allow you to reuse calculations, making your queries near and legible. Let's learn about lateral joins by rewriting an atrocious query together.

-- Queries, Before
select
    (pledged / fx_rate) as pledged_usd,
    (pledged / fx_rate) / backers_count as avg_pledge_usd,
    (goal / fx_rate) - (pledged / fx_rate) as amt_from_goal,
    (deadline - launched_at) / 86400.00 as duration,
    ((goal / fx_rate) - (pledged / fx_rate)) / ((deadline - launched_at) / 86400.00) as usd_needed_daily
from kickstarter_data;

-- Queries, after 
select
    pledged_usd,
    avg_pledge_usd,
    amt_from_goal,
    duration,
    (usd_from_goal / duration) as usd_needed_daily
from kickstarter_data,
    lateral (select pledged / fx_rate as pledged_usd) pu
    lateral (select pledged_usd / backers_count as avg_pledge_usd) apu
    lateral (select goal / fx_rate as goal_usd) gu
    lateral (select goal_usd - pledged_usd as usd_from_goal) ufg
    lateral (select (deadline - launched_at)/86400.00 as duration) dr;

-- 3. Calculate Percentiles

-- Let's say we want to look at the percentiles for query durations. We can use PostgreSQL's percentile_cont function to do that:
select
  percentile_cont(0.25) within group (order by duration asc) as percentile_25,
  percentile_cont(0.50) within group (order by duration asc) as percentile_50,
  percentile_cont(0.75) within group (order by duration asc) as percentile_75,
  percentile_cont(0.95) within group (order by duration asc) as percentile_95
from query_durations

-- if we wnat to view those percentiles by day:
select
  day,
  percentile_cont(0.25) within group (order by duration asc) over (partition by day) as percentile_25,
  percentile_cont(0.50) within group (order by duration asc) over (partition by day) as percentile_50,
  percentile_cont(0.75) within group (order by duration asc) over (partition by day) as percentile_75,
  percentile_cont(0.95) within group (order by duration asc) over (partition by day) as percentile_95
from query_durations
group by 1
order by 1 asc

-- 4. Get the First Row per Group

-- Let's say we have an `events` table that belongs to a `user_id`, and we want to see the first event for each user for that day. The function we need here is `row_number`. it's got a tricky syntax that I always forget. Here's an example PostgreSQL query:
select *, row_number() over (partition by user_id order by created_at desc) as row_number from events where day = '2018-01-01'::date

-- This gives us all the event IDs for the day, plus their `row_number`. Since we only want the first event for that, we can use a `common table expression:`
with _events as (
  select
    *,
    row_number() over (partition by user_id order by created_at desc) as row_number
  from events
  where day = '2018-01-01'::date
)

select *
from _events
where row_number = 1

-- 5. Use generate_series to Avoid Gaps in Data

-- if you're grouping by time and you don't want any gaps in your data, PostgreSQL's `generate_series` can help. The function wants three arguments: `start`, `stop`, and `interval`:
select generate_series(
  date_trunc('hour', now()) - '1 day'::interval, -- start at one day ago, rounded to the hour
  date_trunc('hour', now()), -- stop at now, rounded to the hour
  '1 hour'::interval -- one hour intervals
) as hour

-- Now you can use a common table expression to create a table that has a row for each interval(ie each hour of the day), and then left join that with your time series data(ie new user sign ups per hour).
 with hours as (
  select generate_series(
    date_trunc('hour', now()) - '1 day'::interval,
    date_trunc('hour', now()),
    '1 hour'::interval
  ) as hour
)

select
  hours.hour,
  count(users.id)
from hours
left join users on date_trunc('hour', users.created_at) = hours.hour
group by 1

-- 6. Do Type Casting

-- Cast text to boolean
select 'true'::boolean;

-- Cast float to integer
select 1.0::integer;

-- Cast integer to float
select '3.33'::float;
select 10/3.0; -- This will return a float too

-- Cast text to integer
select '1'::integer;

-- Cast text to timestamp
select '2018-01-01 09:00:00'::timestamp;

-- Cast text to date
select '2018-01-01'::date;

-- Cast text to interval
select '1 minute'::interval;
select '1 hour'::interval;
select '1 day'::interval;
select '1 week'::interval;
select '1 month'::interval;

7. Write a Common Table Expression

-- Common table expressions (CTEs) are a great way to break up complex PostgreSQL queries. Here'ss a simple query to illustrate how to write a CTE:
with beta_users as (
    select *
    from users
    where beta is true
)

select events.*
from events
inner join beta_users on beta_user.id = events.user_id 

-- 8. Import a CSV

-- in your terminal, let's open `psql`:
-- psql your_database_name # or postgres://username:password@amazonaws.com

-- now it's time to use the `\copy` command:
-- Assuming you have already created an imported_users table
-- Assuming your CSV has no headers
\copy imported_users from 'imported_users.csv' csv;

-- If your CSV does have headers, they need to match the columns in your table
\copy imported_users from 'imported_users.csv' csv header;

-- If you want to only import certain columns
\copy imported_users (id, email) from 'imported_users.csv' csv header;

-- 9. Compare Two Values When One Is Null

-- Imagine you're comparing two PostgreSQL columns and you want to know how many rows are different. No problem, you think:
select count(1) from items where width != height;

-- Not so fast if some of the widths or heights are null, they won't be counted! Surely that wasn't your intention. That's where `is distinct from` comes into play:
select count(1) from items where width is distinct from height;

-- 10. Use Coalesce

-- Instead of having that null, you might want that row to be 0. To do that, use the coalesce function, which returns the first non-null argument it's passed:
select day, coalesce(tickets, 0) from stats;

-- 11. Write a Case Statement

-- Case statements are useful when you're reaching for an if statement in your select clause.
select
  case
    when precipitation = 0 then 'none'
    when precipitation <= 5 then 'little'
    when precipitation > 5 then 'lots'
    else 'unknown'
  end as amount_of_rain
from weather_data;

-- 12. Query a JSON Column

-- Give me params.name (text) from the events table
select params->>'name' from events;

-- Find only events with a specific name
select * from events where params->>'name' = 'Click Button';

-- Give me the first index of a JSON array
select params->ids->0 from events;

-- Find users where preferences.beta is true (boolean)
-- This requires type casting preferences->'beta' from json to boolean
select preferences->'beta' from users where (preferences->>'beta')::boolean is true;

-- 13. Use Filter to Have Multiple Counts

-- Using filter is useful when you want to do multiple counts on a table:
select
  count(1), -- Count all users
  count(1) filter (where gender = 'male'), -- Count male users
  count(1) filter (where beta is true) -- Count beta users
  count(1) filter (where active is true and beta is false) -- Count active non-beta users
from users

-- 14. Calculate Cumulative Sum-Running Total

select
  date_trunc('day', created_at) as day,
  count(1)
from users
group by 1

-- Next, we'll write a PostgreSQL common table expression (CTE) and use a window function to keep track of the cumulative sum/running total:

with data as (
  select
    date_trunc('day', created_at) as day,
    count(1)
  from users
  group by 1
)

select
  day,
  sum(count) over (order by day asc rows between unbounded preceding and current row)
from data