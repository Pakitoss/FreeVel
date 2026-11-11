-- FreeVel · tabella dei feedback
-- Incolla tutto in Supabase → SQL Editor → Run (si può rieseguire senza perdere dati)

create table if not exists public.feedback (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  user_id     uuid references auth.users(id) on delete set null,
  rating      smallint check (rating between 1 and 5),
  used        text,          -- no | desk | mail | pdf
  interests   text[] not null default '{}',   -- animali, strumenti, sport, treno, hotel, danni
  comment     text,
  contact     text,          -- email facoltativa lasciata dall'utente
  lang        text
);

alter table public.feedback enable row level security;

-- Chiunque può inviare un feedback (anche senza account); nessuno può leggere quelli degli altri.
drop policy if exists "anyone can send feedback" on public.feedback;
create policy "anyone can send feedback" on public.feedback
  for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

-- Riepilogo pronto da consultare in SQL Editor:  select * from public.feedback_summary;
-- (visibile solo a te dal pannello, non dal sito)
create or replace view public.feedback_summary
with (security_invoker = true) as
select
  count(*)                                         as risposte,
  round(avg(rating)::numeric, 2)                   as voto_medio,
  count(*) filter (where used <> 'no')             as hanno_usato_la_scheda,
  count(*) filter (where 'animali'   = any(interests)) as vogliono_animali,
  count(*) filter (where 'strumenti' = any(interests)) as vogliono_strumenti,
  count(*) filter (where 'sport'     = any(interests)) as vogliono_sport,
  count(*) filter (where 'treno'     = any(interests)) as vogliono_treni,
  count(*) filter (where 'hotel'     = any(interests)) as vogliono_hotel,
  count(*) filter (where 'danni'     = any(interests)) as vogliono_danni
from public.feedback;

revoke all on public.feedback_summary from anon, authenticated;
