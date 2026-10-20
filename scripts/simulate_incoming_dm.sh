#!/usr/bin/env bash
# =============================================================================
# SIMULATOR PESAN DM UNTUK PENGUJIAN NOTIFIKASI DENGAN 1 HP FISIK
# =============================================================================
# Cara kerja:
# Skrip ini menyuntikkan (INSERT) pesan DM baru ke Supabase Database atas nama
# pengguna lain. Ini otomatis memicu Database Trigger -> Edge Function send-dm-push ->
# Google FCM HTTP v1 -> Notifikasi muncul di HP fisik Anda yang sedang terkunci!
# =============================================================================

set -e

SUPABASE_URL="https://lcwsxldnoqjdfqxqcqja.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxjd3N4bGRub3FqZGZxeHFjcWphIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NjA1NjEwNCwiZXhwIjoyMTAxNjMyMTA0fQ.Hb48YZ42zA7aOjVbE2a2E8XvplchlGLwJGYmyAh8Tuw"

MESSAGE_TEXT="${1:-Halo dari terminal! Ini uji coba push notifikasi saat app ditutup.}"

echo "=========================================================="
echo "Simulasi Pengiriman Pesan DM (1-Device Testing Mode)"
echo "=========================================================="

# 1. Ambil 1 percakapan aktif dari database
CONV_JSON=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/conversations?select=id,participant_one,participant_two,participant_one_profile:profiles!conversations_participant_one_fkey(username,full_name),participant_two_profile:profiles!conversations_participant_two_fkey(username,full_name)&limit=1" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}")

CONV_ID=$(echo "$CONV_JSON" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)
SENDER_ID=$(echo "$CONV_JSON" | grep -o '"participant_one":"[^"]*' | head -n 1 | cut -d'"' -f4)
RECIPIENT_ID=$(echo "$CONV_JSON" | grep -o '"participant_two":"[^"]*' | head -n 1 | cut -d'"' -f4)

if [ -z "$CONV_ID" ]; then
  echo "Error: Tidak ditemukan percakapan di database untuk disimulasikan."
  exit 1
fi

echo "Percakapan ID : $CONV_ID"
echo "Pengirim      : $SENDER_ID"
echo "Penerima      : $RECIPIENT_ID"
echo "Isi Pesan     : \"$MESSAGE_TEXT\""
echo "----------------------------------------------------------"
echo "Menyuntikkan pesan ke tabel direct_messages..."

# 2. Insert pesan ke direct_messages (otomatis memicu trigger database)
INSERT_RES=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/direct_messages" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"conversation_id\": \"${CONV_ID}\",
    \"sender_id\": \"${SENDER_ID}\",
    \"message_text\": \"${MESSAGE_TEXT}\",
    \"is_read\": false
  }")

MSG_ID=$(echo "$INSERT_RES" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)

if [ -n "$MSG_ID" ]; then
  echo "Pesan ID      : $MSG_ID"
  echo "Status        : BERHASIL DISUNTIKKAN KE SUPABASE!"
  echo "----------------------------------------------------------"
  echo "Trigger database otomatis memanggil Edge Function send-dm-push."
  echo "Periksa layar HP fisik Anda sekarang (Status bar / Banner)!"
  echo "=========================================================="
else
  echo "Respon: $INSERT_RES"
fi
