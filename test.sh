#!/usr/bin/env bash

# License: GPLv3, or later
# Author: Christopher Harrison <ch12@sanger.ac.uk>
# Copyright (c) 2017 Genome Research Ltd.

TEST_KEY_ID=""

_gen_key() {
  # Create valid encryption and signing key
  gpg2 --batch --gen-key <(cat <<-EOF
	Key-Type: default
	Key-Usage: sign
	Subkey-Type: default
	Subkey-Usage: encrypt
	Name-Real: Testy McTestface
	Name-Email: testy@mctestface.com
	Expire-Date: 0
	Passphrase: abc123
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

test_has_valid_secret_keys() {
  # This should fail before any secret keys have been defined
  assertFalse "has_valid_secret_keys"

  TEST_KEY_ID="$(_gen_key)"

  # Now we should be good to go
  assertTrue "has_valid_secret_keys"
}

# Run tests
source ./secrets
source "$(which shunit2)"
