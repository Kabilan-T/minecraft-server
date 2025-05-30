#!/bin/bash

BASE_DIR="$(pwd)"

export BASE_DIR
export SESSION_NAME="blueWorld_server_session"
export BEDROCK_SERVER_PATH="$BASE_DIR/bedrock-server"
export BACKUP_DIR="$BASE_DIR/backup"
export LOG_DIR="$BASE_DIR/logs"

echo "Done"
