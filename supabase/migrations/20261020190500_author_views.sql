-- Re-point user_id on the community tables at public.profiles instead of
-- auth.users. Every signed-in user already has a profiles row (via the
-- handle_new_user trigger), so this loses nothing, and it lets PostgREST
-- embed the author's name in a single request instead of a client-side
-- second round trip per row.

alter table public.forum_questions
  drop constraint if exists forum_questions_user_id_fkey,
  add constraint forum_questions_user_id_fkey
    foreign key (user_id) references public.profiles (id) on delete cascade;

alter table public.forum_answers
  drop constraint if exists forum_answers_user_id_fkey,
  add constraint forum_answers_user_id_fkey
    foreign key (user_id) references public.profiles (id) on delete cascade;

alter table public.marketplace_listings
  drop constraint if exists marketplace_listings_user_id_fkey,
  add constraint marketplace_listings_user_id_fkey
    foreign key (user_id) references public.profiles (id) on delete cascade;

-- `security_invoker` makes each view enforce RLS as the querying user, not
-- as the view's owner — without it every row would be visible to everyone
-- regardless of the underlying tables' policies.

create or replace view public.forum_questions_feed
  with (security_invoker = true) as
select
  fq.id,
  fq.user_id,
  fq.category,
  fq.title,
  fq.body,
  fq.created_at,
  coalesce(p.full_name, 'A student') as author_name,
  (select count(*) from public.forum_answers fa
    where fa.question_id = fq.id) as answer_count
from public.forum_questions fq
left join public.profiles p on p.id = fq.user_id;

create or replace view public.forum_answers_feed
  with (security_invoker = true) as
select
  fa.id,
  fa.question_id,
  fa.user_id,
  fa.body,
  fa.created_at,
  coalesce(p.full_name, 'A student') as author_name
from public.forum_answers fa
left join public.profiles p on p.id = fa.user_id;

create or replace view public.marketplace_listings_feed
  with (security_invoker = true) as
select
  ml.id,
  ml.user_id,
  ml.title,
  ml.description,
  ml.price_naira,
  ml.category,
  ml.location,
  ml.contact_info,
  ml.image_url,
  ml.status,
  ml.created_at,
  coalesce(p.full_name, 'A student') as seller_name
from public.marketplace_listings ml
left join public.profiles p on p.id = ml.user_id;

grant select on public.forum_questions_feed to authenticated;
grant select on public.forum_answers_feed to authenticated;
grant select on public.marketplace_listings_feed to authenticated;
