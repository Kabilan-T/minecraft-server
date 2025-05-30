#!/bin/bash

if [ -z "$BEDROCK_SERVER_PATH" ] || [ -z "$SESSION_NAME" ] || [ -z "$LOG_DIR" ]; then
  echo "Please source env.sh before running this script."
  exit 1
fi

# === Creating new TMUX session ===
echo "Starting blueWorld server..."
tmux new-session -d -s ${SESSION_NAME} "bash"
sleep 1

# === Forwarding session outputs to log ===
tmux send-keys -t ${SESSION_NAME} "cd ${BEDROCK_SERVER_PATH}" Enter
sleep 1
mkdir -p "${LOG_DIR}"
timestamp=$(date +"%Y%m%d_%H%M%S")
log_file="${LOG_DIR}/blueWorld_server_${timestamp}.log"
touch "${log_file}"
tmux pipe-pane -t ${SESSION_NAME}:0.0 -o "cat > ${log_file}"

# === Launching bedrock server ===
tmux send-keys -t ${SESSION_NAME} 'LD_LIBRARY_PATH=. ./bedrock_server' Enter


echo "blueWorld server running..."
echo "log file : ${log_file}"
echo "Use the following command to attach to tmux session:"
echo "  tmux attach -t ${SESSION_NAME}"