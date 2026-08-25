{
  lib,
  stdenv,
  fetchurl,
}:
let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  platform = sources.platforms.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "varlock";
  version = sources.version;

  src = fetchurl {
    url = platform.url;
    hash = platform.hash;
  };

  sourceRoot = ".";

  # The varlock binary locates its local-encryption helper relative to itself:
  # varlock-local-encrypt on Linux, VarlockEnclave.app on macOS.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 varlock $out/bin/varlock
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      install -m755 varlock-local-encrypt $out/bin/varlock-local-encrypt
    ''}
    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      cp -R VarlockEnclave.app $out/bin/VarlockEnclave.app
    ''}
    runHook postInstall
  '';

  meta = {
    description = "AI-safe .env files: schemas, validation, secrets, and redaction";
    homepage = "https://varlock.dev";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "varlock";
  };
}
