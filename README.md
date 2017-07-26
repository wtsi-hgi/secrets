# Secrets

A command line based secret manager.

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

The default policy will generate a secret with 284 bits of entropy.

If the secrets file has not yet been created, you will be prompted for
your GnuPG encryption and signing key IDs.

### `tell`

    secrets tell [OPTIONS] SECRET_ID

Tell the secret with the identifier of `SECRET_ID`.

Options:

    --secrets FILE        Secrets file [~/.secrets]
    --copy                Copy the secret to the clipboard, if supported,
                          rather than outputting to stdout
    --expire SECONDS      Delete the secret from the clipboard, if used,
                          after a time limit [30]

### `forget`

    secrets tell [OPTIONS] SECRET_ID

Forget the secret with the identifier of `SECRET_ID`.

Options:

    --secrets FILE        Secrets file [~/.secrets]


## Dependencies

The following dependencies are required:

* [GnuPG](https://gnupg.org/)
* [jq](https://stedolan.github.io/jq/)

<!-- Clipboard support? -->
