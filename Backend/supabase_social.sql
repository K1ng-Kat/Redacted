-- REDACTED Social Network v1 — independent of iCloud/CloudKit.
-- Apply to Supabase SQL Editor AFTER enabling Authentication > Anonymous Sign-ins.
-- App uses ONLY public publishable key + per-user Auth JWT, never service_role.
-- RLS protects tables; only these validated SECURITY DEFINER RPC functions
-- are exposed. There are NO chat messages, public username searches or feeds.

create extension if not exists pgcrypto;

create table if not exists public.rd_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  code varchar(8) not null unique check (code ~ '^[A-F0-9]{8}$'),
  alias varchar(22) not null,
  last_seen timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists rd_profiles_last_seen on public.rd_profiles(last_seen);

create table if not exists public.rd_friend_requests (
  id bigint generated always as identity primary key,
  sender uuid not null references public.rd_profiles(user_id) on delete cascade,
  recipient uuid not null references public.rd_profiles(user_id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  constraint rd_requests_not_self check (sender <> recipient),
  unique(sender, recipient)
);
create index if not exists rd_requests_to on public.rd_friend_requests(recipient, status);

create table if not exists public.rd_friendships (
  member_a uuid not null references public.rd_profiles(user_id) on delete cascade,
  member_b uuid not null references public.rd_profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (member_a, member_b),
  constraint rd_friends_canonical check (member_a < member_b)
);

create table if not exists public.rd_task_forces (
  id uuid primary key default gen_random_uuid(),
  code varchar(8) not null unique check (code ~ '^[A-F0-9]{8}$'),
  name varchar(32) not null check (length(trim(name)) between 3 and 32),
  owner_id uuid not null references public.rd_profiles(user_id),
  created_at timestamptz not null default now()
);
create table if not exists public.rd_task_force_members (
  task_force_id uuid not null references public.rd_task_forces(id) on delete cascade,
  user_id uuid not null unique references public.rd_profiles(user_id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key(task_force_id,user_id)
);
create index if not exists rd_force_members_order on public.rd_task_force_members(task_force_id, joined_at);

-- Deny all direct client CRUD, even for signed-in anonymous accounts.
alter table public.rd_profiles enable row level security;
alter table public.rd_friend_requests enable row level security;
alter table public.rd_friendships enable row level security;
alter table public.rd_task_forces enable row level security;
alter table public.rd_task_force_members enable row level security;
revoke all on public.rd_profiles, public.rd_friend_requests, public.rd_friendships,
 public.rd_task_forces, public.rd_task_force_members from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;

-- Each function validates auth.uid and its own access constraints.
-- Fixed search_path and fully qualified tables prevent object injection.
create or replace function public.rd_social_bootstrap() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  code_text text;
  i integer;
begin
  if me is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.rd_profiles where user_id = me) then
    for i in 1..8 loop
      code_text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
      insert into public.rd_profiles(user_id,code,alias,last_seen)
        values(me,code_text,'AGENT-'||right(code_text,4),now())
      on conflict do nothing;
      exit when exists(select 1 from public.rd_profiles where user_id = me);
    end loop;
  end if;
  if not exists(select 1 from public.rd_profiles where user_id = me) then
    raise exception 'Could not allocate detective code'; end if;
  return jsonb_build_object('ok',true);
end $$;

create or replace function public.rd_social_heartbeat() returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  update public.rd_profiles set last_seen = now() where user_id = auth.uid();
  return jsonb_build_object('ok',found);
end $$;

create or replace function public.rd_social_snapshot() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  person public.rd_profiles%rowtype;
  squad public.rd_task_forces%rowtype;
  friends jsonb;
  pending jsonb;
  group_members jsonb;
  group_json jsonb := 'null'::jsonb;
begin
  if me is null then raise exception 'Authentication required'; end if;
  select * into person from public.rd_profiles where user_id=me;
  if not found then raise exception 'Initialize account first'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'code',p.code,'alias',p.alias,'lastSeen',p.last_seen)
      order by p.alias), '[]'::jsonb) into friends
  from public.rd_friendships f
  join public.rd_profiles p
    on p.user_id = case when f.member_a=me then f.member_b else f.member_a end
  where f.member_a=me or f.member_b=me;

  select coalesce(jsonb_agg(jsonb_build_object(
      'id',r.id,'code',p.code,'alias',p.alias)
      order by r.created_at desc), '[]'::jsonb) into pending
  from public.rd_friend_requests r
  join public.rd_profiles p on p.user_id=r.sender
  where r.recipient=me and r.status='pending';

  select t.* into squad from public.rd_task_forces t
    join public.rd_task_force_members m on m.task_force_id=t.id
    where m.user_id=me limit 1;
  if found then
    select coalesce(jsonb_agg(jsonb_build_object(
      'code',p.code,'alias',p.alias,'lastSeen',p.last_seen,
      'leader',p.user_id=squad.owner_id)
      order by (p.user_id=squad.owner_id) desc, p.alias), '[]'::jsonb)
      into group_members
    from public.rd_task_force_members m
    join public.rd_profiles p on p.user_id=m.user_id
    where m.task_force_id=squad.id;
    group_json := jsonb_build_object('id',squad.id,'code',squad.code,
      'name',squad.name,'isLeader',squad.owner_id=me,'members',group_members);
  end if;

  return jsonb_build_object('code',person.code,'alias',person.alias,
    'friends',friends,'requests',pending,'taskForce',group_json);
