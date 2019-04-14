#!/usr/bin/env bash

set -u # Exit script when using an uninitialised variable
set -e # Exit script when a statement returns a non-true value
#set -x # Debug during development

REMOTE="test/remote"
LOCAL="test/local"
RESTORE_REMOTE="test/input-restore"
TC=""


################################################################################
# Functions

PRINT()
{
  if [ -z "${TC}" ]; then
    echo "========== $1 =========="
  else
    echo "${TC}: $1"
  fi
}

INIT_BACKUP()
{
  TC="$1"
  echo "--- ${TC}: Init test case ---"
  mkdir -p "${REMOTE}"
}

TEARDOWN_BACKUP()
{
  echo "--- ${TC}: Completed test case ---"
  rm -rf "${REMOTE}"
  TC=""
  echo
}

INIT_RESTORE()
{
  TC="$1"
  echo "--- ${TC}: Init test case ---"
  mkdir -p "${LOCAL}"
}

TEARDOWN_RESTORE()
{
  echo "--- ${TC}: Completed test case ---"
  rm -rf "${LOCAL}"
  TC=""
  echo
}

EXPECT_ZERO()
{
  set +e
  # shellcheck disable=SC2068
  $@
  local res=$?
  if [ $res -eq 0 ]; then
    echo "${TC}: ZERO: OK"
  else
    echo "${TC}: ZERO: ERROR - Unexpected exit code: $res"
    exit 1
  fi
  set -e
}

EXPECT_NON_ZERO()
{
  set +e
  # shellcheck disable=SC2068
  $@
  local res=$?
  if [ $res -ne 0 ]; then
    echo "${TC}: NON ZERO: OK"
  else
    echo "${TC}: NON ZERO: ERROR - Unexpected exit code: $res"
    exit 1
  fi
  set -e
}

EXPECT_EXIST()
{
  if [ -s "$1" ]; then
    echo "${TC}: EXIST: OK"
  else
    echo "${TC}: EXIST: ERROR - Expected file does not exist: $1"
    exit 1
  fi
}

EXPECT_NOT_EXIST()
{
  if [ -s "$1" ]; then
    echo "${TC}: NOT EXIST: ERROR - File should not exist: $1"
    exit 1
  else
    echo "${TC}: NOT EXIST: OK"
  fi
}

CHECK_KERNEL_MODULE()
{
  set +e
  res=$(find "/lib/modules/$(uname -r)/kernel" | grep "$1")
  set -e
  if [ -n "${res}" ]; then
    echo "${TC}: KERNEL MODULE: OK"
  else
    echo "${TC}: KERNEL MODULE: ERROR - Not found"
    exit 1
  fi
}

################################################################################
# Test cases

PRINT "Running all tests"

PRINT "Run test: Kernel module fs/cifs present"
CHECK_KERNEL_MODULE "fs/cifs"

PRINT "Run test: Arguments for artifact backup script."
INIT_BACKUP "Help menu"
EXPECT_ZERO ./scripts/artifact-backup.sh -h
EXPECT_ZERO ./scripts/artifact-backup.sh --help
EXPECT_ZERO ./scripts/artifact-backup.sh --help me
TEARDOWN_BACKUP
INIT_BACKUP "Version menu"
EXPECT_ZERO ./scripts/artifact-backup.sh -v
EXPECT_ZERO ./scripts/artifact-backup.sh --version
EXPECT_ZERO ./scripts/artifact-backup.sh --version now
TEARDOWN_BACKUP
INIT_BACKUP "Test menu"
EXPECT_NON_ZERO ./scripts/artifact-backup.sh -t
EXPECT_NON_ZERO ./scripts/artifact-backup.sh --test
EXPECT_NON_ZERO ./scripts/artifact-backup.sh --test invalid argument
TEARDOWN_BACKUP

