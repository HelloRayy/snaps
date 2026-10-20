#!/usr/bin/env bash
set -e

PROJECT_REF="lcwsxldnoqjdfqxqcqja"

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
  echo "=========================================================="
  echo "Error: SUPABASE_ACCESS_TOKEN belum diatur di sesi terminal."
  echo "=========================================================="
  echo "Langkah cepat (hanya butuh 30 detik):"
  echo "1. Buka browser: https://supabase.com/dashboard/account/tokens"
  echo "2. Klik 'Generate new token', beri nama 'snaps-cli', lalu copy tokennya."
  echo "3. Jalankan perintah di bawah di terminal:"
  echo ""
  echo "   export SUPABASE_ACCESS_TOKEN=\"sbp_xxxxxxxxxxxx\""
  echo "   ./scripts/deploy_dm_push.sh"
  echo "=========================================================="
  exit 1
fi

echo "[1/3] Mengunggah secret FIREBASE_SERVICE_ACCOUNT ke Supabase..."
./node_modules/.bin/supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat src/admin/firebase-service-account.json)" --project-ref "$PROJECT_REF"

echo "[2/3] Mendeploy Edge Function send-dm-push..."
./node_modules/.bin/supabase functions deploy send-dm-push --project-ref "$PROJECT_REF" --no-verify-jwt

echo "[3/3] Melakukan verifikasi endpoint..."
curl -i -X POST "https://${PROJECT_REF}.supabase.co/functions/v1/send-dm-push" \
  -H "Content-Type: application/json" \
  -d '{"test":true}'

echo ""
echo "=========================================================="
echo "SELESAI: Edge Function send-dm-push aktif!"
echo "=========================================================="
