#!/bin/bash

LOG_FILE="/tmp/sd-script1.log"

#clear the log file if it exists
> $LOG_FILE
echo "Starting script..." | tee -a $LOG_FILE

# Ensure the environment variables are available
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
SQL_FILE="./release_sql/release1.sql"

# Check if the database is ready
# pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
# pg_isready -h "$DB_HOST" -p "$DB_PORT"
# psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"
pg_isready -h "$DB_HOST" -p "$DB_PORT" | tee -a $LOG_FILE
if [ $? -eq 0 ]; then
    echo "Database is ready. Executing SQL file..." | tee -a $LOG_FILE
    # Execute the SQL file
    psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE" | tee -a $LOG_FILE
    if [ $? -eq 0 ]; then
        echo "SQL file executed successfully" | tee -a $LOG_FILE
    else
        echo "Error executing SQL file" | tee -a $LOG_FILE
        exit 1
    fi
else
    echo "Database is not ready or authentication failed. Transaction terminated." | tee -a $LOG_FILE
    exit 1
fi

echo "Script compeleted successfully." | tee -a $LOG_FILE