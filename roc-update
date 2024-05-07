#!/bin/zsh
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

echo -n "Downloading latest Roc nightly build... "
curl -sOL https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-macos_apple_silicon-latest.tar.gz \
&& echo -e "$CHECKMARK" || {
    echo -e "$CROSSMARK Failed to download Roc nightly build"; exit 1; 
}
echo -n "Extracting tar file... "
tar xf roc_nightly-macos_apple_silicon-latest.tar.gz \
&& echo -e "$CHECKMARK" || {
    rm roc_nightly-macos_apple_silicon-latest.tar.gz
    echo "Failed to extract tar file"; exit 1; 
}
mv "$roc_dir" "${roc_dir}-old"
mv roc_nightly-macos_apple_silicon-20* "$roc_dir"

roc_version=$(roc version)
if [ $? -eq 0 ]; then
    echo -n "Cleaning up... "
    rm -rf "${roc_dir}-old"
    rm roc_nightly-macos_apple_silicon-latest.tar.gz
    echo -e "$CHECKMARK"
    echo "Updated Roc to: ${PURPLE}${roc_version}${NC}"
else
    echo -e "$CROSSMARK Failed to update Roc. Reverting changes..."
    rm -rf roc_nightly-macos_apple_silicon-20*
    rm roc_nightly-macos_apple_silicon-latest.tar.gz
    mv "${roc_dir}-old" "$roc_dir"
    echo -e "Reverted Roc to ${PURPLE}$(roc version)${NC}"
fi
