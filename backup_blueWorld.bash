#!/bin/bash

if [ -z "$BEDROCK_SERVER_PATH" ] || [ -z "$BACKUP_DIR" ] || [ -z "$SESSION_NAME" ]; then
  echo "Please source env.sh before running this script."
  exit 1
fi

timestamp=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="bedrock_backup_$timestamp.tar.gz"

# List of files/directories to backup (relative to BEDROCK_SERVER_PATH)
BACKUP_ITEMS=(
    "worlds"
    "server.properties"
    "permissions.json"
    "allowlist.json"
)

# === Check if tmux session exists ===
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    SERVER_RUNNING=true
    echo "Found TMUX session '$SESSION_NAME'. Bedrock server Running."
else
    SERVER_RUNNING=false
    echo "TMUX session '$SESSION_NAME' not found. Bedrock server not Running. Proceeding with local backup only."
fi

# === Pause saving ===
if [ "$SERVER_RUNNING" = true ]; then
    echo "Sending 'save hold' to Bedrock server"
    tmux send-keys -t "$SESSION_NAME" "save hold" C-m
    sleep 5
    tmux send-keys -t "$SESSION_NAME" "save query" C-m
    sleep 5
fi

# === Check backup items  ===
tar_args=()
missing_items=()
empty_backup=true

for item in "${BACKUP_ITEMS[@]}"; do
    path="$BEDROCK_SERVER_PATH/$item"
    if [ -e "$path" ]; then
        # Check if non-empty directory or non-empty file
        if [ -d "$path" ]; then
            if [ "$(ls -A "$path")" ]; then
                empty_backup=false
                tar_args+=("$item")
            else
                # empty directory, treat as missing for backup
                missing_items+=("$item (empty directory)")
            fi
        else
            # file: check size > 0
            if [ -s "$path" ]; then
                empty_backup=false
                tar_args+=("$item")
            else
                missing_items+=("$item (empty file)")
            fi
        fi
    else
        missing_items+=("$item (missing)")
    fi
done

if [ "$empty_backup" = true ]; then
    echo "No backup needed: all backup items are missing or empty."
    # Resume saving if server was paused
    if [ "$SERVER_RUNNING" = true ]; then
        echo "Sending 'save resume' to Bedrock server"
        tmux send-keys -t "$SESSION_NAME" "save resume" C-m
    fi
    exit 0
fi

# === Create backup ===
mkdir -p "$BACKUP_DIR"
# Build tar arguments dynamically from BACKUP_ITEMS
tar_args=()
for item in "${BACKUP_ITEMS[@]}"; do
    tar_args+=("$item")
done
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$BEDROCK_SERVER_PATH" "${tar_args[@]}"
echo "Backup created - $BACKUP_DIR/$BACKUP_NAME"

# === Echo backup info ===
backup_size=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
file_count=$(tar -tf "$BACKUP_DIR/$BACKUP_NAME" | wc -l)

echo "Backup size: $backup_size"
echo "Number of files in backup: $file_count"

if [ ${#missing_items[@]} -ne 0 ]; then
    echo "Warning: The following backup items were missing or empty and not included:"
    for miss in "${missing_items[@]}"; do
        echo "  - $miss"
    done
fi

# === Resume saving ===
if [ "$SERVER_RUNNING" = true ]; then
    echo "Sending 'save resume' to Bedrock server"
    tmux send-keys -t "$SESSION_NAME" "save resume" C-m
fi


# === Delete backups older than 7 days ===
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;
