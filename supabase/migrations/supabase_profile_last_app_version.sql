-- ========================================================
-- 📱 TAMBAH KOLOM LAST_APP_VERSION PADA TABEL PROFILES
-- Menyimpan versi & build APK yang terpasang di HP masing-masing siswa
-- ========================================================

alter table public.profiles add column if not exists last_app_version text;
create index if not exists idx_profiles_last_app_version on public.profiles(last_app_version);

-- Update status realtime publication untuk profiles jika diperlukan
do $$
begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object or others then null;
end $$;
