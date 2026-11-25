-- ViralAI Studio: secure initial Supabase schema
-- Apply in Supabase SQL Editor. Never expose the service_role key in browser code.

create extension if not exists pgcrypto;

create or replace function public.is_owner()
returns boolean
language sql
stable
as $$
  select coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'owner';
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Untitled project',
  description text,
  project_type text not null default 'video',
  status text not null default 'draft' check (status in ('draft','queued','processing','completed','failed','archived')),
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists projects_user_updated_idx on public.projects(user_id, updated_at desc);

create table if not exists public.generation_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  provider text,
  job_type text not null,
  status text not null default 'pending' check (status in ('pending','queued','processing','completed','failed','cancelled')),
  prompt text,
  input_assets jsonb not null default '[]'::jsonb,
  output_assets jsonb not null default '[]'::jsonb,
  error_code text,
  error_message text,
  estimated_credits integer not null default 0 check (estimated_credits >= 0),
  actual_credits integer not null default 0 check (actual_credits >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists generation_jobs_user_created_idx on public.generation_jobs(user_id, created_at desc);
create index if not exists generation_jobs_status_idx on public.generation_jobs(status, created_at desc);

create table if not exists public.usage_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  generation_job_id uuid references public.generation_jobs(id) on delete set null,
  event_type text not null,
  credits integer not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists usage_ledger_user_created_idx on public.usage_ledger(user_id, created_at desc);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  plan_code text not null default 'free',
  status text not null default 'inactive' check (status in ('inactive','trialing','active','past_due','cancelled','paused')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_type text,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists audit_logs_created_idx on public.audit_logs(created_at desc);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name'));
  insert into public.subscriptions (user_id, plan_code, status)
  values (new.id, 'free', 'inactive');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.generation_jobs enable row level security;
alter table public.usage_ledger enable row level security;
alter table public.subscriptions enable row level security;
alter table public.audit_logs enable row level security;

-- Profiles: users can read their own profile and update only their display name.
drop policy if exists "profile_select_self_or_owner" on public.profiles;
create policy "profile_select_self_or_owner" on public.profiles
for select to authenticated using (id = auth.uid() or public.is_owner());
drop policy if exists "profile_update_self" on public.profiles;
create policy "profile_update_self" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
revoke update on public.profiles from authenticated;
grant update (display_name) on public.profiles to authenticated;

-- Projects are private to their owner; the owner role can monitor all.
drop policy if exists "projects_select_owner" on public.projects;
create policy "projects_select_owner" on public.projects
for select to authenticated using (user_id = auth.uid() or public.is_owner());
drop policy if exists "projects_insert_self" on public.projects;
create policy "projects_insert_self" on public.projects
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "projects_update_self" on public.projects;
create policy "projects_update_self" on public.projects
for update to authenticated using (user_id = auth.uid() or public.is_owner())
with check (user_id = auth.uid() or public.is_owner());
drop policy if exists "projects_delete_self" on public.projects;
create policy "projects_delete_self" on public.projects
for delete to authenticated using (user_id = auth.uid() or public.is_owner());

-- Jobs are readable by their user and the owner. Writes are server-only.
drop policy if exists "jobs_select_self_or_owner" on public.generation_jobs;
create policy "jobs_select_self_or_owner" on public.generation_jobs
for select to authenticated using (user_id = auth.uid() or public.is_owner());

-- Usage ledger is immutable from client sessions; backend service role writes it.
drop policy if exists "usage_select_self_or_owner" on public.usage_ledger;
create policy "usage_select_self_or_owner" on public.usage_ledger
for select to authenticated using (user_id = auth.uid() or public.is_owner());

-- Subscription status and billing identifiers are server-managed.
drop policy if exists "subscription_select_self_or_owner" on public.subscriptions;
create policy "subscription_select_self_or_owner" on public.subscriptions
for select to authenticated using (user_id = auth.uid() or public.is_owner());

-- Audit log is owner-readable only; inserts are server-side only.
drop policy if exists "audit_select_owner" on public.audit_logs;
create policy "audit_select_owner" on public.audit_logs
for select to authenticated using (public.is_owner());

grant select on public.profiles, public.projects, public.generation_jobs, public.usage_ledger, public.subscriptions, public.audit_logs to authenticated;
grant insert, update, delete on public.projects to authenticated;

comment on table public.profiles is 'Public profile data; role is deliberately not stored here.';
comment on table public.usage_ledger is 'Server-written immutable record of credits and usage.';
comment on table public.audit_logs is 'Server-written owner audit trail.';
