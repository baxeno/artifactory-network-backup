#!/usr/bin/env bash

################################################################################
# Bash script that copies lastest weekly backup from an Artifactory server on
# Linux to a Windows network share. Including removing oldest weekly backup
# from network share.

set -u # Exit script when using an uninitialised variable
set -e # Exit script when a statement returns a non-true value
#set -x # Debug during development


################################################################################
# Global variables (most are loaded from CFG_FILE)
#
# TEST - Test mode [0: disabled, 1: enabled].
# BACKUP_COUNT - Number of weekly artifactory backups that are kept.
# CIFS_VERSION - Protocol version (3.0 = Windows Server 2012).
# CFG_FILE - Configuration file which makes updating this file from git easier.
# AD_USER - Active Directory username for Windows network share.
# AD_PW - Active Directory password for Windows network share.
# AD_DOMAIN - Active Directory domain name for Windows network share.
# AD_MACHINE - Active Directory machine name for Windows network share.
# MOUNT_POINT - Linux mount point for Windows network share.
# DEST_DIR - Backup destination directory structure relative to MOUNT_POINT.
# FULL_SRC_DIR - Absolute path to Linux directory with Artifactory weekly backups.

TEST=0
BACKUP_COUNT=2
CIFS_VERSION="3.0"
CFG_FILE="live-cfg.sh"


################################################################################
# Constants

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
  if [ -z "${MOUNT_POINT}" ] || [ -z "${FULL_SRC_DIR}" ]; then
    echo "ERROR! Mount point or Artifactory backup location missing!"
    exit 1
  fi
}

check_mount_point()
{
  local mounted
  mounted=$(mount | grep "${MOUNT_POINT}")
  if [ -z "${mounted}" ]; then
    echo "Remote backup machine not mounted!"
    mkdir -p "${MOUNT_POINT}"
    mount -t cifs \
      -o "username=${AD_USER},password=${AD_PW},domain=${AD_DOMAIN},vers=3.0" \
      "//${AD_MACHINE}/data" \
      "${MOUNT_POINT}" \
      --verbose
  fi
}

check_idle_artifactory()
{
  local unfinished
  unfinished=$(find "${FULL_SRC_DIR}" -maxdepth 1 -type d -regextype sed -regex "${TMP_DIR_REGEX}")
  if [ -n "${unfinished}" ]; then
    exit 1
  fi
}

backup_newest_weekly()
{
  local local_newest remote_newest tarfile
  cd "${FULL_DEST_DIR}"
  remote_newest=$(find . -maxdepth 1 -type f -regextype sed -regex "${BACKUP_FILE_REGEX}" | sort -n -r | head -1)
  if [ -n ${remote_newest} ] && [ ! -s "${remote_newest}" ]; then
    echo "Remote tarball is zero bytes, removing it."
    rm -f "${remote_newest}"
  fi
  cd -
  cd "${FULL_SRC_DIR}"
  local_newest=$(find . -maxdepth 1 -type d -regextype sed -regex "${BACKUP_DIR_REGEX}" | sort -n -r | head -1)
  if [ "${remote_newest}" = "${local_newest}.tar" ]; then
    echo "Up-to-date backup"
    exit 0
  fi
  tarfile="${FULL_DEST_DIR}/${local_newest}.tar"
  echo "Backup from: ${local_newest}"
  echo "Backup to: ${tarfile}"
  tar -cf "${tarfile}" "${local_newest}"
  cd -
}

cleanup_network_backups()
{
  remote_count=$(find "${FULL_DEST_DIR}" -maxdepth 1 -type f -regextype sed -regex "${BACKUP_FILE_REGEX}" | wc -l)
  if [ -n ${remote_count} ] && [[ "${remote_count}" -gt ${BACKUP_COUNT} ]]; then
    remote_oldest=$(find "${FULL_DEST_DIR}" -maxdepth 1 -type f -regextype sed -regex "${BACKUP_FILE_REGEX}" | sort -n | head -1)
    echo "Removing oldest tarball backup - ${remote_oldest}"
    rm -f "${remote_oldest}"
  fi
}


################################################################################
# Main

if [ "$#" -eq 2 ]; then
  if [[ "$1" == "-test" ]]; then
    # shellcheck source=test/test-1-cfg.sh
    source "test/test-$2-cfg.sh"
    TEST=1
  else
    echo "Usage: $0 -test <type>"
    exit 1
  fi
else
  if [ -s "${CFG_FILE}" ]; then
    # shellcheck source=live-cfg.sh
    source "${CFG_FILE}"
  else
    echo "Error: Unable to load configuration file - ${CFG_FILE}"
    exit 1
  fi
fi
FULL_DEST_DIR="${MOUNT_POINT}/${DEST_DIR}"

if [ ${TEST} -eq 0 ]; then
  check_config
  check_mount_point
fi
check_idle_artifactory
backup_newest_weekly
cleanup_network_backups

exit 0
