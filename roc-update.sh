#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'
CHECKMARK="${GREEN}\xE2\x9C\x94${NC}"
CROSSMARK="${RED}\xE2\x9C\x98${NC}"

roc_dir=$(which roc | xargs dirname)
[ -z "$roc_dir" ] && {
    echo -e "$CROSSMARK Failed to find Roc installation directory"; exit 1;
}

cd $(dirname $roc_dir)

# Determine the OS and architecture
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Linux)
        case "$ARCH" in
            x86_64) FILENAME="roc_nightly-linux_x86_64-latest.tar.gz" ;;
            aarch64) FILENAME="roc_nightly-linux_arm64-latest.tar.gz" ;;
            *) echo -e "$CROSSMARK Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    Darwin)
        case "$ARCH" in
            x86_64) FILENAME="roc_nightly-macos_x86_64-latest.tar.gz" ;;
            arm64) FILENAME="roc_nightly-macos_apple_silicon-latest.tar.gz" ;;
            *) echo -e "$CROSSMARK Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    *)
        echo -e "$CROSSMARK Unsupported OS: $OS"; exit 1
        ;;
esac

# Check if gh is installed and authenticated
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo -n "Checking for updates... "
    # Get the latest release asset timestamp
    latest_release_date=$(gh release view nightly --repo roc-lang/roc --json assets --jq '.assets[0].updatedAt' | cut -d'T' -f1,2 | cut -d':' -f1)
    latest_release_date_unix=$(date -j -f "%Y-%m-%dT%H" "$latest_release_date" +"%s")

    # Get the current installed version's build date
    roc_version_output=$(roc version)
    roc_build_date=$(echo "$roc_version_output" | sed -n 's/.*built from commit .* on \(.*\)/\1/p' | cut -d':' -f1)
    roc_build_date_unix=$(date -j -f "%a %b %d %H %Y" "$roc_build_date" +"%s")
    echo -e "$CHECKMARK"

    # Compare the release asset date and the current build date
    # Check if the latest release is more than 1 hour newer than the current build
    if [ "$((latest_release_date_unix - roc_build_date_unix))" -le 3600 ]; then
        echo "No new update available."
        echo -e "Current roc version: ${PURPLE}${roc_version_output}${NC}"
        exit 0
    fi
else
    echo -e "$CROSSMARK \`gh\` not available. Cannot compare installed version with latest release."
fi

echo -n "Downloading latest Roc nightly build... "
curl -sOL "https://github.com/roc-lang/roc/releases/download/nightly/$FILENAME" \
&& echo -e "$CHECKMARK" || {
    echo -e "$CROSSMARK Failed to download Roc nightly build"; exit 1;
}

echo -n "Extracting tar file... "
tar xf "$FILENAME" \
&& echo -e "$CHECKMARK" || {
    rm "$FILENAME"
    echo "Failed to extract tar file"; exit 1;
}
rm "$FILENAME"

mv "$roc_dir" "roc-old"
mv roc_nightly-* "$roc_dir"

roc_version=$(roc version)
if [ $? -eq 0 ]; then
    echo -n "Cleaning up... "
    rm -rf "roc-old"
    echo -e "$CHECKMARK"
    echo -e "Updated Roc to: ${PURPLE}${roc_version}${NC}"
else
    echo -e "$CROSSMARK Failed to update Roc. Reverting changes..."
    rm -rf roc_nightly-*
    rm "$FILENAME"
    mv "roc-old" "$roc_dir"
    echo -e "Reverted Roc to ${PURPLE}$(roc version)${NC}"
fi
