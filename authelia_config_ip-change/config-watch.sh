#!/bin/bash

################
# inotifywait doesn't work correctly if file modified with sed
# so this script worked only on manual edit
################

cd "$(dirname -- "$0")"

CONFIG_PATH="/home/your/folder/config/configuration.yml"
#BACKUP_DIR="./backup"
AUTHELIA_CONTAINER="authelia"
TELEGRAM_TOKEN="$(sed -n 1p ./cred.txt)"
TELEGRAM_CHAT_ID="$(sed -n 2p ./cred.txt)"
DELAY=2  # Minimum time in seconds between two checks

# Comment out. The changes done before the file-watcher done anything
# Backup config file
#backup_config() {
#    cp "$CONFIG_PATH" "${BACKUP_DIR}/config_$(date +"%Y%m%d%H%M%S").yml"
#}

# Send Telegram message
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$message" > /dev/null
    echo No restarting something wrong
}

# Validate config
validate_config() {
    #authelia validate-configuration --config "$CONFIG_PATH"
    # Config path inside container
    OUTPUT=$(docker exec authelia authelia validate-config --config /config/configuration.yml 2>&1)
    
        # Check for success message in the output
    if echo "$OUTPUT" | grep -q "successfully"; then
        # If the output contains the success message
        echo "$OUTPUT"
        return 0
    else
        # If the output contains warnings or errors
        echo "$OUTPUT"
        return 1
    fi
}

# Restart authelia container
restart_authelia() {
    docker restart "$AUTHELIA_CONTAINER"
    echo restart container
}

# Watch for changes to the config file
inotifywait -m "$CONFIG_PATH" -e modify |
while read path action file; do
    echo
    echo "Detected change in config file, backing up and validating..."
    # Preventing from multiple changes in file
    #sleep 0.5

    CURRENT_TIME=$(date +%s)

    # Check if enough time has passed since the last run
    if (( CURRENT_TIME - LAST_RUN < DELAY )); then
        echo "Change detected, but throttled to avoid multiple triggers."
        continue
    fi

    LAST_RUN=$CURRENT_TIME
    # Backup the config file
    #backup_config
    
    # Validate the config file
    if validate_config; then
        echo "Config is valid, restarting Authelia..."
        restart_authelia
    else
        echo "Config is invalid, sending Telegram alert..."
        send_telegram_message "Authelia config validation failed. Please check!"
    fi
done
