
#!/bin/bash
set -e

# Database connection details
CURRENT_DB_HOST="CURRENT_DB_HOST"
CURRENT_DB_PORT="CURRENT_DB_PORT"
CURRENT_DB_USER="CURRENT_DB_USER"
CURRENT_DB_NAME="CURRENT_DB_NAME"
CURRENT_DB_PASSWORD="CURRENT_DB_PASSWORD"

PREVIOUS_DB_HOST="NEW_DB_HOST"
PREVIOUS_DB_PORT="NEW_DB_PORT"
PREVIOUS_DB_USER="NEW_DB_USER"
PREVIOUS_DB_NAME="NEW_DB_NAME"
PREVIOUS_DB_PASSWORD="NEW_DB_PASSWORD"

EXPORT_DIR="datafile"
SCHEMA_DIFF_FILE="schema_diff.sql"
DATA_DIFF_FILE="data_diff.sql"

# mkdir -p $EXPORT_DIR

# Export current and previous databases
echo "Exporting current database..."

# PGPASSWORD="$CURRENT_DB_PASSWORD" pg_dump -h $CURRENT_DB_HOST -U $CURRENT_DB_USER -d $CURRENT_DB_NAME > $EXPORT_DIR/current_db_export.sql

echo "Exporting previous database..."

PGPASSWORD="$PREVIOUS_DB_PASSWORD" pg_dump -h $PREVIOUS_DB_HOST -U $PREVIOUS_DB_USER -d $PREVIOUS_DB_NAME > $EXPORT_DIR/previous_db_export.sql

# Compare schemas
echo "Comparing schemas..."
pg_diff --old $EXPORT_DIR/previous_db_export.sql --new $EXPORT_DIR/current_db_export.sql --output $EXPORT_DIR/$SCHEMA_DIFF_FILE

# Compare data
echo "Comparing data..."
diff $EXPORT_DIR/previous_db_export.sql $EXPORT_DIR/current_db_export.sql > $EXPORT_DIR/$DATA_DIFF_FILE

echo "Schema differences saved to $EXPORT_DIR/$SCHEMA_DIFF_FILE"
echo "Data differences saved to $EXPORT_DIR/$DATA_DIFF_FILE"

