#!/bin/bash
# Ensure the environment variables are available
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
# DB_PASSWORD="postgres"
# PGPASSWORD="${DB_PASSWORD}"  # Use the environment variable for password
SQL_FILE="./release1.sql"
echo  "Selva"
# Check if the database is ready
# pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
pg_isready -h "$DB_HOST" -p "$DB_PORT"
psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"