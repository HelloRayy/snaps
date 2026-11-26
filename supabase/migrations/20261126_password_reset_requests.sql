-- Migration: In-App Password Reset Requests (Ticket 4)
CREATE TABLE IF NOT EXISTS public.password_reset_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nis text NOT NULL,
  full_name text NOT NULL,
  class_group text NOT NULL,
  notes text,
  device_fcm_token text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  temp_password text,
  admin_note text,
  processed_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_password_reset_requests_nis_status
  ON public.password_reset_requests (nis, status, created_at DESC);

ALTER TABLE public.password_reset_requests ENABLE ROW LEVEL SECURITY;

-- Allow anyone (including logged-out students) to submit a reset request
CREATE POLICY "Anyone can insert password reset request"
  ON public.password_reset_requests
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (status = 'pending');

-- Allow anyone to check their own request status by NIS
CREATE POLICY "Anyone can read password reset requests"
  ON public.password_reset_requests
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only admins can update (approve/reject) requests
CREATE POLICY "Admins can update password reset requests"
  ON public.password_reset_requests
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND (profiles.role = 'admin' OR profiles.is_admin = true)
    )
  );
