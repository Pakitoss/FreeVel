-- FreeVel · test della Garanzia Ausilio (fake door)
-- Incolla tutto in Supabase → SQL Editor → Run (si può rieseguire senza perdere dati)
-- Ogni riga è un'azione di un dispositivo anonimo: shown | yes | no | no_reason | email.
-- Nessun nome, nessun dato sulla carrozzina. L'email c'è solo se l'utente la lascia per essere avvisato.

create table if not exists public.protection_interest (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  device_id   text not null,                 -- id casuale salvato sul dispositivo, non collegato all'account
  action      text not null check (action in ('shown','yes','no','no_reason','email')),
  price       numeric(6,2),                  -- prezzo mostrato in euro
  reason      text check (reason is null or reason in ('price','insured','no_need','trust')),
  email       text,
  lang        text
);

alter table public.protection_interest enable row level security;

-- Il sito può solo INSERIRE righe; nessuno può leggerle dal sito.
drop policy if exists "anyone can log protection interest" on public.protection_interest;
create policy "anyone can log protection interest" on public.protection_interest
  for insert to anon, authenticated
  with check (true);

-- Riepilogo da consultare in SQL Editor:  select * from public.protection_summary;
-- Conta i dispositivi unici, così chi apre la pagina più volte vale una volta sola.
create or replace view public.protection_summary
with (security_invoker = true) as
select
  price                                                                    as prezzo,
  count(distinct device_id) filter (where action = 'shown')                as hanno_visto,
  count(distinct device_id) filter (where action = 'yes')                  as hanno_detto_si,
  count(distinct device_id) filter (where action = 'no')                   as hanno_detto_no,
  round(100.0 * count(distinct device_id) filter (where action = 'yes')
        / nullif(count(distinct device_id) filter (where action = 'shown'), 0), 1) as adesione_pct,
  count(distinct device_id) filter (where action = 'email')                as email_lasciate,
  count(*) filter (where action = 'no_reason' and reason = 'price')        as no_costa_troppo,
  count(*) filter (where action = 'no_reason' and reason = 'insured')      as no_ha_gia_assicurazione,
  count(*) filter (where action = 'no_reason' and reason = 'no_need')      as no_non_serve,
  count(*) filter (where action = 'no_reason' and reason = 'trust')        as no_non_si_fida
from public.protection_interest
group by price
order by price;

-- Email di chi vuole essere avvisato:
-- select created_at, email from public.protection_interest where action = 'email' order by created_at desc;
