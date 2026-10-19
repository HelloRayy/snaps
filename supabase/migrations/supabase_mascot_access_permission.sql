-- Migration: Add can_use_mascot permission column to public.profiles
-- Allows admin to toggle whether a user can use mascot icons (default true).

alter table public.profiles
  add column if not exists can_use_mascot boolean default true;

comment on column public.profiles.can_use_mascot is 'Permission flag determining whether the user can customize and use mascot flair icons. Defaults to true for all users.';
