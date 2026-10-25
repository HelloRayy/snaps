-- ==============================================================================
-- 🛡️ SNAPS SECURITY AUDIT HARDENING MIGRATION
-- ==============================================================================
-- Migration ini menutup celah keamanan penting:
-- 1. Anti-Privilege Escalation & Anti-Unsuspend Mandiri (public.profiles)
-- 2. Anti-Message Tampering oleh Penerima Pesan (public.direct_messages)
-- 3. Proteksi Manipulasi Master Data Siswa (public.student_registry)
-- 4. Penegakan Kuota Perangkat Fisik Sisi Server (handle_new_user)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PROTEKSI PROFIL PENGGUNA (ANTI-ESKALASI ROLE & UN-SUSPEND MANDIRI)
-- ------------------------------------------------------------------------------
create or replace function public.fn_protect_profile_sensitive_fields()
returns trigger as $$
begin
  -- Kolom sensitif yang HANYA boleh diubah oleh administrator resmi:
  -- - role (mencegah siswa biasa mengangkat diri menjadi admin)
  -- - is_verified (mencegah siswa memberi centang verifikasi sendiri)
  -- - is_suspended, suspended_at, suspended_until, suspend_reason (mencegah bypass sanksi)
  -- - nis (mencegah pembajakan NIS siswa lain)
  if (old.role is distinct from new.role) or
     (old.is_verified is distinct from new.is_verified) or
     (old.is_suspended is distinct from new.is_suspended) or
     (old.suspended_at is distinct from new.suspended_at) or
     (old.suspended_until is distinct from new.suspended_until) or
     (old.suspend_reason is distinct from new.suspend_reason) or
     (old.nis is not null and old.nis is distinct from new.nis) then
    if not public.is_admin() then
      raise exception 'Akses Ditolak: Anda tidak memiliki izin untuk memodifikasi hak akses, status suspensi, atau NIS akun ini.';
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_profile_sensitive_fields on public.profiles;
create trigger trg_protect_profile_sensitive_fields
  before update on public.profiles
  for each row
  execute function public.fn_protect_profile_sensitive_fields();


-- ------------------------------------------------------------------------------
-- 2. PROTEKSI PESAN CHAT (ANTI-MESSAGE TAMPERING OLEH PENERIMA)
-- ------------------------------------------------------------------------------
create or replace function public.fn_protect_direct_message_fields()
returns trigger as $$
begin
  -- Identitas pengirim dan percakapan TIDAK PERNAH boleh diubah setelah pesan dibuat
  if (old.sender_id is distinct from new.sender_id) or (old.conversation_id is distinct from new.conversation_id) then
    raise exception 'Akses Ditolak: Identitas pengirim dan ID percakapan tidak dapat diubah.';
  end if;

  -- Jika bukan pengirim asli yang melakukan update, dia HANYA boleh mengubah kolom 'is_read'
  if auth.uid() is distinct from old.sender_id then
    if (old.message_text is distinct from new.message_text) or
       (old.created_at is distinct from new.created_at) or
       (old.attachment_url is distinct from new.attachment_url) then
      raise exception 'Akses Ditolak: Hanya pengirim asli yang berhak mengubah isi pesan.';
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_direct_message_fields on public.direct_messages;
create trigger trg_protect_direct_message_fields
  before update on public.direct_messages
  for each row
  execute function public.fn_protect_direct_message_fields();


-- ------------------------------------------------------------------------------
-- 3. PROTEKSI MASTER DATA REGISTRI SISWA (ANTI-TAMPERING MASTER SISWA)
-- ------------------------------------------------------------------------------
create or replace function public.fn_protect_student_registry_fields()
returns trigger as $$
begin
  -- Pengguna biasa hanya diizinkan mengklaim (is_claimed = true, claimed_by = auth.uid())
  -- DILARANG mengubah nama lengkap, kelas/jurusan, atau NIS siswa!
  if not public.is_admin() then
    if (old.full_name is distinct from new.full_name) or
       (old.class_group is distinct from new.class_group) or
       (old.nis is distinct from new.nis) then
      raise exception 'Akses Ditolak: Hanya administrator resmi yang dapat mengubah master data registri siswa.';
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_student_registry_fields on public.student_registry;
create trigger trg_protect_student_registry_fields
  before update on public.student_registry
  for each row
  execute function public.fn_protect_student_registry_fields();


