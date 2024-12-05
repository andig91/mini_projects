#!/bin/bash

# A script to write the wiki as markdown with pictures in your git-repo
# Delete and download all and commit (diff detect only the changes)

# Install in CRONTAB
#12 23 * * * /path/to/bookstack-export.sh > /tmp/export-to-git.log 2>&1 &

cd "$(dirname -- "$0")"
pwd -P

# --user flag to override the uid/gid for created files. Set this to your uid/gid
# docker run \
podman run \
    --user 1000:1000 \
    --rm \
    -v ./config.yml:/export/config/config.yml:ro \
    -v ./md-tgz:/export/dump \
    docker.io/homeylab/bookstack-file-exporter:latest
# Podman: Set directory permissions of /export/dump to 666, because container user wrong ID
# Maybe I don't know the trick. No problem in docker

# Get last archive
tgz_file=$(ls -1A md-tgz/ | tail -n 1)
echo $tgz_file

# Delete old archives
rm -rf bookstack_markdown_export/

# Untar the archive
tar -xvzf md-tgz/$tgz_file -C ./
mv bookstack_export_* bookstack_markdown_export

# I think git is sometimes not fast enough and see only a part of the changes
#sleep 10

# Push to gitea
timestamp=$(date "+%Y-%m-%d %H:%M")
git add -A
git commit -m "Autocommit $timestamp"
#git commit -a -m "Autocommit $timestamp"
git push