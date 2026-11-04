-- ============================================================
-- Leonid Studio : rôles de l'équipe (coach / admin)
-- À exécuter APRÈS schema.sql, dans SQL Editor → New query → Run.
-- Ré-exécutable sans risque. Ne supprime aucune donnée.
--
--   coach : gère les adhérents, abonnements, mesures, paiements.
--   admin : tout ce que fait le coach + gestion de l'équipe
--           (ajouter / retirer un coach) + suppression d'adhérents.
--   adhérent : voit uniquement ses propres données (inchangé).
-- ============================================================

alter table public.staff add column if not exists role text not null default 'coach';
alter table public.staff drop constraint if exists staff_role_check;
alter table public.staff add constraint staff_role_check check (role in ('coach', 'admin'));

-- ---------- Fonctions ----------

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.staff where user_id = auth.uid() and role = 'admin');
$$;

-- Rôle du compte connecté : 'admin', 'coach' ou null (adhérent / inconnu).
create or replace function public.my_staff_role()
returns text
language sql stable security definer set search_path = public
as $$
  select role from public.staff where user_id = auth.uid();
$$;

-- Liste de l'équipe avec les e-mails (admin seulement).
create or replace function public.staff_list()
returns table (user_id uuid, email text, role text, created_at timestamptz)
language sql stable security definer set search_path = public, auth
as $$
  select s.user_id, u.email::text, s.role, s.created_at
    from public.staff s join auth.users u on u.id = s.user_id
   where public.is_admin()
   order by s.role, u.email;
$$;

-- Ajouter un membre de l'équipe, ou changer son rôle (admin seulement).
-- Le compte doit déjà exister (créé depuis espace.html).
-- Renvoie : 'ok', 'not_admin', 'no_account', 'bad_role', 'self'.
create or replace function public.admin_set_staff(target_email text, target_role text)
returns text
language plpgsql security definer set search_path = public, auth
as $$
declare
  target uuid;
begin
  if not public.is_admin() then return 'not_admin'; end if;
  if target_role not in ('coach', 'admin') then return 'bad_role'; end if;
  select id into target from auth.users where lower(email) = lower(trim(target_email)) limit 1;
  if target is null then return 'no_account'; end if;
  if target = auth.uid() then return 'self'; end if;
  insert into public.staff (user_id, role) values (target, target_role)
  on conflict (user_id) do update set role = excluded.role;
  return 'ok';
end;
$$;

-- Retirer un membre de l'équipe (admin seulement, pas soi-même).
create or replace function public.admin_remove_staff(target uuid)
returns text
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then return 'not_admin'; end if;
  if target = auth.uid() then return 'self'; end if;
  delete from public.staff where user_id = target;
  return 'ok';
end;
$$;

revoke all on function public.is_admin(), public.my_staff_role(), public.staff_list(),
  public.admin_set_staff(text, text), public.admin_remove_staff(uuid) from public, anon;
grant execute on function public.is_admin(), public.my_staff_role(), public.staff_list(),
  public.admin_set_staff(text, text), public.admin_remove_staff(uuid) to authenticated;

-- ---------- Règles : seule la suppression d'adhérents est réservée à l'admin ----------

drop policy if exists members_staff_write on public.members;
drop policy if exists members_staff_insert on public.members;
create policy members_staff_insert on public.members
  for insert to authenticated with check (public.is_staff());
drop policy if exists members_staff_update on public.members;
create policy members_staff_update on public.members
  for update to authenticated using (public.is_staff()) with check (public.is_staff());
drop policy if exists members_admin_delete on public.members;
create policy members_admin_delete on public.members
  for delete to authenticated using (public.is_admin());

-- Personne ne peut écrire directement dans staff : uniquement via les fonctions admin.
revoke insert, update, delete on public.staff from anon, authenticated;

-- ---------- Premier admin ----------
-- Les comptes déjà dans staff (ajoutés avant ce fichier) deviennent admin
-- seulement s'il n'existe encore aucun admin. Vérifie ensuite avec :
--   select u.email, s.role from public.staff s join auth.users u on u.id = s.user_id;
update public.staff set role = 'admin'
 where not exists (select 1 from public.staff where role = 'admin');
