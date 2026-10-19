-- REDACTED account backup — authenticated, email-code account (no Apple ID).
-- Apply AFTER Backend/supabase_social.sql. This is the account's PRIVATE
-- campaign save. Only server-side, authenticated RPCs may touch the table.

create table if not exists public.rd_account_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision integer not null default 1 check (revision > 0),
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.rd_account_saves enable row level security;
revoke all on public.rd_account_saves from anon, authenticated;

-- NEVER return a global list, never trust a user_id supplied by a client.
create or replace function public.rd_account_save_get()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  saved public.rd_account_saves%rowtype;
begin
  if me is null then raise exception 'Sign in required'; end if;
  select * into saved from public.rd_account_saves where user_id=me;
  if not found then return jsonb_build_object('exists',false,'revision',0); end if;
  return jsonb_build_object('exists',true,'revision',saved.revision,
          'updatedAt',saved.updated_at,'payload',saved.payload);
end $$;

-- Optimistic concurrency prevents another signed-in device from silently
-- losing progress or duplicating spendable currency. Revision 0 creates a
-- brand-new save, never overwrites another account's existing save.
create or replace function public.rd_account_save_put(
  p_payload jsonb, p_expected_revision integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  prior integer;
  next_revision integer;
begin
  if me is null then raise exception 'Sign in required'; end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object'
    or not (p_payload ? 'progress') or not (p_payload ? 'preferences')
    or octet_length(p_payload::text) > 262144
  then raise exception 'Invalid or oversized save'; end if;
  if p_expected_revision < 0 then raise exception 'Invalid revision'; end if;

  select revision into prior from public.rd_account_saves
    where user_id=me for update;

  if prior is null then
    if p_expected_revision <> 0 then
      raise exception 'Save changed on another device. Refresh before trying again';
    end if;
    insert into public.rd_account_saves(user_id,revision,payload)
      values(me,1,p_payload);
    next_revision := 1;
  else
    if prior <> p_expected_revision then
      raise exception 'Save changed on another device. Refresh before trying again';
    end if;
    update public.rd_account_saves
      set revision=revision+1, payload=p_payload, updated_at=now()
      where user_id=me
      returning revision into next_revision;
  end if;
  return jsonb_build_object('revision',next_revision,'success',true);
end $$;

-- Account deletion is an explicit in-app user choice; removes auth.users and
-- Cascades to this account's private saves, codes, friend requests, friends.
-- Reassigns or closes Task Forces first to preserve referential integrity.
create or replace function public.rd_account_delete()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  force_id uuid;
  successor uuid;
begin
  if me is null then raise exception 'Sign in required'; end if;
  for force_id in
    select id from public.rd_task_forces where owner_id=me for update
  loop
    select user_id into successor from public.rd_task_force_members
      where task_force_id=force_id and user_id<>me
      order by joined_at asc limit 1;
    if successor is null then
      delete from public.rd_task_force_members where task_force_id=force_id;
      delete from public.rd_task_forces where id=force_id;
    else
      update public.rd_task_forces set owner_id=successor where id=force_id;
    end if;
  end loop;
  delete from auth.users where id=me;
  return jsonb_build_object('success',true);
end $$;

revoke all on function public.rd_account_save_get() from public;
revoke all on function public.rd_account_save_put(jsonb,integer) from public;
revoke all on function public.rd_account_delete() from public;
grant execute on function public.rd_account_save_get() to authenticated;
grant execute on function public.rd_account_save_put(jsonb,integer) to authenticated;
grant execute on function public.rd_account_delete() to authenticated;
