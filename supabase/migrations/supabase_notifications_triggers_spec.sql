-- =========================================================================
-- SNAPS NOTIFICATIONS TRIGGERS SPECIFICATION (DRAFT / PROPOSAL)
-- Multi-action notification dispatch: Comment, Reply, Like, Mention, Follow
-- Target table: public.notifications
-- =========================================================================

-- 1. TRIGGER FUNCTION: Komentar & Balasan Komentar
create or replace function public.tr_fn_notify_post_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_author_id uuid;
  v_parent_author_id uuid;
  v_actor_name text;
  v_preview text;
begin
  -- Ambil nama lengkap / username pengirim komentar
  select coalesce(nullif(full_name, ''), '@' || username, 'Seseorang')
  into v_actor_name
  from public.profiles
  where id = NEW.user_id;

  v_preview := trim(NEW.content);
  if length(v_preview) > 50 then
    v_preview := substring(v_preview from 1 for 47) || '...';
  end if;

  -- A. Jika ini balasan komentar (reply)
  if NEW.parent_comment_id is not null then
    select user_id into v_parent_author_id
    from public.post_comments
    where id = NEW.parent_comment_id;

    -- Notifikasi ke penulis komentar induk jika bukan dirinya sendiri
    if v_parent_author_id is not null and v_parent_author_id <> NEW.user_id then
      insert into public.notifications (
        user_id,
        actor_id,
        type,
        title,
        message,
        post_id,
        action_type,
        action_url,
        is_read
      ) values (
        v_parent_author_id,
        NEW.user_id,
        'comment',
        v_actor_name,
        'membalas komentarmu: "' || v_preview || '"',
        NEW.post_id,
        'post_link',
        NEW.post_id::text,
        false
      );
    end if;
  end if;

  -- B. Notifikasi ke pemilik postingan (post author / seller)
  select seller_id into v_post_author_id
  from public.market_posts
  where id = NEW.post_id;

  -- Kirim ke pemilik postingan jika:
  -- 1. Bukan postingannya sendiri (NEW.user_id <> v_post_author_id)
  -- 2. Bukan orang yang sama dengan penerima notifikasi reply di atas
  if v_post_author_id is not null 
     and v_post_author_id <> NEW.user_id 
     and (v_parent_author_id is null or v_post_author_id <> v_parent_author_id) then
    insert into public.notifications (
      user_id,
      actor_id,
      type,
      title,
      message,
      post_id,
      action_type,
      action_url,
      is_read
    ) values (
      v_post_author_id,
      NEW.user_id,
      'comment',
      v_actor_name,
      'mengomentari postinganmu: "' || v_preview || '"',
      NEW.post_id,
      'post_link',
      NEW.post_id::text,
      false
    );
  end if;

  return NEW;
end;
$$;


-- 2. TRIGGER FUNCTION: Like Postingan
create or replace function public.tr_fn_notify_post_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_author_id uuid;
  v_actor_name text;
begin
  -- Ambil pemilik postingan
  select seller_id into v_post_author_id
  from public.market_posts
  where id = NEW.post_id;

  -- Cegah kirim notifikasi jika menyukai postingan sendiri
  if v_post_author_id is null or v_post_author_id = NEW.user_id then
    return NEW;
  end if;

  -- Deduplikasi: Jangan buat duplikat jika ada notifikasi like yang belum dibaca dalam 2 jam terakhir
  if exists (
    select 1 from public.notifications
    where user_id = v_post_author_id
      and actor_id = NEW.user_id
      and post_id = NEW.post_id
      and type = 'like'
      and created_at > timezone('utc'::text, now()) - interval '2 hours'
  ) then
    return NEW;
  end if;

  select coalesce(nullif(full_name, ''), '@' || username, 'Seseorang')
  into v_actor_name
  from public.profiles
  where id = NEW.user_id;

  insert into public.notifications (
    user_id,
    actor_id,
    type,
    title,
    message,
    post_id,
    action_type,
    action_url,
    is_read
  ) values (
    v_post_author_id,
    NEW.user_id,
    'like',
    v_actor_name,
    'menyukai postinganmu',
    NEW.post_id,
    'post_link',
    NEW.post_id::text,
    false
  );

  return NEW;
