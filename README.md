# cx-sideload

Strict, auditable CLI for running unlisted Windows installers in an existing
CrossOver bottle.

It validates the bottle and installer, reports the SHA-256, preserves arguments
without shell evaluation, and uses CrossOver's `--untrusted` execution path.

## Platform support

| Platform | Status |
| --- | --- |
| macOS with CrossOver or CrossOver Preview | Supported |
| Linux | Not currently supported |
| Windows | Not applicable |

This project is independent and is not affiliated with or endorsed by
CodeWeavers. CrossOver is a CodeWeavers product.

## Requirements

- macOS
- CrossOver or CrossOver Preview
- Bash 3.2 or newer
- Standard macOS utilities: `file`, `shasum`, `tr`, `dirname`, and `basename`

There are no additional runtime dependencies. ShellCheck is required only for
development.

## Install

```sh
install -m 0755 bin/cx-sideload "$HOME/.local/bin/cx-sideload"
```

Ensure `$HOME/.local/bin` is in `PATH`.

## Usage

```sh
cx-sideload --list-bottles
cx-sideload --bottle Research --dry-run ~/Downloads/setup.exe
cx-sideload --bottle Research ~/Downloads/setup.exe
cx-sideload --bottle Research --sha256 HASH ~/Downloads/setup.exe /S
cx-sideload --bottle Research ~/Downloads/package.msi /qn
```

Run `cx-sideload --help` for all options.

## Security

A CrossOver bottle is not a strong security sandbox. Only run software you are
authorized to use and trust. Prefer `--sha256` with a digest obtained through an
independent channel.

The helper does not create, delete, stop, or reset bottles. See
[SECURITY.md](SECURITY.md) for the security model and reporting instructions.

## Development

```sh
make check
```

This runs Bash syntax validation, strict ShellCheck analysis, and isolated local
tests. CI is intentionally deferred; see [ROADMAP.md](ROADMAP.md).

## License

[MIT](LICENSE)
