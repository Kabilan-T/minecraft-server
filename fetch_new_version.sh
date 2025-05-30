#!/bin/bash

# === Fetching download url of latest server version ===
json_url="https://raw.githubusercontent.com/kittizz/bedrock-server-downloads/main/bedrock-server-downloads.json"
read -r latest_version latest_url < <(curl -s "$json_url" | python3 -c '
import sys, json
j = json.load(sys.stdin)
latest = sorted(j["release"].keys(), key=lambda x: list(map(int, x.split("."))))[-1]
print(latest, j["release"][latest]["linux"]["url"])
')

echo "Latest version: $latest_version"
echo "URL : $latest_url"

export SERVER_DOWNLOAD_URL="$latest_url"
echo "SERVER_DOWNLOAD_URL set to $SERVER_DOWNLOAD_URL"