end;
$$;


-- 3. TRIGGER FUNCTION: Follow Pengguna
create or replace function public.tr_fn_notify_user_follow()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_name text;
  v_actor_username text;
begin
  if NEW.follower_id = NEW.following_id then
    return NEW;
  end if;

  select coalesce(nullif(full_name, ''), '@' || username, 'Seseorang'), username
  into v_actor_name, v_actor_username
  from public.profiles
  where id = NEW.follower_id;

  insert into public.notifications (
    user_id,
    actor_id,
    type,
    title,
    message,
    action_type,
    action_url,
    is_read
  ) values (
    NEW.following_id,
    NEW.follower_id,
    'follow',
    v_actor_name,
    'mulai mengikuti kamu',
    'user_profile',
    coalesce(v_actor_username, ''),
    false
  );

  return NEW;
end;
$$;


-- 4. TRIGGER FUNCTION: Mention (@username) di Komentar atau Post
create or replace function public.tr_fn_notify_mentions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_content text;
  v_post_id uuid;
  v_actor_id uuid;
  v_actor_name text;
  v_matches text[];
  v_target_username text;
  v_target_user_id uuid;
  v_is_post boolean;
begin
  if TG_TABLE_NAME = 'market_posts' then
    v_content := coalesce(NEW.description, '');
    v_post_id := NEW.id;
    v_actor_id := NEW.seller_id;
    v_is_post := true;
  else
    v_content := coalesce(NEW.content, '');
    v_post_id := NEW.post_id;
    v_actor_id := NEW.user_id;
    v_is_post := false;
  end if;

  if v_content is null or position('@' in v_content) = 0 then
    return NEW;
  end if;

  select coalesce(nullif(full_name, ''), '@' || username, 'Seseorang')
  into v_actor_name
  from public.profiles
  where id = v_actor_id;

  -- Cari seluruh @username unik di dalam teks
  for v_target_username in
    select distinct lower(m[1])
    from regexp_matches(v_content, '@([a-zA-Z0-9_.]+)', 'g') as m
  loop
    select id into v_target_user_id
    from public.profiles
    where lower(username) = v_target_username;

    -- Kirim notifikasi jika user ditemukan dan bukan menyebut diri sendiri
    if v_target_user_id is not null and v_target_user_id <> v_actor_id then
      insert into public.notifications (
        user_id,
        actor_id,
        type,
        title,
        message,
        post_id,
        action_type,
        action_url,
        is_read
      ) values (
        v_target_user_id,
        v_actor_id,
        'mention',
        v_actor_name,
        case 
          when v_is_post then 'menyebut kamu dalam postingan baru'
          else 'menyebut kamu dalam sebuah komentar'
        end,
        v_post_id,
        'post_link',
        v_post_id::text,
        false
      );
    end if;
  end loop;

  return NEW;
end;
$$;


-- 5. ATTACH TRIGGERS
drop trigger if exists tr_post_comments_notify on public.post_comments;
create trigger tr_post_comments_notify
after insert on public.post_comments
for each row execute function public.tr_fn_notify_post_comment();

drop trigger if exists tr_post_likes_notify on public.post_likes;
create trigger tr_post_likes_notify
after insert on public.post_likes
for each row execute function public.tr_fn_notify_post_like();

drop trigger if exists tr_user_follows_notify on public.user_follows;
create trigger tr_user_follows_notify
after insert on public.user_follows
for each row execute function public.tr_fn_notify_user_follow();

drop trigger if exists tr_post_comments_mention_notify on public.post_comments;
create trigger tr_post_comments_mention_notify
after insert on public.post_comments
for each row execute function public.tr_fn_notify_mentions();

drop trigger if exists tr_market_posts_mention_notify on public.market_posts;
create trigger tr_market_posts_mention_notify
after insert on public.market_posts
for each row execute function public.tr_fn_notify_mentions();
