#!/bin/bash

LOG_FILE="/tmp/sd-script1.log"
SNAPSHOT_NAME="selva-geneartdb-snapshot-$(date +%Y%m%d%H%M%S)"
DB_INSTANCE_IDENTIFIER="selva-geneartdb"

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

echo "Taking a snapshot of the database..." | tee -a $LOG_FILE
aws rds create-db-snapshot --db-snapshot-identifier $SNAPSHOT_NAME --db-instance-identifier $DB_INSTANCE_IDENTIFIER | tee -a $LOG_FILE
echo "Waiting for the snapshot to be available..." | tee -a $LOG_FILE
aws rds wait db-snapshot-available --db-snapshot-identifier $SNAPSHOT_NAME | tee -a $LOG_FILE

echo "Snapshot $SNAPSHOT_NAME is available." | tee -a $LOG_FILE