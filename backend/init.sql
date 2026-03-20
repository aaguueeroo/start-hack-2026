-- Leaderboard schema for Supabase
-- Fields requested: username, character_type, score

create extension if not exists pgcrypto;

create table if not exists public.leaderboard_scores (
  id uuid primary key default gen_random_uuid(),
  username text not null check (char_length(trim(username)) > 0),
  character_type text not null check (char_length(trim(character_type)) > 0),
  score integer not null check (score >= 0),
  created_at timestamptz not null default now()
);

-- Migration support for existing schema
alter table public.leaderboard_scores
  add column if not exists character_type text;

update public.leaderboard_scores as ls
set character_type = upper(
  coalesce(
    nullif(ls.character_type, ''),
    nullif(to_jsonb(ls)->>'character_name', ''),
    nullif(to_jsonb(ls)->>'character', ''),
    'UNKNOWN'
  )
)
where ls.character_type is null or ls.character_type = '';

alter table public.leaderboard_scores
  alter column character_type set not null;

alter table public.leaderboard_scores
  drop column if exists character_name;

alter table public.leaderboard_scores
  drop column if exists character;

alter table public.leaderboard_scores
  drop column if exists year;

create index if not exists leaderboard_scores_score_idx
  on public.leaderboard_scores (score desc);

create index if not exists leaderboard_scores_created_at_idx
  on public.leaderboard_scores (created_at desc);

alter table public.leaderboard_scores enable row level security;

drop policy if exists "allow_public_read_scores" on public.leaderboard_scores;
create policy "allow_public_read_scores"
  on public.leaderboard_scores
  for select
  to anon, authenticated
  using (true);

drop policy if exists "allow_public_insert_scores" on public.leaderboard_scores;
create policy "allow_public_insert_scores"
  on public.leaderboard_scores
  for insert
  to anon, authenticated
  with check (true);

-- Multiplayer room schema
create table if not exists public.multiplayer_rooms (
  id uuid primary key default gen_random_uuid(),
  room_code text not null unique,
  status text not null default 'waiting',
  current_round integer not null default 1 check (current_round >= 1),
  created_by uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.multiplayer_players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.multiplayer_rooms (id) on delete cascade,
  user_id uuid not null,
  role text not null check (role in ('market', 'investor')),
  joined_at timestamptz not null default now(),
  unique (room_id, user_id),
  unique (room_id, role)
);

create table if not exists public.multiplayer_round_events (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.multiplayer_rooms (id) on delete cascade,
  round_number integer not null check (round_number >= 1),
  launch_order integer not null check (launch_order >= 1),
  event_payload jsonb not null,
  launched_by uuid,
  created_at timestamptz not null default now(),
  unique (room_id, round_number, launch_order)
);

create table if not exists public.multiplayer_round_results (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.multiplayer_rooms (id) on delete cascade,
  round_number integer not null check (round_number >= 1),
  status text not null default 'simulating',
  started_by uuid,
  events_payload jsonb not null default '[]'::jsonb,
  portfolio_points jsonb not null default '[]'::jsonb,
  last_portfolio_value double precision not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (room_id, round_number)
);

create index if not exists multiplayer_rooms_room_code_idx
  on public.multiplayer_rooms (room_code);
create index if not exists multiplayer_players_room_id_idx
  on public.multiplayer_players (room_id);
create index if not exists multiplayer_round_events_lookup_idx
  on public.multiplayer_round_events (room_id, round_number, launch_order);
create index if not exists multiplayer_round_results_lookup_idx
  on public.multiplayer_round_results (room_id, round_number);

alter table public.multiplayer_rooms enable row level security;
alter table public.multiplayer_players enable row level security;
alter table public.multiplayer_round_events enable row level security;
alter table public.multiplayer_round_results enable row level security;

drop policy if exists "allow_public_read_rooms" on public.multiplayer_rooms;
create policy "allow_public_read_rooms"
  on public.multiplayer_rooms
  for select
  to anon, authenticated
  using (true);

drop policy if exists "allow_public_write_rooms" on public.multiplayer_rooms;
create policy "allow_public_write_rooms"
  on public.multiplayer_rooms
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "allow_public_read_players" on public.multiplayer_players;
create policy "allow_public_read_players"
  on public.multiplayer_players
  for select
  to anon, authenticated
  using (true);

drop policy if exists "allow_public_write_players" on public.multiplayer_players;
create policy "allow_public_write_players"
  on public.multiplayer_players
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "allow_public_read_round_events" on public.multiplayer_round_events;
create policy "allow_public_read_round_events"
  on public.multiplayer_round_events
  for select
  to anon, authenticated
  using (true);

drop policy if exists "allow_public_write_round_events" on public.multiplayer_round_events;
create policy "allow_public_write_round_events"
  on public.multiplayer_round_events
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "allow_public_read_round_results" on public.multiplayer_round_results;
create policy "allow_public_read_round_results"
  on public.multiplayer_round_results
  for select
  to anon, authenticated
  using (true);

drop policy if exists "allow_public_write_round_results" on public.multiplayer_round_results;
create policy "allow_public_write_round_results"
  on public.multiplayer_round_results
  for all
  to anon, authenticated
  using (true)
  with check (true);

grant usage on schema public to anon, authenticated, service_role;

grant select, insert, update, delete on table public.leaderboard_scores
  to anon, authenticated, service_role;
grant select, insert, update, delete on table public.multiplayer_rooms
  to anon, authenticated, service_role;
grant select, insert, update, delete on table public.multiplayer_players
  to anon, authenticated, service_role;
grant select, insert, update, delete on table public.multiplayer_round_events
  to anon, authenticated, service_role;
grant select, insert, update, delete on table public.multiplayer_round_results
  to anon, authenticated, service_role;

notify pgrst, 'reload schema';
