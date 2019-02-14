#!/usr/bin/env bash

################################################################################
# Bash script contain common defines and functions that are shared between
# artifact-backup.sh and artifact-restore.sh


################################################################################
# Constants

APP_VERSION="0.1.0"
APP_NAME="Transfers Artifactory weekly backup to a CIFS/SMB network share"
APP_GITHUB="https://github.com/baxeno/artifactory-network-backup"
TMP_DIR_REGEX='.*/[0-9]\{8\}\.[0-9]\{6\}\.tmp$'
BACKUP_DIR_REGEX='.*/[0-9]\{8\}\.[0-9]\{6\}'
BACKUP_FILE_REGEX='.*/[0-9]\{8\}\.[0-9]\{6\}\.tar'


################################################################################
# Functions

check_config()
{
  if [ -z "${AD_USER}" ] || [ -z "${AD_PW}" ] || [ -z "${AD_DOMAIN}" ] || [ -z "${AD_MACHINE}" ]; then
    echo "ERROR! Active Directory (AD) credentials or domain joined machine missing!"
    exit 1
  fi
  if [ -z "${MOUNT_POINT}" ] || [ -z "${FULL_LOCAL_DIR}" ]; then
    echo "ERROR! Mount point or Artifactory backup location missing!"
    exit 1
  fi
}

check_mount_point()
{
  local mounted
  mounted=$(mount | grep "${MOUNT_POINT}" || true)
  if [ -z "${mounted}" ]; then
    echo "Mounting remote backup machine!"
    mkdir -p "${MOUNT_POINT}"
    mount -t cifs \
      -o "username=${AD_USER},password=${AD_PW},domain=${AD_DOMAIN},vers=${CIFS_VERSION}" \
      "//${AD_MACHINE}/data" \
      "${MOUNT_POINT}" \
      --verbose
  fi
}

show_app_version()
{
  echo "${APP_NAME} v${APP_VERSION}"
  echo "Development: ${APP_GITHUB}"
}

show_app_test_error()
{
  echo "Error: Unable to find test configuration file - ${1}"
}
