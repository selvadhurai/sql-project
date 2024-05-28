#!/bin/bash
# Database connection parameters
# DB_HOST="selva-geneartdb.c7gozccxmuzm.us-east-1.rds.amazonaws.com"
DB_HOST="172.16.2.154"
DB_PORT="5432"
DB_NAME="geneart"
DB_USER="postgres"
DB_PASSWORD=$DB_PASSWORD
export PGPASSWORD="$DB_PASSWORD"
# Check network connectivity
echo "Testing connectivity to the database host..."
# Connect to the database
pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;"
