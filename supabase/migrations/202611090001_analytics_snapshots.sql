begin;

create table if not exists public.analytics_snapshots (
  firebase_uid text not null check (length(firebase_uid) between 1 and 128),
  local_date date not null,
  metrics jsonb not null check (jsonb_typeof(metrics) = 'object'),
  updated_at timestamptz not null default now(),
  primary key (firebase_uid, local_date)
);

comment on table public.analytics_snapshots is
  'Self-reported daily activity metrics. Owner is verified by analytics-snapshot Edge Function using Firebase JWT; not medical predictions.';

alter table public.analytics_snapshots enable row level security;
-- No client policies: all requests go through the verified Edge Function.
revoke all on public.analytics_snapshots from public, anon, authenticated;
grant select, insert, update on public.analytics_snapshots to service_role;

commit;
