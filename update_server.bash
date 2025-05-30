#!/bin/bash

if [ -z "$BEDROCK_SERVER_PATH" ] || [ -z "$SESSION_NAME" ] || [ -z "$BACKUP_DIR" ]; then
  echo "Please source env.sh before running this script."
  exit 1
fi

# Control variables (default to TRUE)
BACKUP_BEFORE_UPDATE=${BACKUP_BEFORE_UPDATE:-TRUE}
RESTORE_AFTER_UPDATE=${RESTORE_AFTER_UPDATE:-TRUE}

# Use URL from argument or environment variable SERVER_DOWNLOAD_URL
DOWNLOAD_URL="$1"
if [ -z "$DOWNLOAD_URL" ]; then
  if [ -z "$SERVER_DOWNLOAD_URL" ]; then
    echo "No download URL provided and SERVER_DOWNLOAD_URL is not set."
    exit 1
  fi
  DOWNLOAD_URL="$SERVER_DOWNLOAD_URL"
fi

echo "Updating Bedrock server from: $DOWNLOAD_URL"

# === Stopping the server ===
echo "Stopping server..."
bash stop_blueWorld.bash

# === Create a Backup at current state ===
if [ "$BACKUP_BEFORE_UPDATE" = "TRUE" ]; then
  echo "Backing up server files..."
  bash backup_blueWorld.bash
else
  echo "Skipping backup before update."
fi

# === Download the new version archive ===
TMP_DIR=$(mktemp -d)
ARCHIVE_NAME="$TMP_DIR/bedrock_server_update.tar.gz"
echo "Downloading server archive..."
if ! wget --user-agent="Mozilla/5.0 (X11; Linux x86_64)" -O "$ARCHIVE_NAME" "$DOWNLOAD_URL"; then
  echo "Download failed."
  rm -rf "$TMP_DIR"
  exit 1
fi

# === Extract the downloaded archive to server directory (overwrite) ===
echo "Extracting new server files..."
unzip -o "$ARCHIVE_NAME" -d "$BEDROCK_SERVER_PATH"
# Clean up temp
rm -rf "$TMP_DIR"

# === Restore the latest backup ===
if [ "$RESTORE_AFTER_UPDATE" = "TRUE" ]; then
  BACKUP_FILE=$(ls -1t "$BACKUP_DIR" 2>/dev/null | head -n 1)
  if [ -z "$BACKUP_FILE" ]; then
    echo "No backup files found in $BACKUP_DIR, skipping restore."
  else
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    echo "Restoring latest backup...$BACKUP_FILE"
    bash restore_backup.bash "$BACKUP_FILE"
  fi
else
  echo "Skipping restore after update."
fi

echo "Bedrock server update completed."

