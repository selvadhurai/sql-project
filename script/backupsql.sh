#!/bin/bash
set -e
# Ensure the environment variables are available
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
PGPASSWORD="${DB_PASSWORD}"  # Use the environment variable for password
NEW_DB_HOST="${NEW_DB_HOST}"
NEW_DB_PORT="${NEW_DB_PORT}"
NEW_DB_NAME="${NEW_DB_NAME}"
NEW_DB_USER="${NEW_DB_USER}"
NEW_PGPASSWORD="${NEW_DB_PASSWORD}"  # Use the environment variable for password
EXPORT_FILE="db_export.sql"
# Check network connectivity
echo "Testing connectivity to the database host..."
nc -zv "$NEW_DB_HOST" "$NEW_DB_PORT"
if [ $? -ne 0 ]; then
    echo "Failed to reach the database host. Exiting."
    exit 1
fi
# Check if the database is ready
pg_isready -q -h "$NEW_DB_HOST" -p "$NEW_DB_PORT" -U "$NEW_DB_USER" -d "$NEW_DB_NAME"
if [ $? -eq 0 ]; then
    echo "Database is ready. Executing SQL file..."
    # Execute the SQL file
    pg_dump -q -h $NEW_DB_HOST -U $NEW_DB_USER -d $NEW_DB_NAME > $EXPORT_FILE
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