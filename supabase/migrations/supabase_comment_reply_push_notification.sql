-- =========================================================================
-- TIKET 7: NOTIFIKASI KOMENTAR & BALASAN UTAS + FCM PUSH DISPATCH
-- =========================================================================

-- 1. Pastikan ekstensi pg_net tersedia untuk asynchronous HTTP dispatch
create extension if not exists pg_net with schema extensions;

-- 2. Trigger Function: Komentar & Balasan Komentar (Anti-Self-Notif & Anti-Duplikat)
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

drop trigger if exists tr_post_comments_notify on public.post_comments;
create trigger tr_post_comments_notify
after insert on public.post_comments
for each row execute function public.tr_fn_notify_post_comment();

-- 3. Trigger Function: Kirim FCM Push Notification saat row baru masuk ke public.notifications
create or replace function public.trigger_notification_push()
returns trigger
security definer
language plpgsql
as $$
declare
  edge_function_url text;
  payload jsonb;
begin
  payload := jsonb_build_object(
    'record', jsonb_build_object(
      'id', new.id,
      'user_id', new.user_id,
      'actor_id', new.actor_id,
      'type', new.type,
      'title', new.title,
      'message', new.message,
      'post_id', new.post_id,
      'action_type', new.action_type,
      'action_url', new.action_url,
      'created_at', new.created_at
    )
  );

  edge_function_url := 'https://ipshbvtddafgwwrwstxx.supabase.co/functions/v1/send-notification-push';

  perform net.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxjd3N4bGRub3FqZGZxeHFjcWphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYwNTYxMDQsImV4cCI6MjEwMTYzMjEwNH0.fSpOyyIMSk4AUjxTr6N6XB5NCN1l5uy450NuFLefUw0'
    ),
    body := payload,
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    raise warning 'Gagal mentrigger push notifikasi: %', sqlerrm;
    return new;
end;
$$;

drop trigger if exists on_notification_inserted_send_push on public.notifications;
create trigger on_notification_inserted_send_push
after insert on public.notifications
for each row
execute function public.trigger_notification_push();
