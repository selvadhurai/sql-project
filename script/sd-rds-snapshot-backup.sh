#!/bin/bash

LOG_FILE="/tmp/sd-script1.log"
SNAPSHOT_NAME="selva-geneartdb-snapshot-$(date +%Y%m%d%H%M%S)"
DB_INSTANCE_IDENTIFIER="selva-geneartdb"
AWS_REGION="us-east-1"

#clear the log file if it exists
> $LOG_FILE
echo "Starting script..." | tee -a $LOG_FILE

# Ensure the environment variables are available
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
# SQL_FILE="./release_sql/release1.sql"

# Check if the database is ready
# pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
# pg_isready -h "$DB_HOST" -p "$DB_PORT"
# psql -q -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"
pg_isready -h "$DB_HOST" -p "$DB_PORT" | tee -a $LOG_FILE

# timeout handling
max_retries=5
retry_count=0
sleep_interval=60

echo "Taking a snapshot of the database..." | tee -a $LOG_FILE

while [ $retry_count -lt $max_retries ]; do
	aws rds create-db-snapshot --db-snapshot-identifier $SNAPSHOT_NAME --db-instance-identifier $DB_INSTANCE_IDENTIFIER | tee -a $LOG_FILE
    if [ $? -eq 0]; then
    	echo "Snapshot creation init successfully..." | tee -a $LOG_FILE
    	break
    else
    	echo "Snapshot creation failed, Retry $sleep_interval seconds..." | tee -a $LOG_FILE
    	sleeo $sleep_interval
    	retry_count=$((retry_count + 1))
    fi
done

if [ $retry_count -eq $max_retries ]; then
	echo "Faild to init after $max_retries attempts. exiting.." | tee -a $LOG_FILE
	exit 1
fi
echo "Waiting for the snapshot to be available.." | tee -a $LOG_FILE
aws rds wait db-snapshot-available --db-snapshot-identifier $SNAPSHOT_NAME --region $AWS_REGION | tee -a $LOG_FILE

if [ $? -eq 0 ]; then
            echo "Snapshot $SNAPSHOT_NAME is available." | tee -a $LOG_FILE
        else
            echo "Failed to create snapshot. Exiting..." | tee -a $LOG_FILE
            exit 1
fi

echo "Script completed successfully." | tee -a $LOG_FILE