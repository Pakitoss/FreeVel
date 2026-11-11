-- FreeVel · profili salvati nell'account (tabella user_sheets)
-- Supabase → SQL Editor → New query → incolla tutto → Run. Si può rieseguire senza perdere dati.

create table if not exists public.user_sheets (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  sheet_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Il sito salva con "upsert" su user_id: serve che sia unico (se la tabella esisteva già senza chiave)
create unique index if not exists user_sheets_user_id_key on public.user_sheets (user_id);

alter table public.user_sheets enable row level security;

-- Ogni utente legge e scrive solo il proprio profilo
drop policy if exists "read own sheet"   on public.user_sheets;
drop policy if exists "insert own sheet" on public.user_sheets;
drop policy if exists "update own sheet" on public.user_sheets;
drop policy if exists "delete own sheet" on public.user_sheets;

create policy "read own sheet"   on public.user_sheets for select to authenticated using (user_id = auth.uid());
create policy "insert own sheet" on public.user_sheets for insert to authenticated with check (user_id = auth.uid());
create policy "update own sheet" on public.user_sheets for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "delete own sheet" on public.user_sheets for delete to authenticated using (user_id = auth.uid());