PRINT "Run test: Arguments for artifact restore script."
INIT_BACKUP "Help menu"
EXPECT_ZERO ./scripts/artifact-backup.sh -h
EXPECT_ZERO ./scripts/artifact-backup.sh --help
EXPECT_ZERO ./scripts/artifact-backup.sh --help me
TEARDOWN_BACKUP
INIT_BACKUP "Version menu"
EXPECT_ZERO ./scripts/artifact-backup.sh -v
EXPECT_ZERO ./scripts/artifact-backup.sh --version
EXPECT_ZERO ./scripts/artifact-backup.sh --version now
TEARDOWN_BACKUP
INIT_BACKUP "Test menu"
EXPECT_NON_ZERO ./scripts/artifact-backup.sh -t
EXPECT_NON_ZERO ./scripts/artifact-backup.sh --test
EXPECT_NON_ZERO ./scripts/artifact-backup.sh --test invalid argument
TEARDOWN_BACKUP

PRINT "Run test: Sunshine backup. Expect: Remove oldest backup on 3rd iteration."
INIT_BACKUP "Sunshine backup"
PRINT "First weekly backup iteration"
EXPECT_ZERO ./scripts/artifact-backup.sh --test 1
EXPECT_EXIST "${REMOTE}/20180908.020000.tar"
EXPECT_NOT_EXIST "${REMOTE}/20180915.020000.tar"
EXPECT_NOT_EXIST "${REMOTE}/20180922.020000.tar"

PRINT "Second weekly backup iteration"
EXPECT_ZERO ./scripts/artifact-backup.sh --test 2
EXPECT_EXIST "${REMOTE}/20180908.020000.tar"
EXPECT_EXIST "${REMOTE}/20180915.020000.tar"
EXPECT_NOT_EXIST "${REMOTE}/20180922.020000.tar"

PRINT "Third weekly backup iteration"
EXPECT_ZERO ./scripts/artifact-backup.sh --test 3
EXPECT_NOT_EXIST "${REMOTE}/20180908.020000.tar"
EXPECT_EXIST "${REMOTE}/20180915.020000.tar"
EXPECT_EXIST "${REMOTE}/20180922.020000.tar"
TEARDOWN_BACKUP

PRINT "Run test: Abort network backup when Artifactory backup is ongoing. Expect: New weekly backup is in progress and it isn't safe to proceed."
INIT_BACKUP "Ongoing"
EXPECT_NON_ZERO ./scripts/artifact-backup.sh --test tmp
EXPECT_NOT_EXIST "${REMOTE}/20180808.020000.tmp.tar"
TEARDOWN_BACKUP

PRINT "Run test: Restore newest network backup. Expect: Backup needs to be restored."
INIT_RESTORE "Sunshine backup restore"
# Remote directory contain 2 backups
EXPECT_EXIST "${RESTORE_REMOTE}/20180915.020000.tar"
EXPECT_EXIST "${RESTORE_REMOTE}/20180922.020000.tar"
EXPECT_ZERO ./scripts/artifact-restore.sh --test restore
# Remote directory still contain 2 backups as they are left intact.
EXPECT_EXIST "${RESTORE_REMOTE}/20180915.020000.tar"
EXPECT_EXIST "${RESTORE_REMOTE}/20180922.020000.tar"
# Backups are not just copied to local directory.
EXPECT_NOT_EXIST "${LOCAL}/20180915.020000.tar"
EXPECT_NOT_EXIST "${LOCAL}/20180922.020000.tar"
# Correct backup tarball is extracted to local directory.
EXPECT_NOT_EXIST "${LOCAL}/20180915.020000"
EXPECT_EXIST "${LOCAL}/20180922.020000"
TC=""; echo # TEARDOWN_RESTORE # We want to reuse remote directory content in next test.

PRINT "Run test: Abort network backup restore. Expect: Local backup is up-to-date."
INIT_RESTORE "Abort backup restore"
# Newest backup is already extracted in local directory.
EXPECT_EXIST "${LOCAL}/20180922.020000"
# Remote directory contain 2 backups
EXPECT_EXIST "${RESTORE_REMOTE}/20180915.020000.tar"
EXPECT_EXIST "${RESTORE_REMOTE}/20180922.020000.tar"
# Run restore script
EXPECT_ZERO ./scripts/artifact-restore.sh --test restore
# Newest backup is local directory is left intact.
EXPECT_NOT_EXIST "${LOCAL}/20180915.020000"
EXPECT_EXIST "${LOCAL}/20180922.020000"
TEARDOWN_RESTORE

PRINT "All tests completed"
exit 0
