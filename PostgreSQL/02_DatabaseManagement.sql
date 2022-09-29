-- 1. Create table

create table users (
  id serial primary key, -- Auto incrementing IDs
  name character varying, -- String column without specifying a length
  preferences jsonb, -- JSON columns are great for storing unstructured data
  created_at timestamp without time zone -- Always store time in UTC
);

create table users (
    id serial primary key,
    name character varying not null,
    active boolean default true
);

-- Create a temporary table called `scratch_users` with just an `id` column
create temporary table scratch_users (id integer);

-- Or create a temporary table based on the output of a select
create temp table active_users
as
select * from users where active is true;

-- 2. Drop a Table

drop table funky_users;

-- 3. Rename a Table

alter table events rename to events_backup;

-- 4. Truncate a Table

-- Энэ command-ын маш болгоомжтой ашиглаарай. Энэ нь таны PostgreSQL хүснэгтийн агуулгыг хоослох болно. 
truncate my_table;
-- if you have a serial ID column and you'd like to restart its sequence(ie restart IDs from 1);
truncate my_table restart identity;

-- 5. Duplicate a Table

create table dupe_users as (select * from users);

-- The `with no data` here means structure only, no actual rows
create table dupe_users as (select * from users) with no data;

-- 6. Add a Column

-- Here's an example of adding a created_at timestamp column to your users
alter table users add column created_at timestamp without time zone;

-- Adding a string(varchar) column with a not null constraint:
alter table users add column bio character varying not null;

-- Adding a boolean column with a default value:
 alter table users add column active boolean default true;

-- 7. Drop a Column

alter table users drop column created_at;

-- 8. Rename a Column

alter table users rename column registered_at to created_at;

-- 9. Add a Default Value to a Column

-- Example: Orders have a default total of 0 cents
alter table orders alter column total_cents set default 0;

-- Example: Items are available by default
alter table items alter column available set default true;

-- 10. Remove a Default Value From a Column

-- Assuming orders.total_cents had a default value, this will drop the default for future inserts.
alter table orders alter column total_cents drop default;

-- 11. Add a Not Null Constraint

alter table users alter column email set not null;

-- 12. Remove a Not Null Constraint

alter table users alter column email drop not null;

-- 13. Create an Index

-- Having the right indexes are critical to making your queries performant, especially when you have lare amounts of data.
create index concurrently "index_created_at_on_users" on users using btree (created_at);
-- If you want to index multiple columns:
create index concurrently "index_user_id_and_time_on_events" on events using btree (user_id, time);
-- Unique indexes to prevent duplicate data:
create unique index concurrently "index_stripe_event_id_on_stripe_events" on stripe_events using btree(stripe_event_id);
-- Partial indexes to only index rows where a certian condition is met;
create index concurrently "index_active_users" on users using btree(created_at) where active is true;
-- You can also have a unique partial index. For example imagine if each user can only have one active credit card:
-- This will prevent any user from having more than one active credit card
create unique index concurrently "index_active_credit_cards" on credit_cards using btree(user_id) where active is true;

-- 14. Drop a Index

drop index index_created_at_on_users;

-- 15. Create a View

create or replace view enriched_users as ( select * from users inner join enrichments on enrichments.user_id = users.id);

-- 16. Alter Sequence

-- If you have a serial ID column (ie auto incrementing ID), they'll start at 1 by default, but sometimes you may want them to start at a different number. These numbers are known as "sequences" and have their own designated table.
if you have a user.id column, you'll have a `user_id_seq` table. Some helpful columns in there are `start_value`, which will usually be 1, and last_value, which will usually be 1, and last value, which could be a fast way to see how many rows are in your table if you haven't altered your sequence or deleted any rows.
select * from users_id_seq;
-- To alter the sequence so that IDs start a different number, you can't just do an update, you have to use the alter sequence command.
alter sequence users_id_seq restart with 1000;
-- When you're truncating a table, you can truncate and restart IDs from 1 in one command:
truncate bad_users restart identity;

