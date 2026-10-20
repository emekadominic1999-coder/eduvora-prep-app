-- =============================================================================
-- Eduvora Prep — Supabase schema
-- =============================================================================
-- Run this once (via `supabase db push` or the SQL editor) against the
-- project this app is wired to. It creates every table the portal needs,
-- enables Row Level Security everywhere, and wires up the auto-profile
-- trigger used by both email and Google sign-in.
--
-- Unlike Eduvora, this backend is required — the app is signed-in-only, so
-- every table below assumes `auth.uid()` is always present for a normal user.
-- =============================================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------------ profiles
-- One row per student, keyed to auth.users. Mirrors core/models/student.dart.
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default '',
  email       text not null default '',
  avatar_url  text,
  class_level text not null default 'ss3'
                check (class_level in ('ss1', 'ss2', 'ss3', 'graduate')),
  target_body text not null default 'JAMB'
                check (target_body in ('JAMB', 'WAEC', 'NECO', 'POST-UTME')),
  subject_ids text[] not null default array['english']::text[],
  exam_date   date,
  onboarded   boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists profiles_target_body_idx on public.profiles (target_body);

alter table public.profiles enable row level security;

drop policy if exists "profiles are readable by their owner" on public.profiles;
create policy "profiles are readable by their owner"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "students manage their own profile" on public.profiles;
create policy "students manage their own profile"
  on public.profiles for all
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Create a profile row automatically on signup, including via Google OAuth,
-- so the app never has to handle a missing row.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name',
             new.raw_user_meta_data ->> 'name',
             split_part(coalesce(new.email, ''), '@', 1)),
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------------ attempts
-- One row per finished CBT session. Mirrors core/models/exam.dart AttemptRecord.
create table if not exists public.attempts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  paper_id      text not null,
  body_code     text not null,
  subject_id    text not null,
  year          int not null,
  label         text not null default '',
  mode          text not null default 'exam' check (mode in ('exam', 'study')),
  correct       int not null default 0,
  total         int not null default 0,
  seconds_used  int not null default 0,
  taken_at      timestamptz not null default now(),
  topic_scores  jsonb not null default '{}'::jsonb
);

create index if not exists attempts_user_idx on public.attempts (user_id, taken_at desc);
create index if not exists attempts_subject_idx on public.attempts (user_id, subject_id);

alter table public.attempts enable row level security;

drop policy if exists "students manage their own attempts" on public.attempts;
create policy "students manage their own attempts"
  on public.attempts for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ----------------------------------------------------------------- bookmarks
create table if not exists public.bookmarks (
  user_id     uuid not null references auth.users (id) on delete cascade,
  question_id text not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, question_id)
);

alter table public.bookmarks enable row level security;

drop policy if exists "students manage their own bookmarks" on public.bookmarks;
create policy "students manage their own bookmarks"
  on public.bookmarks for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------- news_items
-- Editorially managed exam news (results, admissions, timetables). Readable
-- by every signed-in student; writable only via the service role (i.e. from
-- the Supabase dashboard or a future admin tool), never from the client, so
-- the feed cannot be spammed or used to spread misinformation.
create table if not exists public.news_items (
  id            uuid primary key default gen_random_uuid(),
  category      text not null default 'General News',
  title         text not null,
  summary       text not null default '',
  body          text not null default '',
  source_label  text not null default '',
  source_url    text,
  published_at  timestamptz not null default now(),
  created_at    timestamptz not null default now()
);

create index if not exists news_items_published_idx on public.news_items (published_at desc);
create index if not exists news_items_category_idx on public.news_items (category);

alter table public.news_items enable row level security;

drop policy if exists "news is readable by signed-in students" on public.news_items;
create policy "news is readable by signed-in students"
  on public.news_items for select
  to authenticated
  using (true);

-- No insert/update/delete policy for `authenticated` is intentional: content
-- is added via the service role only.

-- --------------------------------------------------------------- scholarships
create table if not exists public.scholarships (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  degree_level  text not null default '' ,
  country       text not null default '',
  deadline      date,
  description   text not null default '',
  link          text,
  created_at    timestamptz not null default now()
);

create index if not exists scholarships_deadline_idx on public.scholarships (deadline);

alter table public.scholarships enable row level security;

drop policy if exists "scholarships are readable by signed-in students" on public.scholarships;
create policy "scholarships are readable by signed-in students"
  on public.scholarships for select
  to authenticated
  using (true);

-- ------------------------------------------------------------- forum tables
-- "School-based questions" and "academic questions", matching myschool.ng's
-- forum split. Anyone signed in can read; only the author may edit or delete
-- their own post.
create table if not exists public.forum_questions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  category    text not null default 'academic'
                check (category in ('school', 'academic')),
  title       text not null,
  body        text not null default '',
  created_at  timestamptz not null default now()
);

create index if not exists forum_questions_category_idx on public.forum_questions (category, created_at desc);

alter table public.forum_questions enable row level security;

drop policy if exists "forum questions are readable by signed-in students" on public.forum_questions;
create policy "forum questions are readable by signed-in students"
  on public.forum_questions for select
  to authenticated
  using (true);

drop policy if exists "students post their own forum questions" on public.forum_questions;
create policy "students post their own forum questions"
  on public.forum_questions for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "students manage their own forum questions" on public.forum_questions;
