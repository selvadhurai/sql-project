#!/bin/bash
# Database connection parameters
DB_HOST="<>.us-east-1.rds.amazonaws.com"
DB_PORT="5432"
DB_NAME="sample_db"
DB_USER="postgres"
DB_PASSWORD=$DB_PASSWORD
# SQL script file
SQL_FILE=". ./release1.sql"
# Connect to the database
pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"