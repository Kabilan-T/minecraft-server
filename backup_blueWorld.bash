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

send_command_and_confirm_output() {
    local cmd="$1"
    local confirm_message="$2"
    local max_attempts=10
    local sleep_interval=1
    local success=false

    # Capture tmux output before sending the command
    local before_output
    before_output=$(tmux capture-pane -t "$SESSION_NAME" -p)

    # Send the command to the tmux session
    tmux send-keys -t "$SESSION_NAME" "$cmd" C-m

    echo "Waiting for confirmation of '$cmd'..."
    for i in $(seq 1 "$max_attempts"); do
        sleep "$sleep_interval"

        # Capture new output after command
        local after_output
        after_output=$(tmux capture-pane -t "$SESSION_NAME" -p)

        # Get the diff (new lines only)
        local new_lines
        new_lines=$(diff <(echo "$before_output") <(echo "$after_output") | sed '1,2d' | grep '^> ' | cut -c3-)

        if echo "$new_lines" | grep -q "$confirm_message"; then
            echo "Confirmed: $confirm_message"
            success=true
            break
        fi
    done

    if [ "$success" = false ]; then
        echo "ERROR: '$cmd' did not result in expected output ('$confirm_message')"
        exit 1
    fi
}

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
    send_command_and_confirm_output "save hold" "Saving"
    echo "Sending 'save query' to Bedrock server"
    send_command_and_confirm_output "save query" "Data saved"

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
        send_command_and_confirm_output "save resume" "Changes to the world are resumed"
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
    send_command_and_confirm_output "save resume" "Changes to the world are resumed"
fi


# === Delete backups older than 7 days ===
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;
