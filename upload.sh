#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

if [[ "$#" == '0' ]]; then
    echo -e "${RED}Error: No files specified.${NC}"
    echo -e "${CYAN}Usage:${NC} ${GREEN}$0 <file1> <file2> ...${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed.${NC}"
    echo -e "${CYAN}Install jq using your package manager:${NC}"
    echo -e "${GREEN}sudo apt install jq${NC} (for Debian/Ubuntu)"
    echo -e "${GREEN}sudo pacman -S jq${NC} (for Arch Linux)"
    exit 1
fi

echo -e "${CYAN}Querying GoFile for the best server...${NC}"
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

if [[ -z "$SERVER" || "$SERVER" == "null" ]]; then
    echo -e "${RED}Error: Could not retrieve GoFile server information.${NC}"
    exit 1
fi

echo -e "${GREEN}Using server:${NC} ${YELLOW}${SERVER}${NC}"

human_readable_size() {
    local size=$1
    if [ "$size" -lt 1024 ]; then
        echo "${size} bytes"
    elif [ "$size" -lt 1048576 ]; then
        echo "$(echo "scale=2; $size/1024" | bc) KB"
    elif [ "$size" -lt 1073741824 ]; then
        echo "$(echo "scale=2; $size/1048576" | bc) MB"
    else
        echo "$(echo "scale=2; $size/1073741824" | bc) GB"
    fi
}

success_count=0
error_count=0
total_files=$#

for file in "$@"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File $file not found!${NC}"
        error_count=$((error_count + 1))
        continue
    fi

    filename=$(basename "$file")
    filesize=$(stat -c %s "$file")
    human_size=$(human_readable_size $filesize)
    extension="${filename##*.}"

    echo -e "Uploading ${YELLOW}$filename${NC} (${CYAN}$human_size${NC})..."

    response=$(curl -# -F "file=@$file" "https://${SERVER}.gofile.io/uploadFile")
    if echo "$response" | grep -q '"status":"ok"'; then
        download_link=$(echo "$response" | jq -r '.data.downloadPage')
        md5sum=$(md5sum "$file" | awk '{ print $1 }')
        echo -e "${GREEN}Upload successful!${NC}"
        echo -e "${CYAN}Name:${NC} ${YELLOW}$filename${NC}"
        echo -e "${CYAN}File size:${NC} ${YELLOW}$human_size${NC}"
        echo -e "${CYAN}File type:${NC} ${YELLOW}$extension${NC}"
        echo -e "${CYAN}Md5sum:${NC} ${YELLOW}$md5sum${NC}"
        echo -e "${CYAN}File URL:${NC} ${GREEN}$download_link${NC}"
        success_count=$((success_count + 1))
    else
        echo -e "${RED}Error: Failed to upload $filename${NC}"
        error_count=$((error_count + 1))
    fi
    echo ""
done

echo -e "${YELLOW}Upload Summary:${NC}"
echo -e "${GREEN}$success_count files uploaded successfully.${NC}"
if [ "$error_count" -gt 0 ]; then
    echo -e "${RED}$error_count files failed to upload.${NC}"
fi
