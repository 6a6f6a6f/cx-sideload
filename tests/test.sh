#!/usr/bin/env bash

set -euo pipefail

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$1"
  passed=$((passed + 1))
}

assert_contains() {
  local output="$1"
  local expected="$2"
  local label="$3"

  [[ "${output}" == *"${expected}"* ]] || fail "${label}: missing output: ${expected}"
  pass "${label}"
}

assert_fails_with() {
  local expected="$1"
  local label="$2"
  local output
  shift 2

  if output="$("$@" 2>&1)"; then
    fail "${label}: command unexpectedly succeeded"
  fi
  [[ "${output}" == *"${expected}"* ]] || fail "${label}: missing error: ${expected}"
  pass "${label}"
}

cleanup() {
  case "${test_root}" in
    "${TMPDIR:-/tmp}"/cx-sideload-test.*)
      rm -rf -- "${test_root}"
      ;;
    *)
      printf 'refusing to remove unexpected test path: %s\n' "${test_root}" >&2
      ;;
  esac
}

script_dir="$(cd -P "$(/usr/bin/dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly script_dir
readonly helper="${script_dir}/../bin/cx-sideload"

test_root="$(mktemp -d "${TMPDIR:-/tmp}/cx-sideload-test.XXXXXX")"
readonly test_root
trap cleanup EXIT

readonly bottles_dir="${test_root}/Bottles"
readonly bottle_dir="${bottles_dir}/Research"
readonly crossover_app="${test_root}/CrossOver Preview.app"
readonly wine_path="${crossover_app}/Contents/SharedSupport/CrossOver/bin/wine"
readonly installer_dir="${test_root}/Installers With Spaces"
readonly installer="${installer_dir}/setup.exe"
readonly bad_msi="${installer_dir}/not-an-installer.msi"
readonly symlink_installer="${installer_dir}/setup-link.exe"
readonly injection_marker="${test_root}/injected"

mkdir -p "${bottle_dir}" "${wine_path%/wine}" "${installer_dir}"
printf '[Bottle]\n' > "${bottle_dir}/cxbottle.conf"

cat > "${wine_path}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'mock-argc=%d\n' "$#"
index=0
for argument in "$@"; do
  printf 'mock-arg[%d]=<%s>\n' "$index" "$argument"
  index=$((index + 1))
done
exit "${MOCK_WINE_STATUS:-0}"
EOF
chmod 0755 "${wine_path}"

{
  printf 'MZ'
  dd if=/dev/zero bs=1 count=58 2>/dev/null
  printf '\100\000\000\000'
  printf 'PE\000\000\114\001\000\000\000\000\000\000\000\000\000\000\000\000\000\000\002\000'
} > "${installer}"
printf 'not an MSI\n' > "${bad_msi}"

run_helper() {
  CROSSOVER_APP="${crossover_app}" \
    CROSSOVER_BOTTLES_DIR="${bottles_dir}" \
    "${helper}" "$@"
}

passed=0

output="$(run_helper --list-bottles)"
assert_contains "${output}" 'Research' 'lists private bottles'

output="$(run_helper --bottle Research --dry-run "${installer}")"
assert_contains "${output}" 'Dry run complete; nothing was executed.' 'validates without execution'

digest_line="$(/usr/bin/shasum -a 256 "${installer}")"
digest="${digest_line%% *}"
output="$(run_helper --bottle Research --sha256 "${digest}" --dry-run "${installer}")"
assert_contains "${output}" "SHA-256: ${digest}" 'accepts a pinned SHA-256'

assert_fails_with 'SHA-256 mismatch' 'rejects an incorrect SHA-256' \
  run_helper --bottle Research --sha256 \
  0000000000000000000000000000000000000000000000000000000000000000 \
  --dry-run "${installer}"

assert_fails_with 'invalid bottle name' 'rejects bottle traversal' \
  run_helper --bottle ../Research --dry-run "${installer}"

ln -s "${installer}" "${symlink_installer}"
assert_fails_with 'installer must not be a symbolic link' 'rejects installer symlinks' \
  run_helper --bottle Research --dry-run "${symlink_installer}"

assert_fails_with 'does not look like a Windows Installer package' 'rejects invalid MSI files' \
  run_helper --bottle Research --dry-run "${bad_msi}"

literal_argument="\$(touch ${injection_marker})"
output="$(run_helper --bottle Research --yes "${installer}" 'value with spaces' "${literal_argument}")"
assert_contains "${output}" 'mock-arg[7]=<value with spaces>' 'preserves arguments with spaces'
assert_contains "${output}" "mock-arg[8]=<${literal_argument}>" 'does not evaluate shell syntax'
[[ ! -e "${injection_marker}" ]] || fail 'shell syntax created the injection marker'
pass 'does not execute injected shell syntax'

output="$(run_helper --bottle Research --yes --detach "${installer}")"
assert_contains "${output}" 'mock-arg[5]=<--no-wait>' 'supports detached launches'

assert_fails_with 'interactive confirmation requires a terminal' 'fails closed without confirmation' \
  run_helper --bottle Research "${installer}"

assert_fails_with 'CrossOver returned exit status 23' 'propagates CrossOver failures' \
  env MOCK_WINE_STATUS=23 CROSSOVER_APP="${crossover_app}" \
  CROSSOVER_BOTTLES_DIR="${bottles_dir}" "${helper}" --bottle Research --yes "${installer}"

printf '1..%d\n' "${passed}"
