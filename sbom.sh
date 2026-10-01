#!/bin/sh
# Emit a CycloneDX 1.5 SBOM (JSON) listing every package in a dune.lock directory as pkg:opam/<name>@<version>.
#
#   sbom.sh [dune.lock-dir] > sbom.cdx.json
set -eu

lockdir=${1:-dune.lock}

die() {
  echo "sbom.sh: $*" >&2
  exit 2
}

[ -d "$lockdir" ] || die "$lockdir is not a directory"

components=
for f in "$lockdir"/*.pkg; do
  [ -e "$f" ] || die "no *.pkg in $lockdir"
  stem=$(basename "$f" .pkg)
  name=${stem%%.*}
  version=$(sed -n 's/^(version \(.*\))$/\1/p' "$f" | head -n 1)
  [ -n "$version" ] || version=${stem#"$name".}
  # Values are interpolated into JSON verbatim, so reject anything opam would never produce.
  case "$name$version" in
    *[!A-Za-z0-9._+~-]*) die "unexpected characters in $f" ;;
  esac
  component=$(printf '{"type":"library","name":"%s","version":"%s","purl":"pkg:opam/%s@%s"}' \
    "$name" "$version" "$name" "$version")
  components=${components:+$components,}$component
done

printf '{"bomFormat":"CycloneDX","specVersion":"1.5","version":1,"components":[%s]}\n' "$components"
