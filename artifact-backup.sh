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
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")


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

check_idle_artifactory()
{
  local unfinished
  unfinished=$(find "${FULL_SRC_DIR}" -maxdepth 1 -type d -regextype sed -regex "${TMP_DIR_REGEX}")
  if [ -n "${unfinished}" ]; then
    # This indicates a new weekly backup is in progress and it isn't safe to proceed.
    close_network
    exit 1
  fi
}

backup_newest_weekly()
{
  local local_newest remote_newest tarfile
  cd "${FULL_DEST_DIR}"
  remote_newest=$(find . -maxdepth 1 -type f -regextype sed -regex "${BACKUP_FILE_REGEX}" | sort -n -r | head -1)
  if [ -n "${remote_newest}" ] && [ ! -s "${remote_newest}" ]; then
    echo "Remote tarball is zero bytes, removing it."
    rm -f "${remote_newest}"
  fi
  cd -
  cd "${FULL_SRC_DIR}"
  local_newest=$(find . -maxdepth 1 -type d -regextype sed -regex "${BACKUP_DIR_REGEX}" | sort -n -r | head -1)
  if [ "${remote_newest}" = "${local_newest}.tar" ]; then
    echo "Up-to-date backup"
    return
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
  if [ -n "${remote_count}" ] && [[ "${remote_count}" -gt ${BACKUP_COUNT} ]]; then
    remote_oldest=$(find "${FULL_DEST_DIR}" -maxdepth 1 -type f -regextype sed -regex "${BACKUP_FILE_REGEX}" | sort -n | head -1)
    echo "Removing oldest tarball backup - ${remote_oldest}"
    rm -f "${remote_oldest}"
  fi
}

close_network()
{
  local mounted
  mounted=$(mount | grep "${MOUNT_POINT}" || true)
  if [ -n "${mounted}" ]; then
    echo "Unmounting remote backup machine!"
    umount "${MOUNT_POINT}"
  fi
}

show_app_usage()
{
  echo "Usage: ${0} [OPTION]"
  echo "${APP_NAME}."
  echo "Examples: ${0}"
  echo "          ${0} &> log.txt"
  echo
  echo "Options:"
  echo " -t, --test <CASE>    Run test case called <CASE>"
  echo " -h, --help           This help text"
  echo " -v, --version        Show version and development link"
  echo
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

show_app_error()
{
  echo "Error: Unable to find configuration file - ${CFG_FILE}"
  echo
  echo "Solution:"
  echo "Step 1) cp template-cfg.sh ${CFG_FILE}"
  echo "Step 2) Setup global variables so they match your Artifactory and network backup solution."
}


################################################################################
# Main

# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
while [[ "$#" -gt 0 ]]; do
  case $1 in
  "-t" | "--test")
    if [[ "$#" -gt 1 ]]; then
      test_cfg="${SCRIPT_DIR}/test/test-$2-cfg.sh"
      if [ -s "${test_cfg}" ]; then
        # shellcheck source=test/test-1-cfg.sh
        source "${test_cfg}"
        FULL_DEST_DIR="${MOUNT_POINT}/${DEST_DIR}"
        TEST=1
        shift; shift
      else
        show_app_test_error "${test_cfg}"
        exit 1
      fi
    else
      show_app_usage
      exit 1
    fi
    ;;
  "-h" | "--help")
    show_app_usage
    exit 0
    ;;
  "-v" | "--version")
    show_app_version
    exit 0
    ;;
  *)
    echo "Unknown parameter passed: $1"
    exit 1
    ;;
  esac
done


if [ ${TEST} -eq 0 ]; then
  if [ -s "${SCRIPT_DIR}/${CFG_FILE}" ]; then
    # shellcheck source=template-cfg.sh
    source "${SCRIPT_DIR}/${CFG_FILE}"
    FULL_DEST_DIR="${MOUNT_POINT}/${DEST_DIR}"
  else
    show_app_error
    exit 1
  fi
  check_config
  check_mount_point
fi
check_idle_artifactory
backup_newest_weekly
cleanup_network_backups
close_network

exit 0
