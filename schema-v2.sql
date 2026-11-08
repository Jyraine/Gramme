-- Gramme v2 : sorties privées, partage par lien, matériel personnel.
-- À coller dans Supabase > SQL Editor, puis « Run ». Une seule fois.
-- Supabase peut afficher un avertissement « destructive operation » (drop policy) : confirme.

-- 0. Les données existantes appartiennent à ton compte
update public.gear  set data = data || jsonb_build_object('owner', 'mymath95270@gmail.com') where data->>'owner' is null;
update public.hikes set data = data || jsonb_build_object('owner', 'mymath95270@gmail.com', 'members', '[]'::jsonb) where data->>'owner' is null;

-- 1. Adresse de la personne connectée, en minuscules
create or replace function public.me()
returns text language sql stable
as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) $$;
grant execute on function public.me() to authenticated;

-- 2. Règles d'accès
drop policy if exists "membres gear" on public.gear;
drop policy if exists "gear proprietaire" on public.gear;
create policy "gear proprietaire" on public.gear
  for all to authenticated
  using (public.is_allowed() and data->>'owner' = public.me())
  with check (public.is_allowed() and data->>'owner' = public.me());

drop policy if exists "membres hikes" on public.hikes;
drop policy if exists "hikes lecture" on public.hikes;
drop policy if exists "hikes ajout" on public.hikes;
drop policy if exists "hikes modif" on public.hikes;
drop policy if exists "hikes suppression" on public.hikes;
create policy "hikes lecture" on public.hikes for select to authenticated
  using (public.is_allowed() and (data->>'owner' = public.me() or jsonb_exists(coalesce(data->'members', '[]'::jsonb), public.me())));
create policy "hikes ajout" on public.hikes for insert to authenticated
  with check (public.is_allowed() and data->>'owner' = public.me());
create policy "hikes modif" on public.hikes for update to authenticated
  using (public.is_allowed() and (data->>'owner' = public.me() or jsonb_exists(coalesce(data->'members', '[]'::jsonb), public.me())))
  with check (public.is_allowed() and (data->>'owner' = public.me() or jsonb_exists(coalesce(data->'members', '[]'::jsonb), public.me())));
create policy "hikes suppression" on public.hikes for delete to authenticated
  using (public.is_allowed() and data->>'owner' = public.me());

-- 3. Rejoindre une sortie avec le lien d'invitation (autorise aussi l'adresse de l'invité)
create or replace function public.join_hike(hid text, tok text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare r public.hikes%rowtype; m text := public.me();
begin
  if m = '' then raise exception 'non connecté'; end if;
  select * into r from public.hikes
    where id = hid and tok is not null and data->>'joinToken' = tok;
  if not found then raise exception 'invitation invalide' using errcode = 'P0002'; end if;
  insert into public.allowed_emails (email) values (m) on conflict do nothing;
  if r.data->>'owner' <> m and not jsonb_exists(coalesce(r.data->'members', '[]'::jsonb), m) then
    update public.hikes
      set data = jsonb_set(data, '{members}', coalesce(data->'members', '[]'::jsonb) || to_jsonb(m)),
          updated_at = now()
      where id = hid;
  end if;
end;
$$;
revoke all on function public.join_hike(text, text) from public;
grant execute on function public.join_hike(text, text) to authenticated;

-- 4. Quitter une sortie
create or replace function public.leave_hike(hid text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare m text := public.me();
begin
  update public.hikes
    set data = jsonb_set(data, '{members}',
          coalesce((select jsonb_agg(x) from jsonb_array_elements(coalesce(data->'members', '[]'::jsonb)) x where x #>> '{}' <> m), '[]'::jsonb)),
        updated_at = now()
    where id = hid;
end;
$$;
revoke all on function public.leave_hike(text) from public;
grant execute on function public.leave_hike(text) to authenticated;
