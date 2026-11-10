drop view  if exists thirty_min_sessions;
drop macro if exists thirty_min_sessions;
drop view  if exists hourly_activity_count;
drop macro if exists hourly_activity_count;
drop view  if exists activity_yesterday;
drop macro if exists activity_yesterday;

drop table if exists activity_logs_buffer purge;
drop table if exists activity_logs purge;

var uuid number;
exec :uuid := 7;

create table activity_logs (
  activity_log_id raw(16) constraint activity_logs_pk primary key,
  user_id         raw(16) not null,
  event_time      timestamp(3) not null,
  activity_type   varchar2(30)  not null,
  page_or_screen  varchar2(100) not null,
  client_app      varchar2(30)  not null,
  device_type     varchar2(20)  not null
);

create index activity_logs_user_time_ix
  on activity_logs ( user_id, event_time )
  compress 1;

create index activity_logs_time_ix 
  on activity_logs ( event_time );

create global temporary table activity_logs_buffer (
  user_id         raw(16) not null,
  event_time      timestamp(3) not null,
  activity_type   varchar2(30)  not null,
  page_or_screen  varchar2(100) not null,
  client_app      varchar2(30)  not null,
  device_type     varchar2(20)  not null
) on commit preserve rows;

declare
  c_user_count  constant pls_integer := 40;
  c_period_start constant timestamp :=
    cast(trunc(sysdate) as timestamp) - numtodsinterval(6, 'DAY');

  l_user_id          raw(16);
  l_event_time       timestamp(3);
  l_session_start    timestamp(3);
  l_event_count      pls_integer;
  l_session_count    pls_integer;
  l_events_remaining pls_integer;
  l_events_in_session pls_integer;
  l_total_events     pls_integer := 0;
  l_device_type      varchar2(10);

begin
  for user_no in 1 .. c_user_count loop
    -- Start each user's activity at a random point in the first five days.
    l_session_start := c_period_start
      + numtodsinterval(
          trunc(dbms_random.value(0, 5 * 86400 * 1000)) / 1000,
          'SECOND'
        );

    select uuid (4) into l_user_id;

    -- Random event count per user: 18..32, averaging about 1,000 rows.
    l_event_count := trunc(dbms_random.value(18, 33));
    l_session_count := trunc(dbms_random.value(3, 7)); -- 3..6 clumps
    l_events_remaining := l_event_count;

    for session_no in 1 .. l_session_count loop
      if session_no = l_session_count then
        l_events_in_session := l_events_remaining;
      else
        -- Leave at least one event for every remaining session; cap normal
        -- clumps at eight events so users have a mix of session sizes.
        l_events_in_session := trunc(dbms_random.value(
          1,
          least(8, l_events_remaining - (l_session_count - session_no)) + 1
        ));
      end if;

      l_event_time := l_session_start;
      l_device_type := case trunc(dbms_random.value(1, 4))
            when 1 then 'desktop'
            when 2 then 'mobile'
            when 3 then 'tablet'
          end;

      for event_no in 1 .. l_events_in_session loop
        if event_no > 1 then
          -- Add 60,000..600,000 milliseconds (1..10 minutes).
          l_event_time := l_event_time
            + numtodsinterval(
                trunc(dbms_random.value(60000, 600001)) / 1000,
                'SECOND'
              );
        end if;

        insert into activity_logs_buffer (
          user_id,
          event_time,
          activity_type,
          page_or_screen,
          client_app,
          device_type
        ) values (
          l_user_id,
          l_event_time,
          case trunc(dbms_random.value(1, 7))
            when 1 then 'page_view'
            when 2 then 'search'
            when 3 then 'login'
            when 4 then 'add_to_cart'
            when 5 then 'purchase'
            else 'logout'
          end,
          case trunc(dbms_random.value(1, 9))
            when 1 then '/home'
            when 2 then '/products'
            when 3 then '/products/search'
            when 4 then '/product/detail'
            when 5 then '/cart'
            when 6 then '/checkout'
            when 7 then '/account'
            else '/help'
          end,
          case trunc(dbms_random.value(1, 5))
            when 1 then 'web'
            when 2 then 'ios'
            when 3 then 'android'
            else 'desktop_app'
          end,
          l_device_type

        );

        l_total_events := l_total_events + 1;
      end loop;

      l_events_remaining := l_events_remaining - l_events_in_session;

      -- The next clump is separated by at least 30 minutes.
      l_session_start := l_event_time
        + numtodsinterval(trunc(dbms_random.value(30, 1441)), 'MINUTE');
    end loop;
  end loop;

  insert into activity_logs (
    activity_log_id,
    user_id,
    event_time,
    activity_type,
    page_or_screen,
    client_app,
    device_type
  )
  select uuid(:uuid),
         user_id,
         event_time,
         activity_type,
         page_or_screen,
         client_app,
         device_type
  from activity_logs_buffer
  order by event_time, rowid;

  commit;
  dbms_output.put_line('Inserted ' || l_total_events || ' activity log rows.');
end;
/

truncate table activity_logs_buffer;
drop table if exists activity_logs_buffer purge;

exec dbms_stats.gather_table_stats ( ownname => null, tabname => 'activity_logs' );
