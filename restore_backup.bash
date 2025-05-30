#!/bin/bash

if [ -z "$BEDROCK_SERVER_PATH" ] || [ -z "$BACKUP_DIR" ] || [ -z "$SESSION_NAME" ]; then
  echo "Please source env.sh before running this script."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: bash restore_blueWorld.bash <backup_file>"
  exit 1
fi

# === Check backup file ===
BACKUP_FILE="$1"
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

# === Stopping the server ===
bash stop_blueWorld.bash

# === Restore the backup ===
echo "Restoring backup from $BACKUP_FILE..."
# Extract the backup archive to the server path (overwrite files)
tar -xzf "$BACKUP_FILE" -C "$BEDROCK_SERVER_PATH"
echo "Restore completed."
