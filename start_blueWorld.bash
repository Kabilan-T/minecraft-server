#!/bin/bash

if [ -z "$BEDROCK_SERVER_PATH" ] || [ -z "$SESSION_NAME" ]; then
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
tmux pipe-pane -t ${SESSION_NAME} -o "cat > blueWorld_server.log"

# === Launching bedrock server ===
tmux send-keys -t ${SESSION_NAME} 'LD_LIBRARY_PATH=. ./bedrock_server' Enter


echo "blueWorld server running..."
echo "Use the following command to attach to tmux session:"
echo "  tmux attach -t ${SESSION_NAME}"