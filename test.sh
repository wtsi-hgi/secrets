#!/usr/bin/env bash

# License: GPLv3, or later
# Author: Christopher Harrison <ch12@sanger.ac.uk>
# Copyright (c) 2017 Genome Research Ltd.

# IMPORTANT!!
# This must be run with a clean GnuPG keyring!

source ./secrets

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

_mock() {
  local stdin="$(cat -)"

  echo "$*"        # Arguments on first line, get with `head -1`
  echo "${stdin}"  # stdin otherwise, get with `sed 1d`
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

test_escaping() {
  local -a to_test=("foo" "foo bar" "foo	bar")

  for t in "${to_test[@]}"; do
    assertEquals "${t}" "$(unescape "$(escape "${t}")")"
  done
}

test_random_string() {
  # Password generation relies on this
  local password

  for test_class in "a-z" "a-zA-Z" "a-zA-Z0-9" 'a-zA-Z0-9!?$%&=+_-'; do
    for test_length in {10..20..2}; do
      password="$(random_string "${test_length}" "${test_class}")"
      assertEquals "${password}" "$(grep -Eo "^[${test_class}]{${test_length}}$" <<< "${password}")"
    done
  done
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

test_blockchain() {
  # This is a pretty blunt instrument :P
  local test_key_id="$(_gen_key)"
  local full_key_id="$(get_key sign)"

  assertTrue "(( \"${#BLOCKCHAIN[@]}\" == 0 ))"

  add_block "foo" "bar" "quux" 2>/dev/null
  add_block "xyzzy" "123" 2>/dev/null

  assertTrue "(( \"${#BLOCKCHAIN[@]}\" == 3 ))"

  assertTrue "validate_block -1"
  assertTrue "validate_block 0"
  assertTrue "validate_chain"

  assertFalse "scan_blockchain_for_secrets"
  add_block "keep" "foo" "abc123" 2>/dev/null
  assertTrue "scan_blockchain_for_secrets foo"
  add_block "forget" "foo" 2>/dev/null
  assertFalse "scan_blockchain_for_secrets foo"

  # We can't test writing and reading the blockchain without pinentry,
  # at least with GnuPG 2, so instead we mock GnuPG calls :P
  local _gpg="${GPG}"
  GPG="_mock"

  local output_file="blockchain"
  local expected_args="--no-tty --yes --sign --local-user ${full_key_id} --encrypt --recipient ${full_key_id} --output ${output_file}"
  local expected_contents="$(for block in "${BLOCKCHAIN[@]}"; do echo "${block}"; done)"

  local output="$(write_blockchain "${output_file}")"
  assertEquals "${expected_args}" "$(head -1 <<< "${output}")"
  assertEquals "${expected_contents}" "$(sed 1d <<< "${output}")"

  # Reset mock
  GPG="${_gpg}"

  _del_key "${test_key_id}"
}

# Run tests
source "$(which shunit2)"
