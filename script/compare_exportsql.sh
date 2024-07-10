
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
if ! pg_dump -s -h $CURRENT_DB_HOST -U $CURRENT_DB_USER -d $CURRENT_DB_NAME > $EXPORT_DIR/current_db_schema.sql; then
  echo "Failed to export current database schema."
  exit 1
fi
if ! pg_dump -a -h $CURRENT_DB_HOST -U $CURRENT_DB_USER -d $CURRENT_DB_NAME > $EXPORT_DIR/current_db_data.sql; then
  echo "Failed to export current database data."
  exit 1
fi

echo "Exporting previous database..."
export PGPASSWORD=$PREVIOUS_DB_PASSWORD
if ! pg_dump -s -h $PREVIOUS_DB_HOST -U $PREVIOUS_DB_USER -d $PREVIOUS_DB_NAME > $EXPORT_DIR/previous_db_schema.sql; then
  echo "Failed to export previous database schema."
  exit 1
fi
if ! pg_dump -a -h $PREVIOUS_DB_HOST -U $PREVIOUS_DB_USER -d $PREVIOUS_DB_NAME > $EXPORT_DIR/previous_db_data.sql; then
  echo "Failed to export previous database data."
  exit 1
fi
# Verify if the files are created and not empty
echo "Verifying schema export files..."
if [ ! -s $EXPORT_DIR/current_db_schema.sql ]; then
  echo "Current database schema export file is empty or not found."
  exit 1
fi
if [ ! -s $EXPORT_DIR/previous_db_schema.sql ]; then
  echo "Previous database schema export file is empty or not found."
  exit 1
fi
# Compare schemas using diff
echo "Comparing schemas..."
if diff $EXPORT_DIR/previous_db_schema.sql $EXPORT_DIR/current_db_schema.sql > $EXPORT_DIR/$SCHEMA_DIFF_FILE; then
  echo "No schema differences found."
else
  echo "Schema differences found and saved to $EXPORT_DIR/$SCHEMA_DIFF_FILE"
fi

# Compare data using diff
echo "Comparing data..."
if diff $EXPORT_DIR/previous_db_data.sql $EXPORT_DIR/current_db_data.sql > $EXPORT_DIR/$DATA_DIFF_FILE; then
  echo "No data differences found."
else
  echo "Data differences found and saved to $EXPORT_DIR/$DATA_DIFF_FILE"
fi
echo "Schema differences saved to $EXPORT_DIR/$SCHEMA_DIFF_FILE"
echo "Data differences saved to $EXPORT_DIR/$DATA_DIFF_FILE"