# Security

## Reporting

Do not disclose suspected vulnerabilities in a public issue. Use the repository's
GitHub Security Advisory reporting flow and include a minimal reproduction,
affected revision, and impact.

## Security model

`cx-sideload` validates local inputs before invoking CrossOver, but it does not
make untrusted Windows software safe. CrossOver bottles may expose host files,
network access, credentials, and other user resources.

The helper is designed to reduce accidental misuse and command-construction
risks. It does not defend against an attacker who already controls the user's
account, CrossOver installation, bottle contents, or operating system.

Security-sensitive defaults include:

- explicit target-bottle selection;
- strict bottle-name validation;
- rejection of symlinked installers and bottles;
- executable-type inspection;
- SHA-256 reporting and optional pinning;
- a second digest check immediately before execution;
- CrossOver's `--untrusted` execution path;
- no shell evaluation of installer arguments; and
- no logging of installer arguments.
