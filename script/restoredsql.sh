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

EXPORT_FILE="./datafile/db_export.sql"  # Remove the space around '='

# Check network connectivity
echo "Testing connectivity to the database host..."
ping -c 4 "$DB_HOST"
if [ $? -ne 0 ]; then
    echo "Failed to reach the database host. Exiting."
    exit 1
fi

# Check if the database is ready
pg_isready -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
if [ $? -eq 0 ]; then
    echo "Database is ready. Import SQL file Executing..."
    # Execute the SQL file
    PGPASSWORD="$PGPASSWORD" psql -q -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" < "$EXPORT_FILE"
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