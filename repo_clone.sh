#!/bin/bash

# --- Configuration ---

# Define all repositories
# Format: "URL|TargetDirectory|Branch|Depth"
# Use '0' for depth if you want a full clone.
declare -a REPOS=(
    "https://github.com/mi-atoll/device_xiaomi_miatoll|device/xiaomi/miatoll|16-volt|0"
    "https://github.com/mi-atoll/vendor_xiaomi_miatoll|vendor/xiaomi/miatoll|16|1"
    "https://github.com/mi-atoll/vendor_xiaomi_miuicamera-miatoll|vendor/xiaomi/miuicamera-miatoll|16|1"
    "https://github.com/ihsanulrahman/android_kernel_xiaomi_sm6250|kernel/xiaomi/sm6250|16|1"
    "https://github.com/LineageOS/android_hardware_sony_timekeep|hardware/sony/timekeep|lineage-23.0|0"
    "https://github.com/ihsanulrahman/vendor_voltage-priv_keys|vendor/voltage-priv/keys|16|0"
)

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

SPINNER=("⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽" "⣾")
CHECKMARK="✓"
CROSSMARK="✗"
ARROW="➤"
DOT="•"

print_color() {
    echo -e "${2}${1}${END}"
}

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               REPOSITORY CLONER SCRIPT                       ║"
    echo "║               Android ROM Development                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${END}"
}

print_section() {
    echo -e "${CYAN}"
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│ $1"
    echo "└──────────────────────────────────────────────────────────────┘"
    echo -e "${END}"
}

print_footer() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    OPERATION COMPLETED                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${END}"
}

spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local i=0
    
    # Check if the process is still running
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        echo -ne "\r${CYAN}${SPINNER[$i]}${END} ${WHITE}${message}${END}    "
        sleep $delay
    done
    
    echo -ne "\r"
}

check_dependencies() {
    print_color "${DOT} Checking dependencies..." "$WHITE"
    if ! command -v git &> /dev/null; then
        print_color "${CROSSMARK} Git is not installed." "$RED"
        print_color "Please install 'git' to run this script." "$RED"
        exit 1
    fi
    print_color "${CHECKMARK} Git found." "$GREEN"
    echo ""
}

clean_directory() {
    local target_dir=$1
    local repo_name=$2
    
    if [ -d "$target_dir" ]; then
        print_color "  ${YELLOW}${DOT}${END} Directory exists: ${WHITE}$target_dir${END}" "$YELLOW"
        
        rm -rf "$target_dir" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_color "  ${GREEN}${CHECKMARK}${END} Successfully removed existing directory." "$GREEN"
        else
            print_color "  ${RED}${CROSSMARK}${END} Failed to remove: ${WHITE}$target_dir${END}" "$RED"
            return 1
        fi
    fi
    
    return 0
}

clone_repo() {
    local repo_url=$1
    local target_dir=$2
    local branch=$3
    local depth=$4
    local repo_name=$(basename "$repo_url" .git)
    
    print_color "  ${ARROW} STARTING CLONE: ${MAGENTA}${repo_name}${END}" "$CYAN"
    echo -e "    ${WHITE}Branch: ${YELLOW}${branch:-default}${END} | Depth: ${YELLOW}${depth:-full}${END}"
    echo -e "    ${WHITE}Path: ${CYAN}${target_dir}${END}"
    
    clean_directory "$target_dir" "$repo_name"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local clone_cmd="git clone --progress"
    
    if [ -n "$branch" ]; then
        clone_cmd="$clone_cmd -b $branch"
    fi
    
    if [ -n "$depth" ] && [ "$depth" != "0" ]; then
        clone_cmd="$clone_cmd --depth=$depth"
    fi
    
    clone_cmd="$clone_cmd $repo_url $target_dir"
    
    local temp_output=$(mktemp)
    
    ($clone_cmd >/dev/null 2>&1) &
    local clone_pid=$!
    
    spinner $clone_pid "Cloning ${repo_name}"
    
    wait $clone_pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_color "  ${CHECKMARK} Successfully cloned ${repo_name}" "$GREEN"
    else
        print_color "  ${CROSSMARK} FAILED to clone ${repo_name}" "$RED"
        print_color "    Command failed: ${clone_cmd}" "$RED"
    fi
    
    echo ""
    rm -f "$temp_output"
    return $exit_code
}


main() {
    clear
    print_header

    check_dependencies
    
    print_section "STARTING REPOSITORY CLONING"
    echo -e "${WHITE}Iterating through ${#REPOS[@]} repositories...${END}"
    echo ""

    for repo_data in "${REPOS[@]}"; do
        IFS='|' read -r url dir branch depth <<< "$repo_data"

        clone_repo "$url" "$dir" "$branch" "$depth"
    done

    print_section "CLONING SUMMARY"
    echo -e "${WHITE}Repository status check:${END}"
    echo ""

    local total_repos=${#REPOS[@]}
    local success_count=0
    
    for repo_data in "${REPOS[@]}"; do
        IFS='|' read -r url dir branch depth <<< "$repo_data"
        local repo_name=$(basename "$url" .git)
        
        if [ -d "$dir" ]; then
            echo -e "  ${GREEN}${CHECKMARK}${END} ${repo_name} ${GREEN}(cloned to $dir)${END}"
            success_count=$((success_count + 1))
        else
            echo -e "  ${RED}${CROSSMARK}${END} ${repo_name} ${RED}(directory not found)${END}"
        fi
    done

    echo ""
    print_color "Results: ${GREEN}${success_count}${END}/${WHITE}${total_repos}${END} repositories successfully cloned" "$WHITE"

    if [ $success_count -eq $total_repos ]; then
        print_color "🎉 All repositories cloned successfully!" "$GREEN"
    else
        print_color "⚠️ Some repositories failed to clone. Check the logs above." "$YELLOW"
    fi

    echo ""
    print_footer

    echo ""
    print_color "✨ All operations completed!" "$GREEN"
    print_color "🏗️ Happy building! Now run: ${CYAN}source build/envsetup.sh && brunch miatoll${END}" "$CYAN"
    echo ""
}

main
