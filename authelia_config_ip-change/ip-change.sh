#!/bin/bash

cd "$(dirname -- "$0")"

### You need a csv file with following content
# <Your-Domain>;#<AnchorTag>
# <Your-Domain2>;#<AnchorTag2>
# Without the Hashtag
CSV_FILE="./ip-change-domains.csv"

CONFIG_PATH="./config/configuration.yml"

# Test permissions read
#cat $CONFIG_PATH
#exit

BACKUP_DIR="./backup"
BACKUP_FILE="configuration_$(date +"%Y%m%d_%H%M%S").yml"


AUTHELIA_CONTAINER="authelia"
TELEGRAM_TOKEN="$(sed -n 1p ./cred.txt)"
TELEGRAM_CHAT_ID="$(sed -n 2p ./cred.txt)"

CHANGES=0

# Backup config file
backup_config() {
   cp "$CONFIG_PATH" "${BACKUP_DIR}/${BACKUP_FILE}"
   echo "Backup done!"
}

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
    echo "Container restarted!"
}

get_replace_IP() {
    
    #NEW_IP=$(dig +short @8.8.8.8 $domain)  # New IP passed as an argument
    NEW_IP=$(getent ahostsv4 $domain | cut -f 1 -d " " | head -n 1)  # New IP passed as an argument


    existing_IP_line=$(cat "$CONFIG_PATH" | grep "$anchor")
    if [ -z "$existing_IP_line" ]; then
        echo "No line found with the anchor '$anchor' in $CONFIG_PATH."
        echo
        return
    fi
    
    echo "$existing_IP_line"
    if echo "$existing_IP_line" | grep -q "$NEW_IP"; then
        # If the IP already in the config
        echo "$anchor: Already correct!"
    else
        # If the IP is not in the config
        echo "$anchor: Now changing!"

        # If multiple Changes in file backup only first time
        if [[ "$CHANGES" == 0 ]] ; then
            backup_config
        fi
        CHANGES=1

        sed -i "/$anchor/s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,2\}/$NEW_IP\/32/" "$CONFIG_PATH"
        echo "IP address for $anchor replaced with $NEW_IP in $CONFIG_PATH"

    fi
    echo
    
}


# Read the CSV file line by line
# https://stackoverflow.com/questions/20010741/why-does-unix-while-read-not-read-last-line
while IFS=';' read -r domain anchor || [ -n "$domain" ]; do
    #echo "$domain $anchor"

    # Skip empty lines
    if [ -z "$domain" ] || [ -z "$anchor" ]; then
        continue
    fi

    # Trim leading and trailing whitespace (optional)
    domain=$(echo "$domain" | xargs)
    anchor=$(echo "$anchor" | xargs)
    
    # Call the get_replace_IP function with domain and anchor
    get_replace_IP
done < "$CSV_FILE"

# If something changed: validate config and reload
if [[ "$CHANGES" == 1 ]]; then
    if validate_config; then
        echo "Config is valid, restarting Authelia + Telegram Info..."
        send_telegram_message "Config changed and valid, restarting Authelia..."
        restart_authelia
    else
        echo "Config is invalid, sending Telegram alert..."
        send_telegram_message "Authelia config validation FAILED. Please check!!!!!"
    fi
else
    echo "No changes no reload!"
fi

