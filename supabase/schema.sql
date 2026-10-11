-- Tier lists des villageois: schéma Supabase.
-- À coller dans Supabase > SQL Editor > New query, puis Run. Sans danger si on le relance.
--
-- Principe: la table n'est pas lisible ni modifiable directement par les visiteurs.
-- Tout passe par des fonctions qui vérifient le mot de passe dans la base elle-même.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.profiles (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 30),
  rank        jsonb not null default '{}'::jsonb,
  pw_hash     text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;
revoke all on table public.profiles from anon, authenticated;
-- Aucune policy: aucun accès direct à la table pour les visiteurs.

-- Lire tous les profils (sans le mot de passe).
create or replace function public.list_profiles()
returns table (id uuid, name text, rank jsonb, updated_at timestamptz)
language sql
security definer
set search_path = public, extensions
as $$
  select p.id, p.name, p.rank, p.updated_at from public.profiles p order by lower(p.name);
$$;

-- Créer un profil. Renvoie son identifiant.
create or replace function public.create_profile(p_name text, p_password text)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  new_id uuid;
  clean text := btrim(coalesce(p_name, ''));
begin
  if char_length(clean) < 1 or char_length(clean) > 30 then
    raise exception 'bad_name';
  end if;
  if p_password is null or char_length(p_password) < 4 or char_length(p_password) > 72 then
    raise exception 'bad_password_format';
  end if;
  if (select count(*) from public.profiles) >= 20 then
    raise exception 'too_many_profiles';
  end if;
  insert into public.profiles (name, pw_hash)
  values (clean, crypt(p_password, gen_salt('bf')))
  returning id into new_id;
  return new_id;
end;
$$;

-- Vérifier un mot de passe.
create or replace function public.check_password(p_id uuid, p_password text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare ok boolean;
begin
  select (pw_hash = crypt(coalesce(p_password, ''), pw_hash)) into ok
  from public.profiles where id = p_id;
  if ok is distinct from true then
    perform pg_sleep(0.5);
    return false;
  end if;
  return true;
end;
$$;

-- Enregistrer le classement d'un profil (mot de passe obligatoire).
create or replace function public.save_rank(p_id uuid, p_password text, p_rank jsonb)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not public.check_password(p_id, p_password) then
    raise exception 'bad_password';
  end if;
  if p_rank is null or jsonb_typeof(p_rank) <> 'object' or length(p_rank::text) > 20000 then
    raise exception 'bad_rank';
  end if;
  update public.profiles set rank = p_rank, updated_at = now() where id = p_id;
end;
$$;

-- Supprimer un profil (mot de passe obligatoire).
create or replace function public.delete_profile(p_id uuid, p_password text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not public.check_password(p_id, p_password) then
    raise exception 'bad_password';
  end if;
  delete from public.profiles where id = p_id;
end;
$$;

-- Seules ces fonctions sont appelables par les visiteurs.
revoke execute on function public.list_profiles() from public;
revoke execute on function public.create_profile(text, text) from public;
revoke execute on function public.check_password(uuid, text) from public;
revoke execute on function public.save_rank(uuid, text, jsonb) from public;
revoke execute on function public.delete_profile(uuid, text) from public;
grant execute on function public.list_profiles() to anon, authenticated;
grant execute on function public.create_profile(text, text) to anon, authenticated;
grant execute on function public.check_password(uuid, text) to anon, authenticated;
grant execute on function public.save_rank(uuid, text, jsonb) to anon, authenticated;
grant execute on function public.delete_profile(uuid, text) to anon, authenticated;