-- ------------------------------------------------------------------------------
-- 4. PENEGAKAN SERVER-SIDE KUOTA PERANGKAT FISIK (HANDLE_NEW_USER)
-- ------------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
declare
  v_nis text;
  v_class text;
  v_full_name text;
  v_display_name text;
  v_username text;
  v_avatar text;
  v_bio text;
  v_link text;
  v_device_id text;
  v_device_count int;
begin
  -- Ekstraksi metadata dari raw_user_meta_data
  v_nis := nullif(trim(coalesce(new.raw_user_meta_data->>'nis', '')), '');
  v_class := nullif(trim(coalesce(new.raw_user_meta_data->>'class_group', '')), '');
  v_full_name := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Pengguna Baru');
  v_display_name := nullif(trim(coalesce(new.raw_user_meta_data->>'display_name', '')), '');
  v_username := coalesce(new.raw_user_meta_data->>'username', lower(replace(v_full_name, ' ', '')));
  v_avatar := coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', '');
  v_bio := nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), '');
  v_link := nullif(trim(coalesce(new.raw_user_meta_data->>'link', '')), '');
  v_device_id := nullif(trim(coalesce(new.raw_user_meta_data->>'device_id', '')), '');

  -- A. Validasi Kuota Perangkat Fisik di Sisi Server (Max 3 Akun per HP)
  if v_device_id is not null and exists (
    select 1 from information_schema.tables 
    where table_schema = 'public' and table_name = 'device_registrations'
  ) then
    select count(*) into v_device_count 
    from public.device_registrations 
    where device_id = v_device_id;

    if v_device_count >= 3 then
      raise exception 'Batas kuota pendaftaran tercapai untuk perangkat fisik ini (maksimal 3 akun).';
    end if;

    insert into public.device_registrations (device_id, user_id, username, created_at)
    values (v_device_id, new.id, v_username, timezone('utc'::text, now()))
    on conflict do nothing;
  end if;

  -- B. Jika NIS disertakan, periksa dan klaim ke student_registry
  if v_nis is not null and exists (
    select 1 from information_schema.tables 
    where table_schema = 'public' and table_name = 'student_registry'
  ) then
    select class_group, full_name into v_class, v_full_name
    from public.student_registry
    where nis = v_nis
    limit 1;

    update public.student_registry
    set is_claimed = true,
        claimed_by = new.id,
        claimed_at = timezone('utc'::text, now())
    where nis = v_nis and (is_claimed = false or claimed_by = new.id);
  end if;

  -- C. Fallback kelas jika masih kosong atau bernilai default
  if v_class is null or v_class = '' or lower(v_class) = 'siswa snapan' then
    v_class := coalesce(nullif(trim(new.raw_user_meta_data->>'class_group'), ''), 'Siswa Snapan');
  end if;

  -- D. Simpan record profil publik
  insert into public.profiles (
    id,
    full_name,
    display_name,
    username,
    avatar_url,
    class_group,
    nis,
    bio,
    link
  )
  values (
    new.id,
    v_full_name,
    v_display_name,
    v_username,
    v_avatar,
    v_class,
    v_nis,
    v_bio,
    v_link
  )
  on conflict (id) do update set
    full_name = case 
      when public.profiles.full_name is null or public.profiles.full_name = 'Pengguna Baru' 
      then excluded.full_name else public.profiles.full_name end,
    class_group = case 
      when public.profiles.class_group is null or public.profiles.class_group = 'Siswa Snapan' or public.profiles.class_group = ''
      then excluded.class_group else public.profiles.class_group end,
    nis = coalesce(public.profiles.nis, excluded.nis),
    display_name = coalesce(public.profiles.display_name, excluded.display_name),
    username = coalesce(public.profiles.username, excluded.username),
    avatar_url = case 
      when public.profiles.avatar_url is null or public.profiles.avatar_url = '' 
      then excluded.avatar_url else public.profiles.avatar_url end,
    bio = coalesce(public.profiles.bio, excluded.bio),
    link = coalesce(public.profiles.link, excluded.link);

  return new;
end;
$$ language plpgsql security definer;