end $$;

create or replace function public.rd_social_send_request(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
 me uuid := auth.uid();
 target uuid;
begin
 if me is null then raise exception 'Authentication required'; end if;
 select user_id into target from public.rd_profiles where code=upper(trim(p_code));
 if target is null then raise exception 'Detective code not found'; end if;
 if target=me then raise exception 'You cannot add yourself'; end if;
 if exists(select 1 from public.rd_friendships
           where member_a=least(me,target) and member_b=greatest(me,target))
   then raise exception 'Already friends'; end if;
 if (select count(*) from public.rd_friendships where member_a=me or member_b=me)>=50
   then raise exception 'Friend list is full (50)'; end if;
 if (select count(*) from public.rd_friend_requests
     where sender=me and status='pending')>=20
   then raise exception 'Too many pending invites'; end if;
 insert into public.rd_friend_requests(sender,recipient)
 values(me,target)
 on conflict(sender,recipient) do update
    set status='pending', created_at=now();
 return jsonb_build_object('message','Friend request sent');
end $$;

create or replace function public.rd_social_respond_request(p_id bigint,p_accept boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 me uuid := auth.uid();
 req public.rd_friend_requests%rowtype;
begin
 if me is null then raise exception 'Authentication required'; end if;
 select * into req from public.rd_friend_requests
 where id=p_id and recipient=me and status='pending' for update;
 if not found then raise exception 'Request not found'; end if;
 if p_accept then
    if (select count(*) from public.rd_friendships
        where member_a=me or member_b=me)>=50
      then raise exception 'Friend list is full (50)'; end if;
    insert into public.rd_friendships(member_a,member_b)
      values(least(me,req.sender),greatest(me,req.sender))
      on conflict do nothing;
 end if;
 update public.rd_friend_requests
    set status=case when p_accept then 'accepted' else 'declined' end
    where id=req.id;
 return jsonb_build_object('message',case when p_accept then 'Friend added'
                                                    else 'Request declined' end);
end $$;

create or replace function public.rd_social_remove_friend(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
 me uuid := auth.uid();
 target uuid;
begin
 if me is null then raise exception 'Authentication required'; end if;
 select user_id into target from public.rd_profiles where code=upper(trim(p_code));
 if target is null then raise exception 'Detective code not found'; end if;
 delete from public.rd_friendships where member_a=least(me,target)
                                   and member_b=greatest(me,target);
 return jsonb_build_object('message','Friend removed');
end $$;

create or replace function public.rd_task_force_create(p_name text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
 me uuid := auth.uid();
 team_id uuid;
 code_text text;
 cleaned text := trim(p_name);
 i int;
begin
 if me is null then raise exception 'Authentication required'; end if;
 if length(cleaned) not between 3 and 32 then raise exception 'Name must be 3–32 characters'; end if;
 if exists(select 1 from public.rd_task_force_members where user_id=me)
   then raise exception 'Leave your current Task Force first'; end if;
 for i in 1..8 loop
   code_text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
   insert into public.rd_task_forces(code,name,owner_id)
     values(code_text,cleaned,me)
     on conflict (code) do nothing returning id into team_id;
   exit when team_id is not null;
 end loop;
 if team_id is null then raise exception 'Could not create Task Force'; end if;
 insert into public.rd_task_force_members(task_force_id,user_id)
   values(team_id,me);
 return jsonb_build_object('message','Task Force created');
end $$;

create or replace function public.rd_task_force_join(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
 me uuid := auth.uid();
 team public.rd_task_forces%rowtype;
begin
 if me is null then raise exception 'Authentication required'; end if;
 if exists(select 1 from public.rd_task_force_members where user_id=me)
   then raise exception 'Leave your current Task Force first'; end if;
 select * into team from public.rd_task_forces
   where code=upper(trim(p_code)) for update;
 if not found then raise exception 'Task Force code not found'; end if;
 if (select count(*) from public.rd_task_force_members where task_force_id=team.id)>=20
   then raise exception 'Task Force is full (20 detectives)'; end if;
 insert into public.rd_task_force_members(task_force_id,user_id)
   values(team.id,me);
 return jsonb_build_object('message','Joined Task Force');
end $$;

create or replace function public.rd_task_force_leave() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
 me uuid := auth.uid();
 team_id uuid;
 leader uuid;
 next_leader uuid;
begin
 if me is null then raise exception 'Authentication required'; end if;
 select task_force_id into team_id from public.rd_task_force_members where user_id=me;
 if team_id is null then raise exception 'Not in a Task Force'; end if;
 select owner_id into leader from public.rd_task_forces where id=team_id for update;
 if leader=me then
   select user_id into next_leader from public.rd_task_force_members
      where task_force_id=team_id and user_id<>me
      order by joined_at asc limit 1;
   if next_leader is not null then
      update public.rd_task_forces set owner_id=next_leader where id=team_id;
   else
      delete from public.rd_task_force_members where task_force_id=team_id and user_id=me;
      delete from public.rd_task_forces where id=team_id;
      return jsonb_build_object('message','Task Force closed');
   end if;
 end if;
 delete from public.rd_task_force_members where task_force_id=team_id and user_id=me;
 return jsonb_build_object('message','Left Task Force');
end $$;

revoke all on function public.rd_social_bootstrap() from public;
revoke all on function public.rd_social_heartbeat() from public;
revoke all on function public.rd_social_snapshot() from public;
revoke all on function public.rd_social_send_request(text) from public;
revoke all on function public.rd_social_respond_request(bigint,boolean) from public;
revoke all on function public.rd_social_remove_friend(text) from public;
revoke all on function public.rd_task_force_create(text) from public;
revoke all on function public.rd_task_force_join(text) from public;
revoke all on function public.rd_task_force_leave() from public;

grant execute on function public.rd_social_bootstrap() to authenticated;
grant execute on function public.rd_social_heartbeat() to authenticated;
grant execute on function public.rd_social_snapshot() to authenticated;
grant execute on function public.rd_social_send_request(text) to authenticated;
grant execute on function public.rd_social_respond_request(bigint,boolean) to authenticated;
grant execute on function public.rd_social_remove_friend(text) to authenticated;
grant execute on function public.rd_task_force_create(text) to authenticated;
grant execute on function public.rd_task_force_join(text) to authenticated;
grant execute on function public.rd_task_force_leave() to authenticated;
