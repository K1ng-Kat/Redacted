-- REDACTED private 1v1 mysteries: passwordless REDACTED ID, no CloudKit.
-- Deploy after supabase_social.sql. No client may read tables directly.
create table if not exists public.rd_duels (
  code varchar(6) primary key check (code ~ '^[A-F0-9]{6}$'),
  host uuid not null references public.rd_profiles(user_id) on delete cascade,
  guest uuid references public.rd_profiles(user_id) on delete cascade,
  seed integer not null check (seed between 0 and 999),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  host_finished_at timestamptz,
  guest_finished_at timestamptz,
  host_emote varchar(20),
  host_emote_at timestamptz,
  guest_emote varchar(20),
  guest_emote_at timestamptz,
  host_wrong integer not null default 0,
  guest_wrong integer not null default 0
);
create index if not exists rd_duels_by_host on public.rd_duels(host,created_at);
create index if not exists rd_duels_by_guest on public.rd_duels(guest,created_at);
alter table public.rd_duels enable row level security;
revoke all on public.rd_duels from anon, authenticated;

create or replace function public.rd_duel_create() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare me uuid := auth.uid(); identifier text; mystery_seed integer;
        iteration int;
begin
 if me is null then raise exception 'Sign in required'; end if;
 if not exists(select 1 from public.rd_profiles where user_id=me) then
   raise exception 'Initialize detective account first'; end if;
 if (select count(*) from public.rd_duels
     where host=me and created_at>now()-interval '10 minutes')>=8
 then raise exception 'Too many rooms; try again later'; end if;
 mystery_seed := floor(random()*1000)::integer;
 for iteration in 1..12 loop
   identifier := upper(substr(encode(gen_random_bytes(4),'hex'),1,6));
   insert into public.rd_duels(code,host,seed)
     values(identifier,me,mystery_seed) on conflict do nothing;
   if found then
     return jsonb_build_object('code',identifier,'seed',mystery_seed);
   end if;
 end loop;
 raise exception 'Could not create room';
end $$;

