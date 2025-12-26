#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="postgres"
CONTAINER_NAME="pg-demo"

DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"
DB_PASS="postgres"

FINAL_DB="ad_platform"
FINAL_SCHEMA="ad_platform"

SCHEMA_SQL="/work/Homework-Final/schema.sql"
SEED_SQL="/work/Homework-Final/seed.sql"

echo "[1/6] Stop and remove container + volumes"
docker compose down -v

echo "[2/6] Start postgres container"
docker compose up -d "${SERVICE_NAME}"

echo "[wait] Waiting for Postgres to accept connections..."
until docker exec "${CONTAINER_NAME}" pg_isready -U "${DB_USER}" -d "postgres" >/dev/null 2>&1; do
  sleep 1
done

echo "[3/6] Create database ${FINAL_DB}"
docker exec -e PGPASSWORD="${DB_PASS}" "${CONTAINER_NAME}" \
  psql -U "${DB_USER}" -d "postgres" -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS ${FINAL_DB};"

docker exec -e PGPASSWORD="${DB_PASS}" "${CONTAINER_NAME}" \
  psql -U "${DB_USER}" -d "postgres" -v ON_ERROR_STOP=1 \
  -c "CREATE DATABASE ${FINAL_DB};"

echo "[4/6] Apply schema.sql into ${FINAL_DB}"
docker exec -e PGPASSWORD="${DB_PASS}" "${CONTAINER_NAME}" \
  psql -U "${DB_USER}" -d "${FINAL_DB}" -v ON_ERROR_STOP=1 \
  -f "${SCHEMA_SQL}"

echo "[5/6] Apply seed.sql into ${FINAL_DB}"
docker exec -e PGPASSWORD="${DB_PASS}" "${CONTAINER_NAME}" \
  psql -U "${DB_USER}" -d "${FINAL_DB}" -v ON_ERROR_STOP=1 \
  -f "${SEED_SQL}"

echo "[6/6] Set default search_path for role ${DB_USER} in database ${FINAL_DB}"
docker exec -e PGPASSWORD="${DB_PASS}" "${CONTAINER_NAME}" \
  psql -U "${DB_USER}" -d "${FINAL_DB}" -v ON_ERROR_STOP=1 \
  -c "ALTER ROLE ${DB_USER} IN DATABASE ${FINAL_DB} SET search_path TO ${FINAL_SCHEMA}, public;"

echo "Done."
