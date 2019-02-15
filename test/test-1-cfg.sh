#!/usr/bin/env bash

# Sunshine weekly artifact backup iteration 1.

# BACKUP_COUNT - Number of weekly artifactory backups that are kept. [Default: 2, Minimum: 1]
# CIFS_VERSION - Protocol version. [default 3.0, see README.md for other values]

BACKUP_COUNT=2
CIFS_VERSION="3.0"

# AD_USER - Active Directory username for Windows network share.
# AD_PW - Active Directory password for Windows network share.
# AD_DOMAIN - Active Directory domain name for Windows network share.
# AD_MACHINE - Active Directory machine name for Windows network share.

AD_USER=""
AD_PW=""
AD_DOMAIN=""
AD_MACHINE=""

# MOUNT_POINT - Linux mount point for Windows network share.
# REMOTE_DIR - Backup destination directory structure relative to MOUNT_POINT. [optional parameter]
# FULL_LOCAL_DIR - Absolute path to Linux directory with Artifactory weekly backups.

MOUNT_POINT="${PWD}/test"
REMOTE_DIR="output"
FULL_LOCAL_DIR="${MOUNT_POINT}/input-1"