# Runs varlock through sefko (https://github.com/nklmilojevic/sefko) when sefko
# is installed, so varlock gets the secrets of a trusted project from sefko's
# memory instead of asking 1Password on every run.
#
# The wrapper looks for sefko on PATH each time it starts. Without sefko, or
# with a sefko that has no `exec --if-trusted`, it runs plain varlock. It always
# execs the real binary from its store path, so varlock still finds its
# local-encryption helper next to itself.
{
  lib,
  symlinkJoin,
  writeShellScript,
  gnugrep,
}:
{ package }:
let
  real = lib.escapeShellArg "${package}/bin/varlock";
  script = writeShellScript "varlock" ''
    if command -v sefko >/dev/null 2>&1 && sefko exec --help 2>/dev/null | ${lib.getExe gnugrep} -q -- --if-trusted; then
      exec sefko exec --if-trusted -- ${real} "$@"
    fi
    exec ${real} "$@"
  '';
in
symlinkJoin {
  pname = "varlock";
  version = package.version or "unversioned";
  paths = [ package ];
  postBuild = ''
    rm "$out/bin/varlock"
    ln -s ${script} "$out/bin/varlock"
  '';
  passthru.unwrapped = package;
  meta = (package.meta or { }) // {
    description = "varlock, run through sefko when it is installed";
    mainProgram = "varlock";
  };
}
