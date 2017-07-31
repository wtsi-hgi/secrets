#!/usr/bin/env bash

# License: GPLv3, or later
# Author: Christopher Harrison <ch12@sanger.ac.uk>
# Copyright (c) 2017 Genome Research Ltd.

# IMPORTANT!!
# This must be run with a clean GnuPG keyring!

source ./secrets

# NOTE For debugging only
set +eu +o pipefail

TEST_KEY_USERNAME="Testy McTestface"
TEST_KEY_EMAIL="testy@mctestface.com"
TEST_KEY_UID="${TEST_KEY_USERNAME} <${TEST_KEY_EMAIL}>"
TEST_KEY_PASSPHRASE="abc123"

_gen_key() {
  # Create valid encryption and signing key
  gpg2 --batch --gen-key <(cat <<-EOF
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

_del_key() {
  # Delete public and secret keys by ID
  local key_id="$1"

  local secret_fpr="$(gpg2 --with-colons --with-fingerprint --list-secret-keys "${key_id}" | gawk -F: '$1 == "fpr" { print $10 }')"
  local public_fpr="$(gpg2 --with-colons --with-fingerprint --list-keys "${key_id}" | gawk -F: '$1 == "fpr" { print $10 }')"

  gpg2 --batch --yes --delete-secret-keys "${secret_fpr}"
  gpg2 --batch --yes --delete-keys "${public_fpr}"
}

## Tests

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

test_nonce() {
  for _ in {1..5}; do
    assertTrue "[[ \"$(nonce)\" =~ ^[a-f0-9]{64}$ ]]"
  done
}

## Initialise here

test_initialise() {
  # Initialisation will fail without a valid key
  local test_key_id="$(_gen_key)"

  initialise

  # Delete the key we just created
  _del_key "${test_key_id}"

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

## The following tests must run AFTER initialise has been called

test_sha256() {
  assertEquals "${NULL_DIGEST}" "$(sha256 "")"
  assertEquals "6ca13d52ca70c883e0f0bb101e425a89e8624de51db2d2392593af6a84118090" "$(sha256 "abc123")"
}

test_secret_key_handling() {
  # NOTE This will fail on a system with other secrets keys
  assertNull "$(secret_key_ids)"
  assertFalse "has_valid_secret_keys"

  local test_key_id="$(_gen_key)"
  assertNotNull "${test_key_id}"

  assertTrue "has_valid_secret_keys"

  local signing_keys="$(keys_and_owners sign)"
  local encryption_keys="$(keys_and_owners encrypt)"

  assertEquals "${TEST_KEY_UID}" "$(echo "${signing_keys}" | cut -d: -f2)"
  assertEquals "${TEST_KEY_UID}" "$(echo "${encryption_keys}" | cut -d: -f2)"
  assertTrue "[[ \"$(get_key sign)\" =~ ${test_key_id}$ ]]"
  assertTrue "[[ \"$(get_key encrypt)\" =~ ${test_key_id}$ ]]"

  _del_key "${test_key_id}"
}

# Run tests
source "$(which shunit2)"
