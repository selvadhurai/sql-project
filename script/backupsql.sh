#!/bin/bash
set -e
# Ensure the environment variables are available
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"  # Use the environment variable for password
NEW_DB_HOST="${NEW_DB_HOST}"
NEW_DB_PORT="${NEW_DB_PORT}"
NEW_DB_NAME="${NEW_DB_NAME}"
NEW_DB_USER="${NEW_DB_USER}"
NEW_DB_PASSWORD="${NEW_DB_PASSWORD}"  # Use the environment variable for password
EXPORT_FILE="db_export2.sql"

# Check if the database is ready
# pg_isready -h "$NEW_DB_HOST" -p "$NEW_DB_PORT" -U "$NEW_DB_USER" -d "$NEW_DB_NAME"
pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
if [ $? -eq 0 ]; then
    echo "Database is ready. Executing SQL file..."
    # Execute the SQL file
    # PGPASSWORD="$NEW_DB_PASSWORD" pg_dump -h $NEW_DB_HOST -U $NEW_DB_USER -d $NEW_DB_NAME > $EXPORT_FILE
    PGPASSWORD="$DB_PASSWORD" pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > $EXPORT_FILE
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