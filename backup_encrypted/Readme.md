## Backup Script: `backup_with_features.sh` (and more)  

This project provides a modular backup solution with secure encryption and flexible options for managing and organizing backups. Below are details on setup, configuration, and usage.

---

### Features
1. **Modular Design**: Configure most options from the main script via an environment file `backup.env` (see `backup.env.example`).
2. **Encrypted Backups**: Creates `tar.gz` archives encrypted with AES-256-CBC to `tar.gz.enc`. (I hope everyone see, thats not a normal `tar.gz` archive)
3. **Customizable Backups**: Define the directories, database configurations, and custom operations in the script.
4. **Synchronized Encryption Keys**: It is not a feature, but as information. 
   - Same key for encryption and decryption.  
   - Stored in plain text on the host. (If you have access on the host, you can see the data without the key.)  
   - If you are use the script on multiple hosts. Each host should use its own unique key for encryption.
5. **Remote Backup Management**: Two possible ways:
   - Push backups to a remote SSH server, if you want/can access the backup server directly.  
   - Pull backups from hosts to a backup server or another remote location.
6. **Automated Backup Rotation**: Organize backups into `weekly` and `monthly` history folders, and prune old backups.
7. **Restore Support**: Decrypt and restore backups using the provided decryption script.
8. **Docker Support**: The SSH backup server can be spun up using a Docker container.
9. **Database Dump**: Snippets for PostreSQL and MySQL/MariaDB in the main script.

---

### Directory Structure
```
-- Backup-Dir
   |--- scp_backup     # Temporary storage for the (daily) backups sent via SCP (last 6, old ones are pruned)
   |--- history        # Copy last backup from scp_backup to monthly or weekly
       |---- monthly   # Long-term storage for monthly backups (no pruning)
       |---- weekly    # Stores the last 6 weekly backups (old ones are pruned)
```

---

### Installation and Setup

#### 1. Prerequisites
- Install `tar`, `openssl`, and `ssh/scp` on the host.
- Ensure Docker is installed if using the containerized SSH backup server.

#### 2. Configure the Environment
- Copy the provided `backup.env.example` to `backup.env`.
- Edit `backup.env` to set up variables like:
  - Backup directories
  - SCP target details
  - Encryption key file location
  - ...
  
#### 3. Backup directories and database dump
- Set the directory which should be backed up and the excluded subdirectories  
  `sudo tar -czf - --exclude='/home/<Username>/.*' --exclude='/home/<Username>/logs/*' --absolute-names /home/<Username> | openssl enc ...`
  --absolute-names => "Dir to Backup"  
  --exclude => set (multiple) subdir which you want to exclude from backup (Log-Files, etc)  
- If you need a database dump, feel free to edit the section after `ìf [ $dbbackup ]`  

#### 4. Edit custom section
- If you need some custom (example: stop or start a service) feel free to edit section after `if [ "$custom" ]`  

#### 4. Prepare the Encryption Key
- Generate an encryption key (one per host):
  ```bash
  openssl rand -base64 32 > /path/to/backup.key
  ```

#### 4. Set Up the SSH Server
- Use the provided `docker-compose.yml` to set up an SSH server for receiving backups:
  ```bash
  docker-compose up -d
  ```
- Update `<YOUR-PUBLIC-KEY.pub>` and `<BACKUP-DIRECTORY>` placeholders in the `docker-compose.yml`.  
- Test the SSH-Server with uncomment flag `testssh=1` in `backup.env` or `ssh -i <Your-Private-Key> -p <Your-SSH-Port> <USERNAME>@<SERVER-IP>`.  

---

### Usage different scripts

#### 1. Backup Creation
Run the `backup_with_features.sh` script:
```bash
./backup_with_features.sh
```

#### 2. Pull Backups (If Needed)
If the host cannot directly push to the SSH server, use:
- `backup_collect_OCI_remote2remote.sh` to pull and push backups to another remote server.
- `backup_collect_OCI_remote2local.sh` to pull backups and store locally.
In Both files you have to edit paths and hosts/server.

#### 3. Decrypt Backups
To decrypt a backup:
```bash
./backup_decrypt.sh /path/to/encrypted-file.enc
```

#### 4. Reorganize Backups
Use `backup_reorg.sh` to move and prune backups:
```bash
./backup_reorg.sh weekly     # Move the latest backup from 'scp_backup' to 'weekly' folder
./backup_reorg.sh monthly    # Move the latest backup from 'scp_backup' to 'monthly' folder
./backup_reorg.sh cleanup    # Prune backups, keeping only the last 6 in 'scp_backup' and 'weekly'
./backup_reorg.sh weekly_cleanup  # Combine actions
```
Activate multiple cron-jobs. Example every week the `weekly reorg` and once a month the `monthly reorg` combined with the `cleanup`.  
If you do not need a weekly reorg backup, you do not have to use it. The monthly backup are also copied from `scp_backup`.  

---

### Example CRON Jobs
Automate the backup process by adding the following to crontab:
```bash
# Daily backup at 23:12
12 23 * * * /path/to/backup_with_features.sh > /tmp/backup.log 2>&1 &
```

---

### Notes
- **Security**: The encryption key is stored in plaintext on the host. This is not ideal for high-security environments.
- **Customization**: Add custom pre/post-processing steps in the `backup_with_features.sh` script.

---

### Support
For more information or input, feel free to contact me or open a issue/discussion.