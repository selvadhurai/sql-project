
#!/bin/bash
set -e

# Database connection details
CURRENT_DB_HOST="${CURRENT_DB_HOST}"
CURRENT_DB_PORT="${CURRENT_DB_PORT}"
CURRENT_DB_USER="${CURRENT_DB_USER}"
CURRENT_DB_NAME="${CURRENT_DB_NAME}"
CURRENT_DB_PASSWORD="${CURRENT_DB_PASSWORD}"
PREVIOUS_DB_HOST="${NEW_DB_HOST}"
PREVIOUS_DB_PORT="${NEW_DB_PORT}"
PREVIOUS_DB_USER="${NEW_DB_USER}"
PREVIOUS_DB_NAME="${NEW_DB_NAME}"
PREVIOUS_DB_PASSWORD="${NEW_DB_PASSWORD}"
EXPORT_DIR="datafile"
SCHEMA_DIFF_FILE="schema_diff.sql"
DATA_DIFF_FILE="data_diff.sql"
# mkdir -p $EXPORT_DIR
# Check if the database is ready
pg_isready -h "$CURRENT_DB_HOST" -p "$CURRENT_DB_PORT" -U "$CURRENT_DB_USER" -d "$CURRENT_DB_NAME"
pg_isready -h "$PREVIOUS_DB_HOST" -p "$PREVIOUS_DB_PORT" -U "$PREVIOUS_DB_USER" -d "$PREVIOUS_DB_NAME"
# Export current and previous databases
echo "Exporting current database..."
export PGPASSWORD=$CURRENT_DB_PASSWORD
pg_dump -s -h $CURRENT_DB_HOST -U $CURRENT_DB_USER -d $CURRENT_DB_NAME > $EXPORT_DIR/current_db_schema.sql
pg_dump -a -h $CURRENT_DB_HOST -U $CURRENT_DB_USER -d $CURRENT_DB_NAME > $EXPORT_DIR/current_db_data.sql

echo "Exporting previous database..."
export PGPASSWORD=$PREVIOUS_DB_PASSWORD
pg_dump -s -h $PREVIOUS_DB_HOST -U $PREVIOUS_DB_USER -d $PREVIOUS_DB_NAME > $EXPORT_DIR/previous_db_schema.sql
pg_dump -a -h $PREVIOUS_DB_HOST -U $PREVIOUS_DB_USER -d $PREVIOUS_DB_NAME > $EXPORT_DIR/previous_db_data.sql
# Compare schemas using diff
echo "Comparing schemas..."
diff $EXPORT_DIR/previous_db_schema.sql $EXPORT_DIR/current_db_schema.sql > $EXPORT_DIR/$SCHEMA_DIFF_FILE

# Compare data using diff
echo "Comparing data..."
diff $EXPORT_DIR/previous_db_data.sql $EXPORT_DIR/current_db_data.sql > $EXPORT_DIR/$DATA_DIFF_FILE

echo "Schema differences saved to $EXPORT_DIR/$SCHEMA_DIFF_FILE"
echo "Data differences saved to $EXPORT_DIR/$DATA_DIFF_FILE"