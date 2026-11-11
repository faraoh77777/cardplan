-- 똑씀이 v1.31.7: 5만 건 한도 트리거 수정 (Supabase SQL Editor에서 한 번 실행)
-- 문제: 한도 트리거가 BEFORE INSERT라서, 5만 건이 차면 이미 있는 행을 고치는 upsert(INSERT … ON CONFLICT DO UPDATE)까지 막았습니다.
-- 수정: 같은 (user_id, id) 행이 이미 있으면(=고치기) 세지 않고 통과, 새 행일 때만 5만 건을 셉니다. 표·데이터는 바뀌지 않습니다.

create or replace function public.card_plan_records_limit() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.card_plan_records where user_id = new.user_id and id = new.id) then
    return new;
  end if;
  if (select count(*) from public.card_plan_records where user_id = new.user_id) >= 50000 then
    raise exception 'card_plan_records limit 50000';
  end if;
  return new;
end $$;
revoke all on function public.card_plan_records_limit() from public, anon, authenticated;

-- 확인: 기대값 fn_has_exists true / trigger_count 1
select
  (select prosrc like '%exists (select 1 from public.card_plan_records where user_id = new.user_id and id = new.id)%' from pg_proc where proname = 'card_plan_records_limit') as fn_has_exists,
  (select count(*) from pg_trigger where tgname = 'card_plan_records_limit' and not tgisinternal) as trigger_count;
