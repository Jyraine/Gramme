-- Gramme : à coller dans Supabase > SQL Editor, puis « Run ».
-- Ne l'exécute qu'une fois. Remplace l'adresse e-mail tout en bas avant de lancer.

-- 1. Liste des adresses autorisées (toi et tes amis)
create table if not exists public.allowed_emails (email text primary key);
alter table public.allowed_emails enable row level security;
-- Aucune règle pour les utilisateurs : seule la console Supabase peut modifier cette liste.

create or replace function public.is_allowed()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.allowed_emails a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_allowed() from public;
grant execute on function public.is_allowed() to authenticated;

-- 2. Données partagées
create table if not exists public.gear (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.hikes (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.gear enable row level security;
alter table public.hikes enable row level security;

drop policy if exists "membres gear" on public.gear;
create policy "membres gear" on public.gear
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

drop policy if exists "membres hikes" on public.hikes;
create policy "membres hikes" on public.hikes
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

-- 3. Modification d'une partie d'un document sans écraser le reste
create or replace function public.merge_doc(tbl text, doc_id text, patch jsonb)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare n integer;
begin
  if tbl not in ('gear', 'hikes') then
    raise exception 'table inconnue';
  end if;
  execute format('update public.%I set data = data || $1, updated_at = now() where id = $2', tbl)
    using patch, doc_id;
  get diagnostics n = row_count;
  if n = 0 then
    raise exception 'document introuvable' using errcode = 'P0002';
  end if;
end;
$$;
revoke all on function public.merge_doc(text, text, jsonb) from public;
grant execute on function public.merge_doc(text, text, jsonb) to authenticated;

-- 4. Mises à jour en direct entre les appareils
alter publication supabase_realtime add table public.gear, public.hikes;

-- 5. Ton adresse (et celles de tes amis, à ajouter plus tard de la même façon)
insert into public.allowed_emails (email) values ('remplace-par-ton-adresse@exemple.fr')
on conflict do nothing;
