#!/bin/bash
# Database connection parameters
DB_HOST="selva-geneartdb.c7gozccxmuzm.us-east-1.rds.amazonaws.com"
DB_PORT="5432"
DB_NAME="geneart"
DB_USER="postgres"
DB_PASSWORD=$DB_PASSWORD
export PGPASSWORD="$DB_PASSWORD"
# Check network connectivity
echo "Testing connectivity to the database host..."
# Trim any potential whitespace from the hostname
DB_HOST=$(echo "$DB_HOST" | tr -d '[:space:]')
# Find the IP address of the host
echo "Finding the IP address of the database host..."
nslookup "$DB_HOST" || dig +short "$DB_HOST"
# Check network connectivity
echo "Testing connectivity to the database host..."
ping -c 4 "$DB_HOST"
# Connect to the database
pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;"
