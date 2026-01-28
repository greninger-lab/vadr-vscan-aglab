#!/bin/bash
set -e

VERSIONS_FILE="model_library.versions"
: > "$VERSIONS_FILE"

download_latest_github_tarball() {
    local REPO="$1"
    local OWNER="$2"
    
    if [ -z "$REPO" ] || [ -z "$OWNER" ]; then
        echo "Usage: download_latest_github_tarball <repo> <owner>"
        return 1
    fi
    
    echo "Fetching latest release of ${OWNER}/${REPO}..."
    
    # Get the latest release info
    local RELEASE_JSON
    RELEASE_JSON=$(curl -s -f "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest")
    
    if [ -z "$RELEASE_JSON" ]; then
        echo "Failed to retrieve release info for ${OWNER}/${REPO}"
        return 1
    fi
    
    # Extract tag name
    local TAG
    TAG=$(echo "$RELEASE_JSON" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    
    if [ -z "$TAG" ]; then
        echo "Failed to parse tag for ${OWNER}/${REPO}"
        return 1
    fi
    
    echo "Found tag: ${TAG}"
    echo "${OWNER}/${REPO} ${TAG}" >> "$VERSIONS_FILE"
    
    local TARBALL_FILE="${REPO}.tar.gz"
    local DOWNLOAD_SUCCESS=0
    
    # Try 1: Look for a release asset with .tar.gz (uploaded LFS-enabled tarball)
    local ASSET_URL
    ASSET_URL=$(echo "$RELEASE_JSON" | grep '"browser_download_url":' | grep '\.tar\.gz"' | head -n 1 | sed -E 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    
    if [ -n "$ASSET_URL" ]; then
        echo "Found release asset, downloading from ${ASSET_URL}..."
        if curl -L -f --connect-timeout 30 --max-time 300 -o "$TARBALL_FILE" "$ASSET_URL"; then
            local FILE_SIZE
            FILE_SIZE=$(stat -f%z "$TARBALL_FILE" 2>/dev/null || stat -c%s "$TARBALL_FILE" 2>/dev/null || echo "0")
            
            if [ "$FILE_SIZE" -gt 0 ] && gzip -t "$TARBALL_FILE" 2>/dev/null; then
                echo "Asset download successful ($FILE_SIZE bytes)"
                DOWNLOAD_SUCCESS=1
            else
                echo "Asset download failed validation, trying standard archive..."
                rm -f "$TARBALL_FILE"
            fi
        else
            echo "Asset download failed, trying standard archive..."
            rm -f "$TARBALL_FILE"
        fi
    fi
    
    # Try 2: Fall back to standard GitHub archive URL
    if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
        local TARBALL_URL="https://github.com/${OWNER}/${REPO}/archive/refs/tags/${TAG}.tar.gz"
        echo "Downloading from standard archive ${TARBALL_URL}..."
        
        local RETRY=0
        local MAX_RETRIES=3
        while [ $RETRY -lt $MAX_RETRIES ]; do
            if curl -L -f --connect-timeout 30 --max-time 300 -o "$TARBALL_FILE" "$TARBALL_URL"; then
                local FILE_SIZE
                FILE_SIZE=$(stat -f%z "$TARBALL_FILE" 2>/dev/null || stat -c%s "$TARBALL_FILE" 2>/dev/null || echo "0")
                
                if [ "$FILE_SIZE" -eq 0 ]; then
                    echo "Downloaded file is 0 bytes, retrying..."
                    rm -f "$TARBALL_FILE"
                elif gzip -t "$TARBALL_FILE" 2>/dev/null; then
                    echo "Download successful and verified ($FILE_SIZE bytes)"
                    DOWNLOAD_SUCCESS=1
                    break
                else
                    echo "Downloaded file is not a valid gzip archive, retrying..."
                    rm -f "$TARBALL_FILE"
                fi
            else
                echo "Download failed, retrying..."
                rm -f "$TARBALL_FILE"
            fi
            
            RETRY=$((RETRY + 1))
            if [ $RETRY -lt $MAX_RETRIES ]; then
                echo "Waiting 5 seconds before retry $((RETRY + 1))/$MAX_RETRIES..."
                sleep 5
            fi
        done
    fi
    
    if [ $DOWNLOAD_SUCCESS -eq 0 ] || [ ! -f "$TARBALL_FILE" ]; then
        echo "ERROR: Failed to download ${TARBALL_FILE} from either asset or standard archive"
        return 1
    fi
    
    echo "Extracting ${TARBALL_FILE}..."
    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    
    if ! tar -xzf "$TARBALL_FILE" -C "$TEMP_DIR"; then
        echo "ERROR: Failed to extract tarball"
        rm -rf "$TEMP_DIR"
        rm -f "$TARBALL_FILE"
        return 1
    fi
    
    local EXTRACTED_DIR
    EXTRACTED_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    
    if [ -z "$EXTRACTED_DIR" ]; then
        echo "ERROR: No directory found after extraction"
        rm -rf "$TEMP_DIR"
        rm -f "$TARBALL_FILE"
        return 1
    fi
    
    echo "Renaming extracted directory to ${REPO}..."
    rm -rf "$REPO"
    mv "$EXTRACTED_DIR" "$REPO"
    rm -rf "$TEMP_DIR"
    rm -f "$TARBALL_FILE"
    
    echo "Done. Repository available in ./${REPO}"
    echo ""
}

# Call the function for vadr-models-*
download_latest_github_tarball "vadr-models-hcov" "greninger-lab"
download_latest_github_tarball "vadr-models-hmpv" "greninger-lab"
download_latest_github_tarball "vadr-models-hpiv" "greninger-lab"
download_latest_github_tarball "vadr-models-mev" "greninger-lab"
download_latest_github_tarball "vadr-models-muv" "greninger-lab"
download_latest_github_tarball "vadr-models-ruv" "greninger-lab"
download_latest_github_tarball "vadr-models-hrv" "greninger-lab"
download_latest_github_tarball "vadr-models-ev" "greninger-lab"
#download_latest_github_tarball "vadr-models-hsv" "greninger-lab"

echo "All downloads complete!"
