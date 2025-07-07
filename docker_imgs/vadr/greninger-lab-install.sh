#!/bin/bash
set -e

VERSIONS_FILE="model_library.versions"
: > "$VERSIONS_FILE"  # Truncate or create the versions file

download_latest_github_tarball() {
  local REPO="$1"
  local OWNER="$2"

  if [[ -z "$REPO" || -z "$OWNER" ]]; then
    echo "Usage: download_latest_github_tarball <repo> <owner>"
    return 1
  fi

  echo "Fetching latest release of ${OWNER}/${REPO}..."

  # Get the latest release tag
  local TAG
  TAG=$(curl -s "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -z "$TAG" ]]; then
    echo "Failed to retrieve the latest release tag for ${OWNER}/${REPO}"
    return 1
  fi

  echo "${OWNER}/${REPO} ${TAG}" >> "$VERSIONS_FILE"

  local TARBALL_URL="https://github.com/${OWNER}/${REPO}/archive/refs/tags/${TAG}.tar.gz"
  local TARBALL_FILE="${REPO}.tar.gz"

  echo "Downloading ${TARBALL_URL}..."
  curl -L -o "$TARBALL_FILE" "$TARBALL_URL"

  echo "Extracting ${TARBALL_FILE}..."
  local TEMP_DIR
  TEMP_DIR=$(mktemp -d)

  tar -xzf "$TARBALL_FILE" -C "$TEMP_DIR"

  local EXTRACTED_DIR
  EXTRACTED_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d)

  echo "Renaming extracted directory to ${REPO}..."
  rm -rf "$REPO"
  mv "$EXTRACTED_DIR" "$REPO"
  rm "$TARBALL_FILE"

  echo "Done. Repository available in ./${REPO}"
}

# Call the function for vadr-models-*
download_latest_github_tarball "vadr-models-hcov" "greninger-lab"
download_latest_github_tarball "vadr-models-hmpv" "greninger-lab"
download_latest_github_tarball "vadr-models-hpiv" "greninger-lab"
download_latest_github_tarball "vadr-models-mev" "greninger-lab"
download_latest_github_tarball "vadr-models-muv" "greninger-lab"
download_latest_github_tarball "vadr-models-ruv" "greninger-lab"
#download_latest_github_tarball "vadr-models-hsv" "greninger-lab"
