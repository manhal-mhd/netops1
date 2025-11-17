#!/bin/bash

# Validation script for file permissions assignment
echo "=== Validating File Permissions Assignment ==="
echo

# Change to the directory
cd /home/isoc 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Directory /home/isoc not found!"
    exit 1
fi

# Check if all files exist
files=("executefile.sh" "cantedit.sh" "owneronly.txt" "mixrights.txt")
missing_files=()

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "❌ ERROR: The following files are missing:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    echo "Please create all required files first."
    exit 1
fi

echo "✅ All required files exist"
echo

# Function to validate permissions
validate_permissions() {
    local filename=$1
    local expected_perms=$2
    local description=$3
    
    actual_perms=$(ls -l "$filename" | awk '{print $1}')
    actual_owner=$(ls -l "$filename" | awk '{print $3}')
    actual_group=$(ls -l "$filename" | awk '{print $4}')
    
    echo "Validating $filename: $description"
    echo "  Expected: $expected_perms"
    echo "  Actual:   $actual_perms"
    
    if [ "$actual_perms" == "$expected_perms" ]; then
        echo "  ✅ Permissions CORRECT"
    else
        echo "  ❌ Permissions INCORRECT"
    fi
    
    if [ "$actual_owner" == "isoc" ] && [ "$actual_group" == "isoc" ]; then
        echo "  ✅ Owner and group CORRECT (isoc:isoc)"
    else
        echo "  ❌ Owner/group INCORRECT (expected isoc:isoc, got $actual_owner:$actual_group)"
    fi
    echo
}

# Validate each file's permissions
validate_permissions "executefile.sh" "---x--x--x" "ONLY execute rights for user, group, and other"
validate_permissions "cantedit.sh" "-r--r--r--" "ONLY read rights for user, group, and other"
validate_permissions "owneronly.txt" "-rwx------" "rwx rights ONLY for owner, no rights for others"
validate_permissions "mixrights.txt" "-rwx--xr--" "Owner: rwx, Group: x only, Other: r only"

# Show final ls -l output
echo "=== Final ls -l output ==="
ls -l | grep -E "(executefile.sh|cantedit.sh|owneronly.txt|mixrights.txt)" | sort -k9 
