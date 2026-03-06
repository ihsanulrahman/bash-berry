#!/bin/bash

declare -a REPOS=(
    "https://github.com/mi-atoll/device_xiaomi_miatoll|device/xiaomi/miatoll|16-volt|0"
    "https://github.com/mi-atoll/vendor_xiaomi_miatoll|vendor/xiaomi/miatoll|16|1"
    "https://github.com/mi-atoll/vendor_xiaomi_miuicamera-miatoll|vendor/xiaomi/miuicamera-miatoll|16|1"
    "https://github.com/ihsanulrahman/android_kernel_xiaomi_sm6250|kernel/xiaomi/sm6250|16|1"
    "https://github.com/LineageOS/android_hardware_sony_timekeep|hardware/sony/timekeep|lineage-23.0|0"
    "https://github.com/ihsanulrahman/vendor_voltage-priv_keys|vendor/voltage-priv/keys|16|0"
)

G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; C='\033[0;36m'; E='\033[0m'

command -v git &>/dev/null || { echo -e "${R}Error: git not installed.${E}"; exit 1; }

total=${#REPOS[@]}
success=0

echo -e "${C}Cloning ${total} repositories...${E}\n"

for repo_data in "${REPOS[@]}"; do
    IFS='|' read -r url dir branch depth <<< "$repo_data"
    name=$(basename "$url" .git)

    printf "  %-45s " "$name"

    [ -d "$dir" ] && rm -rf "$dir"

    cmd="git clone -q"
    [ -n "$branch" ]               && cmd="$cmd -b $branch"
    [ -n "$depth" ] && [ "$depth" != "0" ] && cmd="$cmd --depth=$depth"
    cmd="$cmd $url $dir"

    if $cmd 2>/dev/null; then
        echo -e "${G}✓${E}"
        ((success++))
    else
        echo -e "${R}✗ failed${E}"
    fi
done

echo ""
if [ $success -eq $total ]; then
    echo -e "${G}✓ All ${total} repositories cloned.${E}"
else
    echo -e "${Y}⚠ ${success}/${total} cloned successfully.${E}"
fi

echo -e "\n${C}source build/envsetup.sh && brunch miatoll${E}"
