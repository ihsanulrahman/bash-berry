#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
END='\033[0m'

# Animation characters
SPINNER=("⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽" "⣾")
CHECKMARK="✓"
CROSSMARK="✗"
ARROW="➤"
DOT="•"

# Function to print with color
print_color() {
    echo -e "${2}${1}${END}"
}

# Function to print header
print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   REPOSITORY CLONER SCRIPT                   ║"
    echo "║                   Android ROM Development                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${END}"
}

# Function to print section header
print_section() {
    echo -e "${CYAN}"
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│ $1"
    echo "└──────────────────────────────────────────────────────────────┘"
    echo -e "${END}"
}

# Function to print footer
print_footer() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                      OPERATION COMPLETED                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${END}"
}

# Spinner animation
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        echo -ne "\r${CYAN}${SPINNER[$i]}${END} ${WHITE}${message}${END}   "
        sleep $delay
    done
    echo -ne "\r${GREEN}${CHECKMARK}${END} ${WHITE}${message}${END}     \n"
}

# Function to clean directory (remove if exists)
clean_directory() {
    local target_dir=$1
    local repo_name=$2
    
    if [ -d "$target_dir" ]; then
        print_color "  ${YELLOW}${DOT}${END} Directory exists: ${WHITE}$target_dir${END}" "$YELLOW"
        print_color "  ${YELLOW}${DOT}${END} Removing existing directory..." "$YELLOW"
        
        # Remove the directory
        rm -rf "$target_dir"
        
        if [ $? -eq 0 ]; then
            print_color "  ${GREEN}${CHECKMARK}${END} Successfully removed: ${WHITE}$target_dir${END}" "$GREEN"
        else
            print_color "  ${RED}${CROSSMARK}${END} Failed to remove: ${WHITE}$target_dir${END}" "$RED"
            return 1
        fi
    fi
    
    return 0
}

# Function to clone repository with enhanced visuals
clone_repo() {
    local repo_url=$1
    local target_dir=$2
    local branch=$3
    local depth=$4
    local repo_name=$(basename "$repo_url" .git)
    
    # Clean existing directory
    clean_directory "$target_dir" "$repo_name"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Build git clone command
    local clone_cmd="git clone --progress"
    
    if [ -n "$branch" ]; then
        clone_cmd="$clone_cmd -b $branch"
    fi
    
    if [ -n "$depth" ] && [ "$depth" != "0" ]; then
        clone_cmd="$clone_cmd --depth=$depth"
    fi
    
    clone_cmd="$clone_cmd $repo_url $target_dir"
    
    # Show cloning message
    echo -e "  ${CYAN}${ARROW}${END} ${WHITE}Cloning ${MAGENTA}${repo_name}${END}"
    echo -e "    ${WHITE}Branch: ${YELLOW}${branch:-main}${END}"
    echo -e "    ${WHITE}Path: ${CYAN}${target_dir}${END}"
    
    # Execute clone command in background and show spinner
    ($clone_cmd 2>&1 | while read line; do
        echo -ne "\r    ${CYAN}${line:0:60}${END}   " | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g'
    done) &
    
    local clone_pid=$!
    spinner $clone_pid "Cloning in progress"
    
    wait $clone_pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "    ${GREEN}${CHECKMARK} Successfully cloned${END}"
    else
        echo -e "    ${RED}${CROSSMARK} Failed to clone${END}"
        echo -e "    ${RED}Command: ${clone_cmd}${END}"
    fi
    
    echo ""
    return $exit_code
}

# Clear screen and print header
clear
print_header

# Main cloning process
print_section "STARTING CLONING PROCESS"
echo -e "${WHITE}Initializing repository cloning...${END}"
echo ""

# Common DT
print_section "COMMON DEVICE TREE"
clone_repo "https://github.com/ihsanulrahman/device_xiaomi_sm6250-common" \
           "device/xiaomi/sm6250-common" \
           "16-volt" \
           "0"

# Vendor Sources
print_section "VENDOR REPOSITORIES"
clone_repo "https://github.com/ihsanulrahman/vendor_xiaomi_miatoll" \
           "vendor/xiaomi/miatoll" \
           "16" \
           "1"

clone_repo "https://github.com/ihsanulrahman/vendor_xiaomi_sm6250-common" \
           "vendor/xiaomi/sm6250-common" \
           "16" \
           "1"

# Kernel Sources
print_section "KERNEL SOURCES"
clone_repo "https://github.com/ihsanulrahman/android_kernel_xiaomi_sm6250" \
           "kernel/xiaomi/sm6250" \
           "16" \
           "1"

sleep 1

# Hardware Sources
print_section "HARDWARE COMPONENTS"
clone_repo "https://github.com/LineageOS/android_hardware_sony_timekeep" \
           "hardware/sony/timekeep" \
           "lineage-22.2" \
           "0"

# Miui Camera
print_section "MIUI CAMERA"
clone_repo "https://github.com/ihsanulrahman/vendor_xiaomi_miuicamera-miatoll" \
           "vendor/xiaomi/miuicamera-miatoll" \
           "16" \
           "0"

clone_repo "https://github.com/ihsanulrahman/device_xiaomi_miatoll" \
           "device/xiaomi/miatoll" \
           "16-volt" \
           "0"

# Summary
print_section "CLONING SUMMARY"
echo -e "${WHITE}Repository status:${END}"
echo ""

total=0
success=0

check_repo() {
    local dir=$1
    local name=$2
    total=$((total + 1))
    
    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}${CHECKMARK} ${name}${END} ${GREEN}(cloned successfully)${END}"
        success=$((success + 1))
    else
        echo -e "  ${RED}${CROSSMARK} ${name}${END} ${RED}(not found)${END}"
    fi
}

check_repo "device/xiaomi/sm6250-common" "Common Device Tree"
check_repo "vendor/xiaomi/miatoll" "Vendor Miatoll"
check_repo "vendor/xiaomi/sm6250-common" "Vendor Common"
check_repo "kernel/xiaomi/sm6250" "Kernel"
check_repo "hardware/sony/timekeep" "Timekeep Hardware"
check_repo "vendor/xiaomi/miuicamera-miatoll" "MIUI Camera"
check_repo "device/xiaomi/miatoll" "Miatoll Device Tree"

echo ""
echo -e "${WHITE}Results: ${GREEN}${success}${END}/${WHITE}${total}${END} repositories successfully cloned"

if [ $success -eq $total ]; then
    echo -e "${GREEN}🎉 All repositories cloned successfully!${END}"
else
    echo -e "${YELLOW}⚠️  Some repositories failed to clone${END}"
fi

echo ""
print_footer

# Final message with emoji
echo ""
echo -e "${GREEN}✨ All operations completed!${END}"
echo -e "${CYAN}🏗️  Happy building!${END}"
echo -e "${MAGENTA}🚀 Run 'source build/envsetup.sh, do brunch && sit tight untill ROM is cooked :-D${END}"
echo ""