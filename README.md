# varlock-flake

Nix flake for [varlock](https://varlock.dev) - AI-safe .env files with schemas, validation, secrets, and redaction.

varlock doesn't ship in nixpkgs, so this flake packages the official release binaries for Linux and macOS (x64 and arm64). It also ships an overlay and a Home Manager module.

## Try it

```sh
nix run github:nklmilojevic/varlock-flake
```

## Install

### Flake input

```nix
{
  inputs.varlock.url = "github:nklmilojevic/varlock-flake";
}
```

Then use `inputs.varlock.packages.${system}.default` wherever you need the package.

### Overlay

```nix
nixpkgs.overlays = [ inputs.varlock.overlays.default ];
```

This gives you `pkgs.varlock` and `pkgs.varlock-unwrapped`.

### Home Manager

```nix
{
  imports = [ inputs.varlock.homeManagerModules.default ];

  programs.varlock.enable = true;
}
```

Options:

- `programs.varlock.package` - which package to use, defaults to the one from this flake
- `programs.varlock.enableBinSymlink` - symlink the binary to `~/.local/bin/varlock`, on by default on Linux

## sefko

`varlock run` asks 1Password for every `op()` value each time it starts. [sefko](https://github.com/nklmilojevic/sefko) keeps those values in memory, so you approve 1Password once instead of on every run.

The `varlock` package here runs varlock through `sefko exec --if-trusted` when `sefko` is on your `PATH`. After `sefko trust` in a repository, varlock gets that repository's secrets from sefko's memory. Everything else stays the same:

- Without sefko, or with a sefko that doesn't have `--if-trusted` (older than v0.3.0), it runs plain varlock.
- In a repository you haven't trusted, it runs plain varlock and sefko prints a one-line note.
- If the sefko agent isn't running, varlock reads 1Password itself as usual.

To skip the wrapper entirely, use `packages.${system}.varlock-unwrapped` (or `pkgs.varlock-unwrapped` from the overlay).

## Why the symlink option

varlock finds its local-encryption helper (`varlock-local-encrypt` on Linux, `VarlockEnclave.app` on macOS) relative to its own binary. The package installs them side by side so this just works, and the `~/.local/bin` symlink keeps varlock in a standard location for tools that don't read your Nix profile.

## Updating

```sh
./update.sh
```

The script checks GitHub for the latest stable `varlock@X.Y.Z` release, prefetches the tarballs for all four platforms, and rewrites `sources.json` with the new version and hashes. Set `GITHUB_TOKEN` if you're hitting API rate limits.

## License

The flake itself does whatever you want with it. varlock is MIT licensed by [dmno-dev](https://github.com/dmno-dev/varlock).
