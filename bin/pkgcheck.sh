#!/bin/bash

# Resolve project root based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_FILE="$PROJECT_ROOT/Packagefile"

# Define the supported package types, their associated handler commands, and the check command.
declare -a PACKAGE_TYPES_AND_COMMANDS=(
    "DPKG:dpkg:command -v \"\$package\""
    "FLATPAK:flatpak:flatpak info \"\$package\""
)

error_found=0

extract_packages() {
    local section_name="$1"
    awk -v start_section="[${section_name}]" '
    BEGIN { in_section = 0 }
    /^\[.*\]/ {
        if ($0 == start_section) {
            in_section = 1;
        } else {
            in_section = 0;
        }
        next;
    }
    in_section && !/^[[:space:]]*$/ && !/^[[:space:]]*#/ {
        print $1;
    }
    ' "$PACKAGE_FILE"
}

check_packages() {
    local type_name="$1"
    local handler_command="$2"
    local package_check_command_template="$3"

    echo "--- Checking ${type_name} Packages ---"

    readarray -t packages_to_check < <(extract_packages "$type_name")

    if [[ ${#packages_to_check[@]} -eq 0 ]]; then
        return 0
    fi

    if ! command -v "$handler_command" &>/dev/null; then
        echo "  ERROR: '$handler_command' not found. Install it to manage ${type_name} packages." >&2
        error_found=1
        return 1
    fi

    for package in "${packages_to_check[@]}"; do
        echo -n "Checking [${type_name}] $package: "
        local actual_check_command="${package_check_command_template//\"\$package\"/\"$package\"}"

        if ! eval "$actual_check_command" &>/dev/null; then
            echo "-- ERROR -- not installed (not found in PATH)."
            error_found=1
        else
            echo "-- confirmed installed."
        fi
    done
}

# 1. If Packagefile isn't present, exit clean
if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "Info: Packagefile '$PACKAGE_FILE' not found; no package dependencies listed."
    exit 0
fi

for type_info in "${PACKAGE_TYPES_AND_COMMANDS[@]}"; do
    IFS=':' read -r type_name handler_command package_check_command_template <<< "$type_info"
    check_packages "$type_name" "$handler_command" "$package_check_command_template"
    echo ""
done

if [[ "$error_found" -eq 1 ]]; then
    echo "pkgcheck.sh: Required packages are missing. Install before running application." >&2
    exit 1
else
    echo "pkgcheck.sh: All required packages are installed."
    exit 0
fi
