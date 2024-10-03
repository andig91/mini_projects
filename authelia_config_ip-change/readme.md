# IP Update Script for Authelia Configuration

This script automatically updates IP addresses in your Authelia configuration based on domain resolution. It reads a CSV file containing domain names and anchor tags, resolves the new IP addresses for those domains, and replaces the corresponding IP addresses in the Authelia configuration file. If changes are detected, the script backs up the configuration, validates the new configuration, and restarts the Authelia container. Additionally, it sends Telegram alerts in case of any configuration issues and success.

## Prerequisites

- **Authelia** running inside a Docker container.
- **Authelia configuration file** that has rules for domains and IP addresses.
  The configuration file have to be no errors, also no warnings. Only `Configuration parsed and loaded successfully without errors.` allowed.
- **Telegram bot** set up to send alerts.
- **CSV file** with domain and anchor tags.

## Setup

### CSV File Example
The CSV file contains domain names and anchor tags that will be used to identify the correct lines in the configuration file:

```csv
<Your.Domain>;#<Your-Anchor-Tag>
<Your.Domain2>;#<Your-Anchor-Tag2>
test.example.com;#YourHomeISPConnection
```

A example file is in the directory. Rename and edit it.

### Configuration File Example
The Authelia configuration file must include anchor tags (e.g., `#<Your-Anchor-Tag>`) that correspond to the domains in the CSV file:

```yaml
access_control:
  default_policy: deny
  rules:
    # Rules applied to everyone
    - domain:
      - "*.your.domain.com"
      networks:
        - 123.123.123.9/32 #<Your-Anchor-Tag>
        - 122.123.123.78/32 #<Your-Anchor-Tag2>
```

### Directory Structure
Make sure your script and related files are organized like this:

```
your-project-directory/
│
├── ip-change-script.sh       # The main script
├── ip-change-domains.csv     # Your CSV file with domain-anchor pairs
├── config/
│   └── configuration.yml     # Your Authelia configuration file
├── backup/                   # Where configuration backups will be stored
└── cred.txt                  # Credentials for telegram
```

### Required Credentials
The script reads the Telegram bot token and chat ID from a credentials file (`cred.txt`), which should contain:

```
<Your-Telegram-Bot-Token>
<Your-Telegram-Chat-ID>
```

### Permissions
Ensure that the script has execute permissions:
```bash
chmod +x ip-change-script.sh
```

## Usage

1. **Run the Script**:
   Execute the script in your terminal:
   ```bash
   ./ip-change-script.sh
   ```

2. **Expected Behavior**:
   - The script iterate over the lines in the csv-file.
   - The script checks for domain-IP changes.
   - If changes are detected, it backs up the current configuration.
   - The configuration is updated with the new IP addresses.
   - If the updated configuration is valid, the Authelia container is restarted.
   - Telegram notifications are sent for both success and failure cases.
   
## Config as cronjob

```bash
crontab -e
05 */1 * * * /your/project/directory/ip-change-script.sh > /tmp/ip-change.log 2>&1 &
```

## Error Handling

- If the script cannot find an anchor tag in the configuration file that matches the domain from the CSV, it will skip that line and print a message.
- If the configuration validation fails, the script will not restart the Authelia container and will send a Telegram alert. Also warnings are showstopper.

## Troubleshooting

- **No changes are applied**: Ensure that the CSV file contains valid domain names and anchor tags, and that the domain resolves to a valid IP.
- **Permission issues**: If you encounter permission issues while accessing the configuration file, ensure that the script is run with appropriate permissions or adjust file ownership accordingly.

## Disclaimer  

- The script and readme are written with support of ChatGPT
