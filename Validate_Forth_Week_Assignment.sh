#!/bin/bash

# DNS Server Configuration Validation Script
# For Week 4 Assignment - Caching DNS Server

echo "================================================"
echo "DNS Server Assignment Validation Script"
echo "================================================"
echo ""

# Function to check if a service is running
check_service() {
    local service_name=$1
    if pgrep -x "$service_name" > /dev/null; then
        echo "✓ $service_name is running"
        return 0
    else
        echo "✗ $service_name is not running"
        return 1
    fi
}

# Function to check if a service is installed
check_service_installed() {
    local service_name=$1
    if which "$service_name" > /dev/null 2>&1 || command -v "$service_name" > /dev/null 2>&1; then
        echo "✓ $service_name is installed"
        return 0
    else
        echo "✗ $service_name is not installed"
        return 1
    fi
}

# Function to test DNS resolution
test_dns_resolution() {
    local dns_server=$1
    local test_domain="google.com"
    
    echo ""
    echo "Testing DNS resolution for $test_domain via $dns_server..."
    
    # Check if dig is available
    if ! command -v dig &> /dev/null; then
        echo "✗ dig command not found. Please install bind-tools or dnsutils."
        return 1
    fi
    
    # Perform DNS query
    result=$(dig @"$dns_server" "$test_domain" +short +time=3 +tries=2 2>/dev/null)
    
    if [ -n "$result" ]; then
        echo "✓ DNS resolution successful"
        echo "  Resolved $test_domain to: $result"
        return 0
    else
        echo "✗ DNS resolution failed"
        return 1
    fi
}

# Get network interfaces information
echo "=== Network Interface Configuration ==="
if command -v ifconfig &> /dev/null; then
    ifconfig
elif command -v ip &> /dev/null; then
    ip addr show
else
    echo "No network tools found to display interface configuration"
fi

echo ""
echo "=== Checking System Information ==="
# Detect OS
if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "OS: $PRETTY_NAME"
else
    echo "OS: Unknown (cannot determine from /etc/os-release)"
fi

# Get server IP addresses
echo ""
echo "=== Server IP Addresses ==="
if command -v ip &> /dev/null; then
    ip addr show | grep -E "inet (192\.168|10\.|172\.)" | awk '{print "IP: "$2" Interface: "$NF}'
else
    ifconfig | grep -E "inet (192\.168|10\.|172\.)" | awk '{print "IP: "$2}'
fi

echo ""
echo "=== DNS Services Check ==="

# Check for BIND
bind_installed=false
bind_running=false
if check_service_installed "named"; then
    bind_installed=true
    check_service "named" && bind_running=true
fi

# Check for Unbound
unbound_installed=false
unbound_running=false
if check_service_installed "unbound"; then
    unbound_installed=true
    check_service "unbound" && unbound_running=true
fi

echo ""
echo "=== Service Status Summary ==="
if [ "$bind_installed" = true ] && [ "$unbound_installed" = true ]; then
    echo "⚠ Both BIND and Unbound are installed"
    if [ "$bind_running" = true ] && [ "$unbound_running" = true ]; then
        echo "✗ ERROR: Both BIND and Unbound are running simultaneously!"
        echo "  Only one DNS server should run at a time."
    elif [ "$bind_running" = true ]; then
        echo "✓ Only BIND is running (correct configuration)"
    elif [ "$unbound_running" = true ]; then
        echo "✓ Only Unbound is running (correct configuration)"
    else
        echo "✗ Neither BIND nor Unbound is running"
    fi
elif [ "$bind_installed" = true ]; then
    if [ "$bind_running" = true ]; then
        echo "✓ BIND is installed and running"
    else
        echo "✗ BIND is installed but not running"
    fi
elif [ "$unbound_installed" = true ]; then
    if [ "$unbound_running" = true ]; then
        echo "✓ Unbound is installed and running"
    else
        echo "✗ Unbound is installed but not running"
    fi
else
    echo "✗ Neither BIND nor Unbound is installed"
fi

echo ""
echo "=== DNS Server Validation ==="

# Get the server's main IP address for testing
if command -v ip &> /dev/null; then
    SERVER_IP=$(ip route get 1 | awk '{print $7; exit}')
else
    SERVER_IP=$(ifconfig | grep -E "inet (192\.168|10\.|172\.)" | head -1 | awk '{print $2}')
fi

if [ -z "$SERVER_IP" ]; then
    echo "✗ Could not determine server IP address"
    exit 1
fi

echo "Testing DNS server on IP: $SERVER_IP"

# Perform DNS resolution test
test_dns_resolution "$SERVER_IP"
DNS_TEST_RESULT=$?

echo ""
echo "=== Assignment Completion Status ==="
if [ $DNS_TEST_RESULT -eq 0 ]; then
    if { [ "$bind_installed" = true ] && [ "$bind_running" = true ] && [ "$unbound_running" = false ]; } || \
       { [ "$unbound_installed" = true ] && [ "$unbound_running" = true ] && [ "$bind_running" = false ]; }; then
        echo "✅ SUCCESS: Assignment completed correctly!"
        echo "   - DNS server is running and responding to queries"
        echo "   - Only one DNS service is active"
        echo ""
        echo "=== Final Validation Output ==="
        echo "Running: dig @$SERVER_IP google.com"
        echo ""
        dig @"$SERVER_IP" google.com
    else
        echo "⚠ PARTIAL: DNS responds but service configuration may be incorrect"
        echo "   Make sure only one DNS service is running at a time"
    fi
else
    echo "❌ FAILED: DNS server is not responding correctly"
    echo "   Please check your DNS server configuration"
fi

echo ""
echo "================================================"
echo "Validation completed"
echo "================================================" 
