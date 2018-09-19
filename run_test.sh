#!/usr/bin/env bash

set -u # Exit script when using an uninitialised variable
set -e # Exit script when a statement returns a non-true value
#set -x # Debug during development

OUT="test/output"
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

INIT()
{
  TC="$1"
  echo "${TC}: Init test case"
  rm -rf "${OUT}"
  mkdir "${OUT}"
}

TEARDOWN()
{
  echo "${TC}: Completed test case"
  rm -rf "${OUT}"
  TC=""
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
INIT "Kernel module"
CHECK_KERNEL_MODULE "fs/cifs"
TEARDOWN

PRINT "Run test: Sunshine backup"
INIT "Sunshine"
PRINT "First weekly backup iteration"
EXPECT_ZERO ./artifact-backup.sh -test 1
EXPECT_EXIST "${OUT}/20180908.020000.tar"
EXPECT_NOT_EXIST "${OUT}/20180915.020000.tar"
EXPECT_NOT_EXIST "${OUT}/20180922.020000.tar"

PRINT "Second weekly backup iteration"
EXPECT_ZERO ./artifact-backup.sh -test 2
EXPECT_EXIST "${OUT}/20180908.020000.tar"
EXPECT_EXIST "${OUT}/20180915.020000.tar"
EXPECT_NOT_EXIST "${OUT}/20180922.020000.tar"

PRINT "Third weekly backup iteration"
EXPECT_ZERO ./artifact-backup.sh -test 3
EXPECT_NOT_EXIST "${OUT}/20180908.020000.tar"
EXPECT_EXIST "${OUT}/20180915.020000.tar"
EXPECT_EXIST "${OUT}/20180922.020000.tar"
TEARDOWN

PRINT "Run test: About network backup when Artifactory backup is ongoing"
INIT "Ongoing"
EXPECT_NON_ZERO ./artifact-backup.sh -test tmp
EXPECT_NOT_EXIST "${OUT}/20180808.020000.tmp.tar"
TEARDOWN

PRINT "All tests completed"
exit 0
