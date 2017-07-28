#!/usr/bin/env bash

# License: GPLv3, or later
# Author: Christopher Harrison <ch12@sanger.ac.uk>
# Copyright (c) 2017 Genome Research Ltd.

# This must be run with a clean GnuPG keyring!

source ./secrets

# Force GnuPG2 and Gnu Awk
GPG="gpg2"
AWK="gawk"

TEST_KEY_USERNAME="Testy McTestface"
TEST_KEY_EMAIL="testy@mctestface.com"
TEST_KEY_PASSPHRASE="abc123"
TEST_KEY_ID=""

_gen_key() {
  # Create valid encryption and signing key
  "${GPG}" --batch --gen-key <(cat <<-EOF
	Key-Type: default
	Key-Usage: sign
	Subkey-Type: default
	Subkey-Usage: encrypt
	Name-Real: ${TEST_KEY_USERNAME}
	Name-Email: ${TEST_KEY_EMAIL}
	Expire-Date: 0
	Passphrase: ${TEST_KEY_PASSPHRASE}
	%commit
	EOF
  ) 2>&1 | grep -Eo "key [A-F0-9]+" | cut -d" " -f2
}

test_stderr() {
  assertEquals "foo" "$(stderr "foo" 2>&1)"
}

test_has_dependencies() {
  local -a good_deps=("echo" "ls")
  local -a bad_deps=("__this_is_not_a_command" "__nor_is_this")

  for dep in "${good_deps[@]}"; do
    assertTrue "has_dependencies \"${dep}\""
  done
  assertTrue "has_dependencies ${good_deps[*]}"

  for dep in "${bad_deps[@]}"; do
    assertFalse "has_dependencies \"${dep}i\""
  done
  assertFalse "has_dependencies ${bad_deps[*]}"
}

test_secret_key_handling() {
  assertNull "$(secret_key_ids)"
  assertFalse "has_valid_secret_keys"

  TEST_KEY_ID="$(_gen_key)"

  assertTrue "has_valid_secret_keys"
  assertEquals "${TEST_KEY_USERNAME} <${TEST_KEY_EMAIL}>" "$(key_uids sign)"
  assertEquals "${TEST_KEY_USERNAME} <${TEST_KEY_EMAIL}>" "$(key_uids encrypt)"
}

# Run tests
source "$(which shunit2)"
