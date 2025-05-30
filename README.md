# Minecraft Bedrock Server Management

This repository contains scripts to manage a Minecraft Bedrock server.

- Source environment variables (paths and session names). **Must be sourced before running any script.**

    ```bash
    source env.sh
    ```

- The server files are located in the `bedrock-server/` directory.

- Backups are saved in the `backup/` directory.

- To start the server:

    ```bash
    bash start_blueWorld.bash
    ```

- To stop the server:

    ```bash
    bash stop_blueWorld.bash
    ```

- To backup the world related files:

    ```bash
    bash backup_blueWorld.bash
    ```
    This script creates a local backup under  the `backup/` directory

- To restore a backup into the server

    ```bash
    bash restore_backup.bash <backup/filename.tar.gz>
    ```
    This script stops the server and restore a backup.


- To fetch the latest available Bedrock server version and its download URL:

    ```bash
    source fetch_updates.sh
    ```

- To update (or download) the Bedrock server:  
    ```bash
    bash update_server.bash <server download URL>
    ```
    You can provide the download URL as an argument. If no argument is given, the script will use the URL set by `fetch_updates.bash` from the environment variable.
    This script stops the server, creates a backup, updates the server, restores the lastest backup from the `backup/` directory. The backup and restore steps can be skipped by changing the environment variables BACKUP_BEFORE_UPDATE and RESTORE_AFTER_UPDATE in the script, which default to TRUE
