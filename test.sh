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
TEST_KEY_UID="${TEST_KEY_USERNAME} <${TEST_KEY_EMAIL}>"
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
  assertNotNull "${TEST_KEY_ID}"

  assertTrue "has_valid_secret_keys"

  local signing_keys="$(keys_and_owners sign)"
  local encryption_keys="$(keys_and_owners encrypt)"

  assertEquals "${TEST_KEY_UID}" "$(echo "${signing_keys}" | cut -d: -f2)"
  assertEquals "${TEST_KEY_UID}" "$(echo "${encryption_keys}" | cut -d: -f2)"
  assertTrue "[[ \"$(echo "${signing_keys}" | cut -d: -f1)\" =~ ${TEST_KEY_ID}$ ]]"
  assertTrue "[[ \"$(echo "${encryption_keys}" | cut -d: -f1)\" =~ ${TEST_KEY_ID}$ ]]"
}

test_initialise() {
  initialise

  assertEquals "gpg2" "${GPG}"
  assertEquals "gawk" "${AWK}"

  if [[ "$(uname -s)" =~ Linux|.*BSD|DragonFly ]] && [[ "${DISPLAY}" ]]; then
    assertEquals "xclip -i" "${COPY}"
    assertEquals "xclip -o" "${PASTE}"
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    assertEquals "pbcopy" "${COPY}"
    assertEquals "pbpaste" "${PASTE}"
  fi
}

# Run tests
source "$(which shunit2)"
