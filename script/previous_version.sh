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
DB_PASSWORD="${DB_PASSWORD}"
 
 # List all SQL files sorted by modification time
echo "Listing all SQL files sorted by modification time:"
ls -1t archive/*.sql

# Store the sorted list in an array
sql_files=($(ls -1t archive/*.sql))

# Check the array contents
echo "SQL files array: ${sql_files[@]}"

# Select the second most recent SQL file
previous_sql_file=${sql_files[1]}
echo "Previous SQL file: $previous_sql_file"

# Check if previous SQL file exists
if [ -f "$previous_sql_file" ]; then
    echo "Executing $previous_sql_file"
    PGPASSWORD="$DB_PASSWORD" psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$previous_sql_file"
    if [ $? -eq 0 ]; then
        echo "SQL file executed successfully"
    else
        echo "Error executing SQL file"
        exit 1
    fi
else
    echo "No previous SQL file found"
    exit 1
fi