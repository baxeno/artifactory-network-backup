#!/usr/bin/env bash

################################################################################
# Bash script that copies lastest weekly backup from a Windows network share
# an Artifactory server on Linux. In case of desaster recovery this need to
# happen before backup import using Artifactory web interface.

set -u # Exit script when using an uninitialised variable
set -e # Exit script when a statement returns a non-true value
#set -x # Debug during development


################################################################################
# Configuration variables are loaded from CFG_FILE.


################################################################################
# Constants

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
CFG_FILE="live-cfg.sh"
DIRECTION="from"


################################################################################
# Functions


################################################################################
# Main


# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
TEST=0
while [[ "$#" -gt 0 ]]; do
  case $1 in
  "-t" | "--test")
    if [[ "$#" -gt 1 ]]; then
      test_cfg="${SCRIPT_DIR}/test/test-$2-cfg.sh"
      if [ -s "${test_cfg}" ]; then
        # shellcheck source=test/test-restore-cfg.sh
        source "${test_cfg}"
        FULL_REMOTE_DIR="${MOUNT_POINT}/${DEST_DIR}"
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
    FULL_REMOTE_DIR="${MOUNT_POINT}/${REMOTE_DIR}"
  else
    show_app_error
    exit 1
  fi
  check_config
  check_mount_point
fi
restore_newest_weekly
close_network

exit 0
