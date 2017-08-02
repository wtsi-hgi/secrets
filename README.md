# Secrets

[![Build Status](https://travis-ci.org/wtsi-hgi/secrets.svg?branch=master)](https://travis-ci.org/wtsi-hgi/secrets)

A command line based secrets manager.

## Usage

    secrets SUBCOMMAND [OPTIONS]
    secrets (-V | --version)
    secrets (-h | --help)

The `-h` or `--help` option can be used against any subcommand for
details.

## Subcommands

### `keep`

    secrets keep [OPTIONS] SECRET_ID [SECRET]

Keep a secret with the identifier of `SECRET_ID`. The secret can be
specified with the plaintext given in `SECRET`, or generated following
the rule policy provided by the options.

Options:

    --secrets FILE        Secrets file [~/.secrets]
    --force               Overwrite the secret if it already exists
    --length LENGTH       Length [16]
    --allowed CLASS       Class of allowed characters [a-zA-Z0-9!?$%&=+_-]
    --must-include CLASS  Class of characters that must be included (this
                          option can be provided multiple times)
    --copy                Copy the generated secret to the clipboard, if
                          supported, rather than outputting to stdout
    --expire SECONDS      Delete the secret from the clipboard, if used,
                          after a time limit [30]

The default policy will generate a secret with 284 bits of entropy.

If the secrets file has not yet been created, you will be prompted for
your GnuPG encryption and signing key IDs.

You mustn't supply more `--must-include` arguments than the `--length`,
otherwise an error will be raised. Also note that the `--allowed` and
`--must-include` classes may be mutually exclusive.

**Warning** Specifying the secret in the command line is dangerous, as
it will be preserved in your shell history. If you must do this, rather
than generating a random password, then you're advised to add a layer of
indirection. For example, in Bash:

    secrets keep [OPTIONS] SECRET_ID "$(read -rsp "Secret: " X && echo "$X")"

### `tell`

    secrets tell [OPTIONS] SECRET_ID

Tell the secret with the identifier of `SECRET_ID`.

Options:

    --secrets FILE        Secrets file [~/.secrets]
    --copy                Copy the secret to the clipboard, if supported,
                          rather than outputting to stdout
    --expire SECONDS      Delete the secret from the clipboard, if used,
                          after a time limit [30]

### `expose`

    secrets expose [OPTIONS]

Expose the list of all the available secret IDs.

Options:

    --secrets FILE        Secrets file [~/.secrets]
    --with-date           Include the date the secret was kept

### `forget`

    secrets tell [OPTIONS] SECRET_ID

Forget the secret with the identifier of `SECRET_ID`.

Options:

    --secrets FILE        Secrets file [~/.secrets]

## Installation

<!-- TODO -->

### Dependencies

The following dependencies are required:

* Bash 4.2, or newer
* [GnuPG](https://gnupg.org/)
* A means to calculate SHA256 digests (either `sha256sum` or OpenSSL)

You will need at least one valid encryption and signing key.

For clipboard support, the following dependencies are needed:

* macOS: `pbcopy` and `pbpaste`
* Linux: `xclip`

## Why Not Just Use `pass`?

<p align="center"><img alt="xkcd Standards" src="https://imgs.xkcd.com/comics/standards.png"></p>

`secrets` was inspired by Jason A. Donenfeld's [`pass`](https://www.passwordstore.org/),
but with several key differences:

* Secrets are stored in a single database, so no metadata (from the
  secret IDs, for instance) is leaked. [`pass-tomb`](https://github.com/roddhjav/pass-tomb)
  provides a similar function for `pass`, but at the expense of
  complexity.

* `secrets` has a much simpler interface, yet it provides all the useful
  functionality of `pass`, plus a few neat tricks of its own.

* The secrets database is structured as a self-validating blockchain
  audit log, for additional security.

* No automatic Git integration, so you can use a VCS of your choice
  and/or manage the version control of your database how you prefer (if
  you wish).

Think of `secrets` as `pass-lite`!
