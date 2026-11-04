-- ============================================================
-- Leonid Studio : base de données de l'espace adhérent
-- À exécuter UNE FOIS dans Supabase : SQL Editor → New query → coller → Run.
-- Ré-exécutable sans risque (create if not exists / or replace).
--
-- Principe de sécurité (RLS) :
--   * un adhérent connecté ne voit QUE sa propre fiche, ses mesures,
--     ses abonnements et ses paiements ; il ne peut rien modifier ;
--   * l'équipe (table staff : Leonid, Samuel) voit et modifie tout ;
--   * un visiteur non connecté ne voit rien.
--
-- Liaison compte ↔ fiche : Leonid crée la fiche avec l'e-mail de l'adhérent
-- et un code d'activation. L'adhérent crée son compte avec CE même e-mail,
-- puis saisit le code. Les deux doivent correspondre : connaître seulement
-- l'e-mail de quelqu'un ne suffit pas pour voir ses données.
-- ============================================================

-- ---------- Tables ----------

create table if not exists public.staff (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid unique references auth.users (id) on delete set null,
  full_name       text not null,
  full_name_ru    text,
  email           text not null,
  phone           text,
  address         text,
  birth_date      date,
  activation_code text,
  created_at      timestamptz not null default now()
);
create unique index if not exists members_email_unique on public.members (lower(email));
create unique index if not exists members_activation_code_unique on public.members (activation_code) where activation_code is not null;

create table if not exists public.subscriptions (
  id         uuid primary key default gen_random_uuid(),
  member_id  uuid not null references public.members (id) on delete cascade,
  plan       text not null default 'monthly',          -- monthly, quarterly, yearly, punch...
  start_date date not null,
  end_date   date not null,
  price      numeric(10,2),
  created_at timestamptz not null default now(),
  constraint subscriptions_dates check (end_date >= start_date)
);
create index if not exists subscriptions_member_idx on public.subscriptions (member_id, end_date desc);

create table if not exists public.measurements (
  id          uuid primary key default gen_random_uuid(),
  member_id   uuid not null references public.members (id) on delete cascade,
  measured_at date not null default current_date,
  height_cm   numeric(5,1),
  weight_kg   numeric(5,1),
  fat_pct     numeric(4,1),
  muscle_kg   numeric(5,1),
  water_pct   numeric(4,1),
  created_at  timestamptz not null default now()
);
create index if not exists measurements_member_idx on public.measurements (member_id, measured_at desc);

-- Paiements et reçus. Le reçu légal est émis dans Slate :
-- la base ne garde que son numéro, son lien et le statut d'envoi.
create table if not exists public.payments (
  id          uuid primary key default gen_random_uuid(),
  member_id   uuid not null references public.members (id) on delete cascade,
  paid_at     date not null default current_date,
  amount      numeric(10,2) not null check (amount > 0),
  method      text,
  description text,
  status      text not null default 'toIssue' check (status in ('toIssue','issued','sent')),
  slate_no    text,
  slate_url   text check (slate_url is null or slate_url like 'https://%'),
  sent_at     date,
  created_at  timestamptz not null default now()
);
create index if not exists payments_member_idx on public.payments (member_id, paid_at desc);

-- ---------- Fonctions d'aide (security definer : contournent la RLS pour éviter les boucles) ----------

create or replace function public.is_staff()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.staff where user_id = auth.uid());
$$;

create or replace function public.my_member_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select id from public.members where user_id = auth.uid();
$$;

-- Liaison du compte connecté à sa fiche, avec le code d'activation.
-- Renvoie true si la liaison a réussi.
create or replace function public.claim_member(code text)
returns boolean
language plpgsql security definer set search_path = public
as $$
declare
  jwt_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  linked    int;
begin
  if auth.uid() is null or jwt_email = '' then
    return false;
  end if;
  update public.members
     set user_id = auth.uid(), activation_code = null
   where activation_code = upper(trim(code))
     and lower(email) = jwt_email
     and user_id is null;
  get diagnostics linked = row_count;
  return linked = 1;
end;
$$;

-- Codes d'activation : lisibles uniquement par l'équipe (pour les donner aux adhérents).
create or replace function public.staff_activation_codes()
returns table (member_id uuid, full_name text, email text, activation_code text)
language sql stable security definer set search_path = public
as $$
  select m.id, m.full_name, m.email, m.activation_code
    from public.members m
   where public.is_staff() and m.activation_code is not null
   order by m.full_name;
$$;

revoke all on function public.staff_activation_codes() from public, anon;
grant execute on function public.staff_activation_codes() to authenticated;
revoke all on function public.claim_member(text) from public, anon;
grant execute on function public.claim_member(text) to authenticated;
grant execute on function public.is_staff() to authenticated;
grant execute on function public.my_member_id() to authenticated;

-- ---------- Sécurité au niveau des lignes (RLS) ----------

alter table public.staff         enable row level security;
alter table public.members       enable row level security;
alter table public.subscriptions enable row level security;
alter table public.measurements  enable row level security;
alter table public.payments      enable row level security;

-- staff : chacun peut seulement vérifier s'il en fait partie.
drop policy if exists staff_read_self on public.staff;
create policy staff_read_self on public.staff
  for select to authenticated using (user_id = auth.uid());

-- members : l'adhérent lit sa fiche ; l'équipe lit et écrit tout.
drop policy if exists members_read on public.members;
create policy members_read on public.members
  for select to authenticated using (public.is_staff() or user_id = auth.uid());
drop policy if exists members_staff_write on public.members;
create policy members_staff_write on public.members
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- subscriptions, measurements, payments : même modèle.
drop policy if exists subscriptions_read on public.subscriptions;
create policy subscriptions_read on public.subscriptions
  for select to authenticated using (public.is_staff() or member_id = public.my_member_id());
drop policy if exists subscriptions_staff_write on public.subscriptions;
create policy subscriptions_staff_write on public.subscriptions
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists measurements_read on public.measurements;
create policy measurements_read on public.measurements
  for select to authenticated using (public.is_staff() or member_id = public.my_member_id());
drop policy if exists measurements_staff_write on public.measurements;
create policy measurements_staff_write on public.measurements
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists payments_read on public.payments;
create policy payments_read on public.payments
  for select to authenticated using (public.is_staff() or member_id = public.my_member_id());
drop policy if exists payments_staff_write on public.payments;
create policy payments_staff_write on public.payments
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Le code d'activation n'est jamais lisible par l'adhérent (seulement par l'équipe).
revoke select on public.members from anon, authenticated;
grant select (id, user_id, full_name, full_name_ru, email, phone, address, birth_date, created_at)
  on public.members to authenticated;
grant insert, update, delete on public.members to authenticated;

grant select, insert, update, delete on public.subscriptions, public.measurements, public.payments to authenticated;
grant select on public.staff to authenticated;
revoke all on public.staff, public.members, public.subscriptions, public.measurements, public.payments from anon;
