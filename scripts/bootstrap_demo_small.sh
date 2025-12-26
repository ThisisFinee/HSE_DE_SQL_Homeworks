#!/usr/bin/env bash
set -euo pipefail

ZIP_URL="https://edu.postgrespro.ru/demo_small.zip"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DL_DIR="${ROOT_DIR}/_demo"
ZIP_PATH="${DL_DIR}/demo_small.zip"
LOG_OUT="${ROOT_DIR}/demo.log"
LOG_ERR="${ROOT_DIR}/demo.err"

PG_SERVICE="postgres"
PGUSER="${POSTGRES_USER:-postgres}"
PGPASSWORD="${POSTGRES_PASSWORD:-postgres}"
DB_ENTRY="postgres"

mkdir -p "${DL_DIR}"
rm -f "${ZIP_PATH}" "${DL_DIR}"/*.sql "${LOG_OUT}" "${LOG_ERR}" 2>/dev/null || true

echo "[1/11] Download demo_small.zip..."
curl -L "${ZIP_URL}" -o "${ZIP_PATH}" >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "[2/11] Unzip..."
unzip -o "${ZIP_PATH}" -d "${DL_DIR}" >>"${LOG_OUT}" 2>>"${LOG_ERR}"

SQL_FILE="$(find "${DL_DIR}" -maxdepth 2 -type f -name "*.sql" | head -n 1 || true)"
if [[ -z "${SQL_FILE}" ]]; then
  echo "ERROR: .sql not found in ${DL_DIR}" | tee -a "${LOG_ERR}"
  exit 1
fi
echo "Using SQL: ${SQL_FILE}" >>"${LOG_OUT}"

echo "[3/11] Patch dump (DROP DATABASE IF EXISTS)..."
sed -i 's/^DROP DATABASE demo;$/DROP DATABASE IF EXISTS demo;/' "${SQL_FILE}"

echo "[4/11] Patch dump (CREATE SCHEMA public)..."
sed -i 's/^CREATE SCHEMA public;$/CREATE SCHEMA IF NOT EXISTS public;/' "${SQL_FILE}"

echo "[5/11] Recreate compose stack (clean volume)..."
docker compose down -v >>"${LOG_OUT}" 2>>"${LOG_ERR}"
docker compose up -d "${PG_SERVICE}" >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "[6/11] Wait for Postgres ready..."
docker compose exec -T "${PG_SERVICE}" bash -lc \
  "until pg_isready -U '${PGUSER}' -d '${DB_ENTRY}'; do sleep 1; done" \
  >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "[7/11] Import dump..."
docker compose exec -T -e PGPASSWORD="${PGPASSWORD}" "${PG_SERVICE}" \
  psql -v ON_ERROR_STOP=1 -U "${PGUSER}" -d "${DB_ENTRY}" \
  < "${SQL_FILE}" >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "[8/11] Verify DB exists..."
docker compose exec -T "${PG_SERVICE}" psql -U "${PGUSER}" -d postgres -c "\l" \
  >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "[9/11] Verify tables..."
docker compose exec -T "${PG_SERVICE}" psql -U "${PGUSER}" -d demo -c "\dt" \
  >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "[10/11] Set search path..."
docker compose exec -T "${PG_SERVICE}" psql -U "${PGUSER}" -d demo -c "ALTER ROLE "${PGUSER}" SET search_path = bookings, public;" \
  >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "[11/11] Quick sanity check..."
docker compose exec -T "${PG_SERVICE}" psql -U "${PGUSER}" -d demo -c "SELECT count(*) FROM aircrafts;" \
  >>"${LOG_OUT}" 2>>"${LOG_ERR}"

echo "OK. Logs: ${LOG_OUT}, ${LOG_ERR}"
