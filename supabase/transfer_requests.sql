-- FreeVel · tabella delle richieste di transfer
-- Incolla tutto in Supabase → SQL Editor → Run

create table if not exists public.transfer_requests (
  id              bigint generated always as identity primary key,
  created_at      timestamptz not null default now(),
  request_id      text not null unique,           -- es. T4K9QX, lo stesso che vede il viaggiatore
  user_id         uuid references auth.users(id) on delete set null,
  user_email      text,
  name            text,
  contact_method  text,                           -- phone | whatsapp | email
  contact         text,
  payload         jsonb not null,                 -- richiesta completa (tratte, carrozzina, note…)
  status          text not null default 'sent'    -- sent | searching | options | booked | unavailable | cancelled
                  check (status in ('sent','searching','options','booked','unavailable','cancelled')),
  offer           text,                           -- l'opzione che proponi al viaggiatore
  price           text,
  team_notes      text                            -- note interne, non visibili al viaggiatore
);

alter table public.transfer_requests enable row level security;

-- Chiunque usi il sito (anche senza account) può INVIARE una richiesta, ma non leggere quelle degli altri
drop policy if exists "insert own or guest" on public.transfer_requests;
create policy "insert own or guest" on public.transfer_requests
  for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

-- Un utente registrato vede solo le proprie richieste (servirà per mostrargli lo stato aggiornato)
drop policy if exists "read own" on public.transfer_requests;
create policy "read own" on public.transfer_requests
  for select to authenticated
  using (user_id = auth.uid());

-- Tu (team) lavori dal pannello Supabase (Table Editor), che ignora queste regole: nessuna policy extra necessaria ora.
