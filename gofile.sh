#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

display_usage() {
    echo -e "${YELLOW}Usage Instructions for Linux Environment:${NC}"
    echo ""
    echo -e "${CYAN}To make the script globally available, run the following commands in your terminal:${NC}"
    echo -e "   ${GREEN}sudo wget https://raw.githubusercontent.com/tanvirr007/gofile/main/gofile.sh -O \"/usr/local/bin/gofile\"${NC}"
    echo -e "   ${GREEN}sudo chmod +x /usr/local/bin/gofile${NC}"
    echo ""
    echo -e "${CYAN}To uninstall gofile, you can run:${NC}"
    echo -e "   ${GREEN}sudo rm \"/usr/local/bin/gofile\"${NC}"
    echo ""
    echo -e "${YELLOW}Usage Instructions for Termux:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Download this script using wget:"
    echo -e "   ${GREEN}wget https://raw.githubusercontent.com/tanvirr007/gofile/main/gofile.sh -O \"/data/data/com.termux/files/usr/bin/gofile\" && chmod +x \"/data/data/com.termux/files/usr/bin/gofile\"${NC}"
    echo ""
    echo -e "${CYAN}To uninstall gofile from Termux, you can run:${NC}"
    echo -e "   ${GREEN}rm \"/data/data/com.termux/files/usr/bin/gofile\"${NC}"
    echo ""
    echo -e "${YELLOW}How to Upload Files:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Run the script with the file(s) you want to upload:"
    echo -e "   ${GREEN}gofile <your_filename>${NC}"
    echo ""
    echo -e "${CYAN}2.${NC} You can upload multiple files by specifying their names separated by spaces:${NC}"
    echo -e "   ${GREEN}gofile <file1> <file2> <file3>${NC}"
    echo ""
    echo -e "${CYAN}3.${NC} If you have long filenames, you can use wildcards like:${NC}"
    echo -e "   ${GREEN}gofile So*.zip${NC}"
    echo -e "   ${GREEN}gofile Something*.zip${NC}"
    echo ""
}

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

install_jq() {
    echo -e "${CYAN}jq is required for JSON parsing.${NC}"
    read -p "Do you want to install jq now? (y/n): " install_jq
    if [ "$install_jq" = "y" ] || [ "$install_jq" = "Y" ]; then
        if command -v pkg &> /dev/null; then
            pkg install jq
        elif command -v pacman &> /dev/null; then
            sudo pacman -S jq
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install jq
        elif command -v yum &> /dev/null; then
            sudo yum install jq
        elif command -v dnf &> /dev/null; then
            sudo dnf install jq
        elif command -v zypper &> /dev/null; then
            sudo zypper install jq
        elif command -v brew &> /dev/null; then
            brew install jq
        else
            echo -e "${RED}Error: Unsupported package manager.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Exiting script as jq is required.${NC}"
        exit 1
    fi
}

install_bc() {
    echo -e "${CYAN}bc (Basic Calculator) is required for size calculations.${NC}"
    read -p "Do you want to install bc now? (y/n): " install_bc
    if [ "$install_bc" = "y" ] || [ "$install_bc" = "Y" ]; then
        if command -v pkg &> /dev/null; then
            pkg install bc
        elif command -v pacman &> /dev/null; then
            sudo pacman -S bc
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install bc
        elif command -v yum &> /dev/null; then
            sudo yum install bc
        elif command -v dnf &> /dev/null; then
            sudo dnf install bc
        elif command -v zypper &> /dev/null; then
            sudo zypper install bc
        elif command -v brew &> /dev/null; then
            brew install bc
        else
            echo -e "${RED}Error: Unsupported package manager.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Exiting script as bc is required.${NC}"
        exit 1
    fi
}

check_dependencies() {
    if ! command -v jq &> /dev/null; then
        install_jq
    fi
    if ! command -v bc &> /dev/null; then
        install_bc
    fi
}

check_dependencies

if [[ "$#" -eq 0 ]]; then
    display_usage
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed.${NC}"
    echo -e "${CYAN}Install jq using your package manager.${NC}"
    exit 1
fi

SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers | map(.name) | .[]' | shuf -n 1)
if [[ -z "$SERVER" || "$SERVER" == "null" ]]; then
    echo -e "${RED}Error: Could not retrieve GoFile server information.${NC}"
    exit 1
fi

echo -e "${GREEN}Using server:${NC} ${YELLOW}${SERVER}${NC}"

success_count=0
total_files=$#
file_number=0

is_multiple_files=false
if [[ "$total_files" -gt 1 ]]; then
    is_multiple_files=true
fi

for file in "$@"; do
    file_number=$((file_number + 1))

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error - File \"$file\" not found! Skipping...${NC}"
        continue
    fi

    filename=$(basename "$file")
    filesize=$(wc -c < "$file")
    human_size=$(human_readable_size $filesize)
    extension="${filename##*.}"
    md5sum=$(md5sum "$file" | awk '{ print $1 }')

    if $is_multiple_files; then
        echo -e "• ${YELLOW}$file_number:${NC} Uploading Your file ${YELLOW}$filename${NC}"
    else
        echo -e "Uploading Your file ${YELLOW}$filename${NC}"
    fi

    response=$(curl -# -F "file=@$file" "https://${SERVER}.gofile.io/uploadFile")

    if echo "$response" | grep -q '"status":"ok"'; then
        download_link=$(echo "$response" | jq -r '.data.downloadPage')
        echo ""
        echo -e "${GREEN}Name:${NC} ${CYAN}$filename${NC}"
        echo -e "${GREEN}File size:${NC} ${CYAN}$human_size${NC}"
        echo -e "${GREEN}File type:${NC} ${CYAN}$extension${NC}"
        echo -e "${GREEN}Md5sum:${NC} ${CYAN}$md5sum${NC}"
        echo -e "${GREEN}File URL:${NC} ${YELLOW}$download_link${NC}"
        success_count=$((success_count + 1))
    else
        echo -e "${RED}Error: Failed to upload $filename${NC}"
    fi
    echo ""
done

echo -e "${CYAN}Upload Status:${NC} ${GREEN}$success_count of $total_files files uploaded successfully.${NC}"
