# dune-lock-osv

A GitHub Action that checks the packages pinned in a [dune package management](https://dune.readthedocs.io/en/stable/explanation/package-management.html) lock directory (`dune.lock/`) for known vulnerabilities on [OSV.dev](https://osv.dev/list?ecosystem=opam).

General-purpose scanners (osv-scanner, Syft, opam-audit, ...) do not read `dune.lock/`. This action converts it to a CycloneDX SBOM with `pkg:opam/<name>@<version>` purls and hands it to [osv-scanner](https://github.com/google/osv-scanner), which knows the [OCaml security advisories](https://github.com/ocaml/security-advisories) through OSV.dev.

## Usage

```yaml
on:
  pull_request:
    paths: [ 'dune.lock/**' ]
  schedule:
    - cron: '0 0 * * *'

permissions:
  contents: read
  issues: write # only for create-issue

jobs:
  osv:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: lmdexpr/dune-lock-osv@<sha>
        with:
          create-issue: ${{ github.event_name == 'schedule' }}
```

The markdown report is appended to the job summary. The SBOM and the report paths are exposed as outputs, e.g. to upload them as artifacts.

## Inputs

| name | default | description |
| --- | --- | --- |
| `lockdir` | `dune.lock` | Path to the lock directory |
| `osv-scanner-version` | `v2.5.1` | osv-scanner release tag (verified against the release's SHA256SUMS) |
| `fail-on-findings` | `true` | Fail when vulnerabilities are found. Scanner errors always fail |
| `create-issue` | `false` | Open a single issue (or update its body) when vulnerabilities are found |
| `issue-title` | `security: known vulnerabilities in dune.lock (OSV.dev)` | Title used to find and create the issue |
| `issue-labels` | `security,dependencies` | Comma-separated labels; missing labels are created |
| `github-token` | `${{ github.token }}` | Token used by `create-issue` |

## Outputs

| name | description |
| --- | --- |
| `exit-code` | osv-scanner exit code (`0`: clean, `1`: vulnerabilities found, other: scanner error) |
| `sbom` | Path to the generated CycloneDX SBOM |
| `report` | Path to the markdown report |

## Requirements and limitations

- Linux runners (x86_64 / arm64) with `curl` and `sha256sum`. In a minimal container (e.g. `debian`), install `ca-certificates` and `curl` first.
- Packages pinned to a git source usually carry a non-release version (e.g. `dev`) and are never matched by OSV.
- `dune.lock/` is the format of dune's experimental package management, so it may change with dune releases.

The SBOM generator can also be used on its own:

```sh
./sbom.sh dune.lock > sbom.cdx.json
```

## License

MIT