create policy "students manage their own forum questions"
  on public.forum_questions for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "students delete their own forum questions" on public.forum_questions;
create policy "students delete their own forum questions"
  on public.forum_questions for delete
  to authenticated
  using (auth.uid() = user_id);

create table if not exists public.forum_answers (
  id          uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.forum_questions (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  body        text not null,
  created_at  timestamptz not null default now()
);

create index if not exists forum_answers_question_idx on public.forum_answers (question_id, created_at);

alter table public.forum_answers enable row level security;

drop policy if exists "forum answers are readable by signed-in students" on public.forum_answers;
create policy "forum answers are readable by signed-in students"
  on public.forum_answers for select
  to authenticated
  using (true);

drop policy if exists "students post their own forum answers" on public.forum_answers;
create policy "students post their own forum answers"
  on public.forum_answers for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "students manage their own forum answers" on public.forum_answers;
create policy "students manage their own forum answers"
  on public.forum_answers for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "students delete their own forum answers" on public.forum_answers;
create policy "students delete their own forum answers"
  on public.forum_answers for delete
  to authenticated
  using (auth.uid() = user_id);

-- ---------------------------------------------------------- marketplace
create table if not exists public.marketplace_listings (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  title        text not null,
  description  text not null default '',
  price_naira  numeric(12, 2) not null default 0,
  category     text not null default 'other',
  location     text not null default '',
  contact_info text not null default '',
  image_url    text,
  status       text not null default 'active' check (status in ('active', 'sold')),
  created_at   timestamptz not null default now()
);

create index if not exists marketplace_listings_status_idx on public.marketplace_listings (status, created_at desc);

alter table public.marketplace_listings enable row level security;

drop policy if exists "listings are readable by signed-in students" on public.marketplace_listings;
create policy "listings are readable by signed-in students"
  on public.marketplace_listings for select
  to authenticated
  using (true);

drop policy if exists "students post their own listings" on public.marketplace_listings;
create policy "students post their own listings"
  on public.marketplace_listings for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "students manage their own listings" on public.marketplace_listings;
create policy "students manage their own listings"
  on public.marketplace_listings for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "students delete their own listings" on public.marketplace_listings;
create policy "students delete their own listings"
  on public.marketplace_listings for delete
  to authenticated
  using (auth.uid() = user_id);

-- -------------------------------------------------------------- video_lessons
-- Catalogue only for now — no payment is wired up yet, so `video_url` stays
-- null until a Paystack/Flutterwave integration is added. Admin-managed, like
-- news_items.
create table if not exists public.video_lessons (
  id             uuid primary key default gen_random_uuid(),
  subject_id     text not null default '',
  title          text not null,
  description    text not null default '',
  price_naira    numeric(12, 2) not null default 0,
  thumbnail_url  text,
  video_url      text,
  created_at     timestamptz not null default now()
);

create index if not exists video_lessons_subject_idx on public.video_lessons (subject_id);

alter table public.video_lessons enable row level security;

drop policy if exists "video lessons are readable by signed-in students" on public.video_lessons;
create policy "video lessons are readable by signed-in students"
  on public.video_lessons for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------- storage
insert into storage.buckets (id, name, public)
values ('marketplace-images', 'marketplace-images', true)
on conflict (id) do nothing;

drop policy if exists "marketplace images are publicly readable" on storage.objects;
create policy "marketplace images are publicly readable"
  on storage.objects for select
  to public
  using (bucket_id = 'marketplace-images');

drop policy if exists "signed-in students upload marketplace images" on storage.objects;
create policy "signed-in students upload marketplace images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'marketplace-images');

drop policy if exists "students manage their own marketplace images" on storage.objects;
create policy "students manage their own marketplace images"
  on storage.objects for all
  to authenticated
  using (bucket_id = 'marketplace-images' and owner = auth.uid())
  with check (bucket_id = 'marketplace-images' and owner = auth.uid());

-- -------------------------------------------------------------------- seed
-- Clearly-labelled example rows so the News, Scholarships and Store tabs are
-- never empty in a fresh install. These are placeholders, not real current
-- announcements — replace them with genuine content before relying on this
-- feed for real exam dates or deadlines.
insert into public.news_items (category, title, summary, body, source_label, published_at)
select * from (values
  ('General News', 'Example: Welcome to Eduvora Prep News',
   'This is a placeholder story. Real exam news goes here once added from the dashboard.',
   'This feed is editorially managed — students cannot post to it, which keeps it free of rumours. Add real, verified JAMB/WAEC/NECO updates here as they are confirmed.',
   'Eduvora Prep', now()),
  ('JAMB News', 'Example: How UTME results are typically released',
   'Illustrative only — check JAMB''s official channels for real dates.',
   'JAMB historically releases UTME results within two to three weeks of the exam. Replace this placeholder with the confirmed date once announced.',
   'Eduvora Prep', now())
) as seed(category, title, summary, body, source_label, published_at)
where not exists (select 1 from public.news_items);

insert into public.scholarships (title, degree_level, country, deadline, description, link)
select * from (values
  ('Example: Undergraduate Merit Scholarship', 'Undergraduate', 'Nigeria', null::date,
   'Placeholder entry. Replace with a real, verified scholarship listing and its actual deadline.',
   null)
) as seed(title, degree_level, country, deadline, description, link)
where not exists (select 1 from public.scholarships);

-- -------------------------------------------------------------- feed views
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
