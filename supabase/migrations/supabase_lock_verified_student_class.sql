-- ==============================================================================
-- 🏫 SNAPAN MARKET MOBILE — PENGUNCIAN KELAS SISWA TERVERIFIKASI NIS
-- 1. Mengunci class_group pada public.profiles agar tidak bisa diubah secara bebas
--    oleh siswa jika akun sudah memiliki NIS resmi dari student_registry.
-- 2. Sinkronkan profil yang sudah ada agar sesuai dengan kelas resmi di buku induk.
-- ==============================================================================

-- 1. Sinkronisasi data profil yang ada ke kelas resmi buku induk
update public.profiles p
set class_group = sr.class_group
from public.student_registry sr
where p.nis = sr.nis
  and sr.class_group is not null
  and (p.class_group is distinct from sr.class_group);

-- 2. Fungsi trigger untuk memproteksi kolom class_group pada profil ber-NIS
create or replace function public.fn_lock_verified_student_class()
returns trigger as $$
declare
  v_official_class text;
begin
  -- Jika profil memiliki NIS dan class_group berusaha diubah
  if new.nis is not null and (old.class_group is distinct from new.class_group) then
    -- Ambil kelas resmi dari student_registry
    select class_group into v_official_class
    from public.student_registry
    where nis = new.nis
    limit 1;

    -- Jika siswa mencoba mengubah ke kelas yang berbeda dari buku induk
    if v_official_class is not null and new.class_group <> v_official_class then
      -- Kecuali jika aksi dilakukan oleh administrator resmi
      if not public.is_admin() then
        -- Paksa nilai class_group tetap ke kelas resmi buku induk
        new.class_group := v_official_class;
      end if;
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- 3. Pasang trigger sebelum update pada tabel profiles
drop trigger if exists trg_lock_verified_student_class on public.profiles;
create trigger trg_lock_verified_student_class
  before update on public.profiles
  for each row
  execute function public.fn_lock_verified_student_class();

-- Reload cache schema PostgREST
notify pgrst, 'reload schema';
