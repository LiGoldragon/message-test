# The semi-sandbox's skill-variable reader over a sample file: a name with
# spaces is matched whole, not as the prefix of a longer name; the value is
# everything after the first ": ", colons included; a missing name exits 1.
{ pkgs, flake, ... }:
let
  reader = flake.lib.skillVariable { inherit pkgs; };
in
pkgs.runCommand "skill-variable" { nativeBuildInputs = [ reader ]; } ''
  sample=${../fixtures/skill-variable/sample.md}
  expect() {
    got="$(skill-variable "$sample" "$1")"
    [ "$got" = "$2" ] || { echo "«$1»: expected «$2», got «$got»" >&2; exit 1; }
  }
  expect "Flow source root" "/x/y"
  expect "Flow stable Codex" "/opt/codex stable: a value with a colon"
  expect "Flow harness profiles" "claude codex"
  if skill-variable "$sample" "Flow next Codex"; then
    echo "a missing name was answered" >&2
    exit 1
  fi
  touch $out
''
