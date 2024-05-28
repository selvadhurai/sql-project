#!/bin/bash
set -e
# Ensure the environment variables are available
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
PGPASSWORD="${DB_PASSWORD}"  # Use the environment variable for password
SQL_FILE="./release1.sql"
# Check network connectivity
echo "Testing connectivity to the database host..."
ping -c 4 "$DB_HOST"
if [ $? -ne 0 ]; then
    echo "Failed to reach the database host. Exiting."
    exit 1
fi
# Check if the database is ready
pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
if [ $? -eq 0 ]; then
    echo "Database is ready. Executing SQL file..."
    # Execute the SQL file
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"
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