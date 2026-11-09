begin;
create table if not exists public.meal_preferences (
  firebase_uid text primary key check (length(firebase_uid) between 1 and 128),
  preferences jsonb not null check (jsonb_typeof(preferences) = 'object'),
  updated_at timestamptz not null default now()
);
alter table public.meal_preferences enable row level security;
revoke all on public.meal_preferences from public, anon, authenticated;
grant select, insert, update on public.meal_preferences to service_role;
comment on table public.meal_preferences is 'Per-member meal filters and favorite catalog IDs; Firebase owner verified by meal-preferences Edge Function.';
commit;
