-- ==============================================================================
-- 🏫 SNAPAN MARKET MOBILE — SINKRONISASI KLAIM NIS DENGAN PROFIL TERDAFTAR
-- Memperbarui kolom is_claimed dan claimed_by pada student_registry untuk profil
-- yang didaftarkan sebelum trigger registrasi otomatis aktif.
-- ==============================================================================

do $$
begin
  if exists (
    select 1 from information_schema.tables 
    where table_schema = 'public' and table_name = 'student_registry'
  ) then
    -- 1. Tandai NIS yang sudah memiliki profil di tabel profiles sebagai is_claimed = true
    update public.student_registry sr
    set is_claimed = true,
        claimed_by = p.id,
        claimed_at = coalesce(sr.claimed_at, p.created_at, timezone('utc'::text, now()))
    from public.profiles p
    where sr.nis = p.nis
      and (sr.is_claimed = false or sr.claimed_by is null);

    -- 2. Sinkronkan kelas profil jika masih kosong atau default
    update public.profiles p
    set class_group = sr.class_group
    from public.student_registry sr
    where p.nis = sr.nis
      and (p.class_group is null or p.class_group = 'Siswa Snapan' or p.class_group = '')
      and sr.class_group is not null;
  end if;
end $$;

-- Reload cache schema PostgREST
notify pgrst, 'reload schema';
