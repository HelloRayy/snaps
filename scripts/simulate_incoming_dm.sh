#!/usr/bin/env bash
# =============================================================================
# SIMULATOR PESAN DM UNTUK PENGUJIAN NOTIFIKASI DENGAN 1 HP FISIK
# =============================================================================
# PENTING:
# Skrip ini mengunci pengirim secara MUTLAK ke akun resmi @snaps (ID: d3410370-...)
# Dilarang keras memakai akun siswa/pengguna nyata lain sebagai pengirim tiruan!
# =============================================================================
# Penggunaan:
#   ./scripts/simulate_incoming_dm.sh [target_username] [pesan]
# Contoh:
#   ./scripts/simulate_incoming_dm.sh radityaray "Halo Ray! Ini pesan uji coba."
# =============================================================================

set -e

SUPABASE_URL="${SUPABASE_URL:-https://lcwsxldnoqjdfqxqcqja.supabase.co}"

# Baca SERVICE_ROLE_KEY dari environment variable atau .env.local (jangan di-hardcode)
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"
if [ -z "$SERVICE_ROLE_KEY" ] && [ -f .env.local ]; then
  SERVICE_ROLE_KEY=$(grep -E "^SUPABASE_SERVICE_ROLE_KEY=" .env.local | cut -d '=' -f2- | tr -d '"'\'' ' || true)
fi

if [ -z "$SERVICE_ROLE_KEY" ]; then
  echo "Error: Variabel lingkungan SUPABASE_SERVICE_ROLE_KEY belum disetel atau .env.local tidak ditemukan!"
  echo "Silakan export SUPABASE_SERVICE_ROLE_KEY='<token>' sebelum menjalankan skrip ini."
  exit 1
fi

# Akun resmi sistem @snaps sebagai pengirim tunggal yang diizinkan untuk simulasi
SNAPS_SENDER_ID="d3410370-2df1-425d-8c23-3ae980dd5d38"

TARGET_USERNAME="${1:-radityaray}"
MESSAGE_TEXT="${2:-Halo! Ini simulasi pesan masuk dari @snaps.}"

echo "=========================================================="
echo "Simulasi DM Terkunci (@snaps -> @${TARGET_USERNAME})"
echo "=========================================================="

# 1. Cari user_id dari target_username
TARGET_USER_JSON=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/profiles?username=eq.${TARGET_USERNAME}&select=id,username,full_name" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}")

RECIPIENT_ID=$(echo "$TARGET_USER_JSON" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)
RECIPIENT_NAME=$(echo "$TARGET_USER_JSON" | grep -o '"full_name":"[^"]*' | head -n 1 | cut -d'"' -f4)

if [ -z "$RECIPIENT_ID" ]; then
  echo "Error: Akun @${TARGET_USERNAME} tidak ditemukan di database."
  exit 1
fi

echo "Pengirim Resmi: @snaps (Official Snaps System) [${SNAPS_SENDER_ID}]"
echo "Penerima      : @${TARGET_USERNAME} (${RECIPIENT_NAME}) [${RECIPIENT_ID}]"

# 2. Cari percakapan resmi KHUSUS antara @snaps dan penerima
CONV_JSON=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/conversations?or=(and(participant_one.eq.${SNAPS_SENDER_ID},participant_two.eq.${RECIPIENT_ID}),and(participant_one.eq.${RECIPIENT_ID},participant_two.eq.${SNAPS_SENDER_ID}))&select=id&limit=1" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}")

CONV_ID=$(echo "$CONV_JSON" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)

# Jika percakapan resmi belum ada, buat percakapan resmi secara otomatis
if [ -z "$CONV_ID" ]; then
  echo "Membuat ruang percakapan baru antara @snaps dan @${TARGET_USERNAME}..."
  NOW_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  CREATE_CONV_RES=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/conversations" \
    -H "apikey: ${SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{
      \"participant_one\": \"${SNAPS_SENDER_ID}\",
      \"participant_two\": \"${RECIPIENT_ID}\",
      \"last_message_at\": \"${NOW_UTC}\"
    }")
  CONV_ID=$(echo "$CREATE_CONV_RES" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)
fi

if [ -z "$CONV_ID" ]; then
  echo "Error: Gagal mendapatkan atau membuat ID percakapan resmi."
  exit 1
fi

echo "Percakapan ID : ${CONV_ID}"
echo "Isi Pesan     : \"${MESSAGE_TEXT}\""
echo "----------------------------------------------------------"
echo "Menyuntikkan pesan resmi ke tabel direct_messages..."

# 3. Insert pesan ke direct_messages (otomatis memicu trigger -> Edge Function send-dm-push -> FCM)
INSERT_RES=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/direct_messages" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"conversation_id\": \"${CONV_ID}\",
    \"sender_id\": \"${SNAPS_SENDER_ID}\",
    \"message_text\": \"${MESSAGE_TEXT}\",
    \"is_read\": false
  }")

MSG_ID=$(echo "$INSERT_RES" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)

if [ -n "$MSG_ID" ]; then
  echo "Pesan ID      : ${MSG_ID}"
  echo "Status        : BERHASIL DISUNTIKKAN DARI @snaps!"
  echo "----------------------------------------------------------"
  echo "Edge Function send-dm-push otomatis menembak FCM ke HP @${TARGET_USERNAME}."
  echo "Periksa layar HP Anda sekarang!"
  echo "=========================================================="
else
  echo "Respon gagal: ${INSERT_RES}"
  exit 1
fi
