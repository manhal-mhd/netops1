#!/usr/local/bin/bash
FILE="rc.conf"

echo "=== Validating rc.conf Tasks ==="

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "❌ ERROR: File $FILE not found!"
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
line97=$(sed -n '97p' "$FILE" 2>/dev/null)

if [ -n "$line97" ]; then
    if echo "$line97" | grep -q "^\*\+$"; then
        echo "✅ PASS (Line 97 contains: $line97)"
    else
        echo "❌ FAIL - Line 97 should contain only asterisks, but contains: '$line97'"
    fi
else
    echo "❌ FAIL - Line 97 doesn't exist or is empty"
fi

# Bonus: Check if original words still exist (common mistakes)
echo ""
echo "=== Bonus Checks ==="

if grep -q "firewall" "$FILE"; then
    count=$(grep -c "firewall" "$FILE")
    echo "⚠️  WARNING: $count occurrence(s) of 'firewall' still exist - should be replaced with 'tree'"
fi

if grep -q "jail" "$FILE"; then
    count=$(grep -c "jail" "$FILE")
    echo "⚠️  WARNING: $count occurrence(s) of 'jail' still exist - should be replaced with 'warden'"
fi

echo ""
echo "=== Summary ==="
if grep -q "tree" "$FILE" && grep -q "warden" "$FILE" && sed -n '97p' "$FILE" 2>/dev/null | grep -q "^\*\+$"; then
    echo "🎉 ALL TASKS COMPLETED SUCCESSFULLY!"
else
    echo "📝 Some tasks need attention (see failures above)"
fi
