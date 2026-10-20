#!/usr/bin/env bash
# =============================================================================
# SIMULATOR PESAN DM UNTUK PENGUJIAN NOTIFIKASI DENGAN 1 HP FISIK
# =============================================================================
# Penggunaan:
#   ./scripts/simulate_incoming_dm.sh [target_username] [pesan]
# Contoh:
#   ./scripts/simulate_incoming_dm.sh radityaray "Halo Ray! Ini pesan uji coba."
# =============================================================================

set -e

SUPABASE_URL="https://lcwsxldnoqjdfqxqcqja.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxjd3N4bGRub3FqZGZxeHFjcWphIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NjA1NjEwNCwiZXhwIjoyMTAxNjMyMTA0fQ.Hb48YZ42zA7aOjVbE2a2E8XvplchlGLwJGYmyAh8Tuw"

TARGET_USERNAME="${1:-radityaray}"
MESSAGE_TEXT="${2:-Halo! Ini simulasi pesan masuk saat HP terkunci.}"

echo "=========================================================="
echo "Simulasi Pengiriman Pesan DM ke @${TARGET_USERNAME}"
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

echo "Penerima      : @${TARGET_USERNAME} (${RECIPIENT_NAME}) [${RECIPIENT_ID}]"

# 2. Cari percakapan aktif yang melibatkan penerima
CONV_JSON=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/conversations?or=(participant_one.eq.${RECIPIENT_ID},participant_two.eq.${RECIPIENT_ID})&select=id,participant_one,participant_two&limit=1" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}")

CONV_ID=$(echo "$CONV_JSON" | grep -o '"id":"[^"]*' | head -n 1 | cut -d'"' -f4)
P1=$(echo "$CONV_JSON" | grep -o '"participant_one":"[^"]*' | head -n 1 | cut -d'"' -f4)
P2=$(echo "$CONV_JSON" | grep -o '"participant_two":"[^"]*' | head -n 1 | cut -d'"' -f4)

if [ -z "$CONV_ID" ]; then
  echo "Error: Belum ada percakapan untuk @${TARGET_USERNAME}."
  exit 1
fi

# Tentukan pengirim (lawan bicara)
if [ "$P1" = "$RECIPIENT_ID" ]; then
  SENDER_ID="$P2"
else
  SENDER_ID="$P1"
fi

echo "Percakapan ID : ${CONV_ID}"
echo "Pengirim (Lawan): ${SENDER_ID}"
echo "Isi Pesan     : \"${MESSAGE_TEXT}\""
echo "----------------------------------------------------------"
echo "Menyuntikkan pesan ke tabel direct_messages..."

# 3. Insert pesan ke direct_messages (otomatis memicu trigger -> Edge Function -> FCM)
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
  echo "Pesan ID      : ${MSG_ID}"
  echo "Status        : BERHASIL DISUNTIKKAN KE SUPABASE!"
  echo "----------------------------------------------------------"
  echo "Edge Function send-dm-push otomatis menembak FCM ke HP @${TARGET_USERNAME}."
  echo "Periksa layar HP fisik Anda sekarang!"
  echo "=========================================================="
else
  echo "Respon gagal: ${INSERT_RES}"
fi
