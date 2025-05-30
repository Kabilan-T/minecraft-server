#!/bin/bash

if [ -z "$SESSION_NAME" ]; then
  echo "Please source env.sh before running this script."
  exit 1
fi

# === Ending TMUX session, If exists===
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Server is running. Stopping tmux session $SESSION_NAME..."
  tmux send-keys -t "$SESSION_NAME" C-c
  sleep 2
  tmux kill-session -t "$SESSION_NAME"
  echo "Server stopped."
else
  echo "No tmux session named $SESSION_NAME found. Server not running"
fi