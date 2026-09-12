-- Prep4Job: esquema inicial para cuentas, contenido, progreso y entitlements.
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.interview_questions (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  question text not null,
  answer text not null,
  concepts text[] not null default '{}',
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.learning_concepts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text not null,
  detail text not null,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.progress_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  content_id uuid not null,
  content_kind text not null check (content_kind in ('question', 'concept')),
  answered boolean not null default false,
  repetition integer not null default 0,
  ease_factor double precision not null default 2.5,
  interval_days integer not null default 0,
  due_date timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, content_id, content_kind)
);

create table if not exists public.entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  product_id text,
  tier text not null default 'free' check (tier in ('free', 'premium')),
  original_transaction_id text unique,
  expires_at timestamptz,
  environment text check (environment in ('Sandbox', 'Production')),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''))
  on conflict (id) do nothing;
  insert into public.entitlements (user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.interview_questions enable row level security;
alter table public.learning_concepts enable row level security;
alter table public.progress_items enable row level security;
alter table public.entitlements enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);
create policy "questions_read_free_or_premium" on public.interview_questions for select using (
  not is_premium or exists (select 1 from public.entitlements e where e.user_id = auth.uid() and e.tier = 'premium' and (e.expires_at is null or e.expires_at > now()))
);
create policy "concepts_read_free_or_premium" on public.learning_concepts for select using (
  not is_premium or exists (select 1 from public.entitlements e where e.user_id = auth.uid() and e.tier = 'premium' and (e.expires_at is null or e.expires_at > now()))
);
create policy "progress_select_own" on public.progress_items for select using (auth.uid() = user_id);
create policy "progress_insert_own" on public.progress_items for insert with check (auth.uid() = user_id);
create policy "progress_update_own" on public.progress_items for update using (auth.uid() = user_id);
create policy "progress_delete_own" on public.progress_items for delete using (auth.uid() = user_id);
create policy "entitlements_select_own" on public.entitlements for select using (auth.uid() = user_id);

-- Solo el webhook de servidor debe escribir entitlements; nunca expongas service_role al cliente.
