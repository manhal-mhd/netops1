#!/bin/bash
FILE="rc.conf"

echo "=== Validating rc.conf Tasks ==="

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "❌ ERROR: File $FILE not found!"
    echo "Please make sure rc.conf is in the current directory: $(pwd)"
    exit 1
fi

# Task 1: Check if 'tree' replacements exist
echo -n "Task 1 (firewall → tree): "
if grep -q "tree" "$FILE"; then
    count=$(grep -c "tree" "$FILE")
    echo "✅ PASS ($count occurrences of 'tree')"
else
    echo "❌ FAIL - No 'tree' replacements found"
fi

# Task 2: Check if 'warden' replacements exist  
echo -n "Task 2 (jail → warden): "
if grep -q "warden" "$FILE"; then
    count=$(grep -c "warden" "$FILE")
    echo "✅ PASS ($count occurrences of 'warden')"
else
    echo "❌ FAIL - No 'warden' replacements found"
fi

# Task 3: Check line 97 for asterisks
echo -n "Task 3 (line 97 asterisks): "
# Check if file has at least 97 lines
total_lines=$(wc -l < "$FILE")
if [ "$total_lines" -lt 97 ]; then
    echo "❌ FAIL - File only has $total_lines lines (need at least 97)"
else
    line97=$(sed -n '97p' "$FILE" 2>/dev/null)

    if [ -n "$line97" ]; then
        # Check if line contains only asterisks
        if [[ "$line97" =~ ^\*+$ ]]; then
            echo "✅ PASS (Line 97 contains: '$line97')"
        else
            echo "❌ FAIL - Line 97 should contain only asterisks, but contains: '$line97'"
        fi
    else
        echo "❌ FAIL - Line 97 is empty"
    fi
fi

# Bonus: Check if original words still exist (common mistakes)
echo ""
echo "=== Bonus Checks ==="

if grep -q "firewall" "$FILE"; then
    count=$(grep -c "firewall" "$FILE")
    echo "⚠️  WARNING: $count occurrence(s) of 'firewall' still exist - should be replaced with 'tree'"
else
    echo "✅ No 'firewall' references found"
fi

if grep -q "jail" "$FILE"; then
    count=$(grep -c "jail" "$FILE")
    echo "⚠️  WARNING: $count occurrence(s) of 'jail' still exist - should be replaced with 'warden'"
else
    echo "✅ No 'jail' references found"
fi

echo ""
echo "=== Summary ==="
# Check all conditions for success
task1_pass=$(grep -q "tree" "$FILE" && echo "true")
task2_pass=$(grep -q "warden" "$FILE" && echo "true")
task3_pass=$([ "$total_lines" -ge 97 ] && sed -n '97p' "$FILE" 2>/dev/null | grep -q "^\*\+$" && echo "true")

if [ "$task1_pass" ] && [ "$task2_pass" ] && [ "$task3_pass" ]; then
    echo "🎉 ALL TASKS COMPLETED SUCCESSFULLY!"
    exit 0
else
    echo "📝 Some tasks need attention (see failures above)"
    exit 1
fi 