create or replace function public.rd_duel_join(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare me uuid := auth.uid(); room public.rd_duels%rowtype;
begin
 if me is null then raise exception 'Sign in required'; end if;
 select * into room from public.rd_duels
   where code=upper(trim(p_code)) for update;
 if not found or room.created_at < now()-interval '1 hour' then
   raise exception 'Room not found or expired'; end if;
 if room.host=me then raise exception 'Cannot join your own room'; end if;
 if room.guest is not null then raise exception 'Room is already full'; end if;
 if not exists(select 1 from public.rd_profiles where user_id=me) then
   raise exception 'Initialize detective account first'; end if;
 update public.rd_duels
   set guest=me,started_at=now() where code=room.code;
 return jsonb_build_object('code',room.code,'seed',room.seed,'joined',true);
end $$;

create or replace function public.rd_duel_snapshot(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare me uuid := auth.uid(); room public.rd_duels%rowtype;
        their_alias text; my_finish timestamptz; their_finish timestamptz;
        their_emote text; their_emote_at timestamptz; outcome text;
begin
 if me is null then raise exception 'Sign in required'; end if;
 select * into room from public.rd_duels where code=upper(trim(p_code));
 if not found or (room.host <> me and room.guest is distinct from me) then
   raise exception 'Room unavailable'; end if;
 if room.created_at < now()-interval '1 hour' then
   raise exception 'Room expired'; end if;
 if room.host=me then
   select alias into their_alias from public.rd_profiles where user_id=room.guest;
   my_finish := room.host_finished_at;
   their_finish := room.guest_finished_at;
   their_emote := room.guest_emote;
   their_emote_at := room.guest_emote_at;
 else
   select alias into their_alias from public.rd_profiles where user_id=room.host;
   my_finish := room.guest_finished_at;
   their_finish := room.host_finished_at;
   their_emote := room.host_emote;
   their_emote_at := room.host_emote_at;
 end if;
 if room.guest is null then
   outcome := 'waiting';
 elsif my_finish is not null and
       (their_finish is null or my_finish <= their_finish) then
   outcome := 'won';
 elsif their_finish is not null then
   outcome := 'lost';
 else
   outcome := 'playing';
 end if;
 return jsonb_build_object('code',room.code,'seed',room.seed,
  'phase',outcome,'opponent',coalesce(their_alias,''),
  'opponentEmote',their_emote,'opponentEmoteAt',their_emote_at);
end $$;

-- Answers are validated by the database, not by trusting a "finished" flag.
-- Three steps: index of correctly fitting clue, 3-digit envelope code, culprit.
create or replace function public.rd_duel_finish(
 p_code text, p_evidence integer, p_envelope text, p_suspect integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare me uuid := auth.uid(); room public.rd_duels%rowtype;
        attempts integer; correct_evidence integer; correct_envelope text;
        correct_suspect integer;
begin
 if me is null then raise exception 'Sign in required'; end if;
 select * into room from public.rd_duels
   where code=upper(trim(p_code)) for update;
 if not found or room.guest is null or
   (room.host<>me and room.guest is distinct from me) or
   room.created_at < now()-interval '1 hour'
 then raise exception 'Active room unavailable'; end if;
 if room.host=me and room.host_finished_at is not null then
   return jsonb_build_object('success',true); end if;
 if room.guest=me and room.guest_finished_at is not null then
   return jsonb_build_object('success',true); end if;
 attempts := case when room.host=me then room.host_wrong else room.guest_wrong end;
 if attempts>=4 then raise exception 'No attempts remaining'; end if;
 correct_evidence := (room.seed*7+3)%4;
 correct_envelope := lpad((100+(room.seed*37+51)%900)::text,3,'0');
 correct_suspect := (room.seed*11+1)%4;
 if p_evidence<>correct_evidence or p_envelope<>correct_envelope
    or p_suspect<>correct_suspect then
   if room.host=me then
     update public.rd_duels set host_wrong=host_wrong+1 where code=room.code;
   else
     update public.rd_duels set guest_wrong=guest_wrong+1 where code=room.code;
   end if;
   return jsonb_build_object('success',false); end if;
 if room.host=me then
   update public.rd_duels set host_finished_at=clock_timestamp() where code=room.code;
 else
   update public.rd_duels set guest_finished_at=clock_timestamp() where code=room.code;
 end if;
 return jsonb_build_object('success',true);
end $$;

create or replace function public.rd_duel_emote(p_code text, p_emote text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare me uuid := auth.uid(); room public.rd_duels%rowtype;
        last_sent timestamptz;
begin
 if me is null then raise exception 'Sign in required'; end if;
 if p_emote not in ('gg','wave','clue','brilliant','wow','hurry','thinking','applause')
 then raise exception 'Unknown emote'; end if;
 select * into room from public.rd_duels
   where code=upper(trim(p_code)) for update;
 if not found or room.guest is null or
   (room.host <> me and room.guest is distinct from me) or
   room.host_finished_at is not null or room.guest_finished_at is not null or
   room.created_at < now()-interval '1 hour'
 then raise exception 'Emotes only work in active 1v1 games'; end if;
 last_sent := case when room.host=me then room.host_emote_at else room.guest_emote_at end;
 if last_sent is not null and last_sent > now()-interval '5 seconds'
 then raise exception 'Wait before sending another emote'; end if;
 if room.host=me then
   update public.rd_duels set host_emote=p_emote,host_emote_at=clock_timestamp()
   where code=room.code;
 else
   update public.rd_duels set guest_emote=p_emote,guest_emote_at=clock_timestamp()
   where code=room.code;
 end if;
 return jsonb_build_object('success',true);
end $$;

revoke all on function public.rd_duel_create() from public;
revoke all on function public.rd_duel_join(text) from public;
revoke all on function public.rd_duel_snapshot(text) from public;
revoke all on function public.rd_duel_finish(text,integer,text,integer) from public;
revoke all on function public.rd_duel_emote(text,text) from public;

grant execute on function public.rd_duel_create() to authenticated;
grant execute on function public.rd_duel_join(text) to authenticated;
grant execute on function public.rd_duel_snapshot(text) to authenticated;
grant execute on function public.rd_duel_finish(text,integer,text,integer) to authenticated;
grant execute on function public.rd_duel_emote(text,text) to authenticated;
