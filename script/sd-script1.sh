#!/bin/bash
# Ensure the environment variables are available
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
# DB_PASSWORD="postgres"
# PGPASSWORD="${DB_PASSWORD}"  # Use the environment variable for password
SQL_FILE="./release_sql/release1.sql"
echo  "Selva"
# Check if the database is ready
# pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
# pg_isready -h "$DB_HOST" -p "$DB_PORT"
# psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"
pg_isready -h "$DB_HOST" -p "$DB_PORT"
if [ $? -eq 0 ]; then
    echo "Database is ready. Executing SQL file..."
    # Execute the SQL file
    psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"
    if [ $? -eq 0 ]; then
        echo "SQL file executed successfully"
    else
        echo "Error executing SQL file"
        exit 1
    fi
else
    echo "Database is not ready or authentication failed. Transaction terminated."
    exit 1
fi