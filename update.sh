#!/usr/bin/env bash
set -euo pipefail

SOURCES_FILE="sources.json"
GITHUB_API_URL="https://api.github.com/repos/dmno-dev/varlock/releases"

# Platform mapping: nix system -> varlock tarball name
declare -A PLATFORM_MAP=(
  ["x86_64-linux"]="varlock-linux-x64.tar.gz"
  ["aarch64-linux"]="varlock-linux-arm64.tar.gz"
  ["x86_64-darwin"]="varlock-macos-x64.tar.gz"
  ["aarch64-darwin"]="varlock-macos-arm64.tar.gz"
)

get_latest_stable_version() {
  local headers=(-H "Accept: application/vnd.github+json" -H "User-Agent: varlock-flake-updater")

  # Use GITHUB_TOKEN if available
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi

  # The repo is a monorepo: only tags of the form "varlock@X.Y.Z" are CLI releases
  curl -sL "${headers[@]}" "$GITHUB_API_URL?per_page=100" | jq -r '
    [.[] | select(.prerelease == false and .draft == false)
         | select(.tag_name | startswith("varlock@"))
         | .tag_name | sub("^varlock@"; "")
         | select(test("-(alpha|beta|rc|next)") | not)]
    | sort_by(split(".") | map(tonumber))
    | reverse
    | first
  '
}

compute_sri_hash() {
  local url="$1"
  nix store prefetch-file "$url" --json 2>/dev/null | jq -r '.hash'
}

main() {
  echo "Checking for varlock updates..."

  local current_version
  current_version=$(jq -r '.version' "$SOURCES_FILE")
  echo "Current version: $current_version"

  local latest_version
  latest_version=$(get_latest_stable_version)

  if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
    echo "Error: Failed to get latest version"
    exit 1
  fi

  echo "Latest stable version: $latest_version"

  if [[ "$current_version" == "$latest_version" ]]; then
    echo "Already at latest version, no update needed"
    exit 0
  fi

  echo "Updating from $current_version to $latest_version..."

  # Build new sources.json
  local platforms_json="{}"

  for nix_platform in "${!PLATFORM_MAP[@]}"; do
    local tarball_name="${PLATFORM_MAP[$nix_platform]}"
    local url="https://github.com/dmno-dev/varlock/releases/download/varlock%40${latest_version}/${tarball_name}"

    echo "Fetching hash for $nix_platform..."

    local hash
    hash=$(compute_sri_hash "$url")

    if [[ -z "$hash" || "$hash" == "null" ]]; then
      echo "Error: Failed to compute hash for $nix_platform"
      exit 1
    fi

    echo "  $nix_platform: $hash"

    platforms_json=$(echo "$platforms_json" | jq \
      --arg platform "$nix_platform" \
      --arg url "$url" \
      --arg hash "$hash" \
      '. + {($platform): {"url": $url, "hash": $hash}}')
  done

  # Write new sources.json
  jq -n \
    --arg version "$latest_version" \
    --argjson platforms "$platforms_json" \
    '{"version": $version, "platforms": $platforms}' > "$SOURCES_FILE"

  echo "Successfully updated sources.json to version $latest_version"
}

main "$@"
