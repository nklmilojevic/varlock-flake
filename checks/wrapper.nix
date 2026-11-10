# Runs the wrapper without sefko, with a sefko that has no --if-trusted, and
# with a current sefko, against a stand-in varlock.
{ pkgs }:
let
  fakeVarlock = pkgs.writeShellScriptBin "varlock" ''echo "real $*"'';
  wrapped = pkgs.callPackage ../wrapper.nix { } { package = fakeVarlock; };
  fakeSefko =
    help:
    pkgs.writeShellScriptBin "sefko" ''
      if [ "$*" = "exec --help" ]; then echo ${pkgs.lib.escapeShellArg help}; exit 0; fi
      echo "sefko $*"
    '';
  oldSefko = fakeSefko "      --env stringArray   set NAME to the value of alias";
  newSefko = fakeSefko "      --if-trusted        like --project";
  base = "${pkgs.coreutils}/bin";
in
pkgs.runCommand "varlock-wrapper-check" { } ''
  set -eu
  check() {
    [ "$1" = "$2" ] || { echo "$3: got '$1', want '$2'"; exit 1; }
  }
  check "$(PATH=${base} ${wrapped}/bin/varlock run -- "a b")" "real run -- a b" "without sefko"
  check "$(PATH=${oldSefko}/bin:${base} ${wrapped}/bin/varlock run -- x)" "real run -- x" "old sefko"
  check "$(PATH=${newSefko}/bin:${base} ${wrapped}/bin/varlock run -- "a b")" \
    "sefko exec --if-trusted -- ${fakeVarlock}/bin/varlock run -- a b" "current sefko"
  touch $out
''
