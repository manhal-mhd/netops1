#!/bin/bash
#
# Validate_Forth_Week_Assignment.sh
# Ubuntu Caching DNS Server Validation Script (using service commands)
# Fixed to ignore zombie processes
#
# Usage: sudo bash Validate_Forth_Week_Assignment.sh
#
set -euo pipefail

echo "================================================"
echo "Caching DNS Server Validation Script (Ubuntu)"
echo "================================================"
echo ""

# Helper: print a heading
h() { echo ""; echo "=== $* ==="; }

# Detect available commands
command -v ip >/dev/null 2>&1 && HAVE_IP=true || HAVE_IP=false
command -v ifconfig >/dev/null 2>&1 && HAVE_IFCONFIG=true || HAVE_IFCONFIG=false
command -v dig >/dev/null 2>&1 && HAVE_DIG=true || HAVE_DIG=false
command -v service >/dev/null 2>&1 && HAVE_SERVICE=true || HAVE_SERVICE=false

h "System Information"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $PRETTY_NAME"
else
    echo "OS: Unknown"
fi
echo "Kernel: $(uname -r)"
echo "Init system: $(ps -p 1 -o comm= 2>/dev/null || echo "unknown")"
echo ""

h "Network Interfaces"
if $HAVE_IP; then
    ip addr show | grep -E "inet (10\.|172\.|192\.168|169\.254)" || echo "No private IP addresses found via ip command"
elif $HAVE_IFCONFIG; then
    ifconfig | grep -E "inet (addr:)?(10\.|172\.|192\.168|169\.254)" || echo "No private IP addresses found via ifconfig"
else
    echo "No ip/ifconfig command found"
fi

# Functions to check service status (using service command)
is_service_running() {
    local service_name=$1
    
    # Method 1: Use service command (most reliable)
    if $HAVE_SERVICE; then
        if service "$service_name" status 2>/dev/null | grep -q "running"; then
            return 0
        fi
    fi
    
    return 1
}

# Improved process detection that ignores zombie processes
is_process_running() {
    local name=$1
    
    # Use ps to check for running (not zombie) processes
    # Exclude defunct/zombie processes and only show running processes
    if ps -eo pid,state,comm | grep -v grep | grep -w "$name" | grep -vq "Z"; then
        return 0
    fi
    
    # Alternative method using pgrep (if available)
    if command -v pgrep >/dev/null 2>&1; then
        # pgrep by default only shows running processes
        if pgrep -x "$name" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    return 1
}

is_package_installed() {
    local pkg=$1
    if command -v dpkg >/dev/null 2>&1; then
        dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" && return 0
    fi
    return 1
}

# Function to check for zombie processes
check_zombie_processes() {
    echo "Zombie processes check:"
    local zombies=0
    
    if ps -eo pid,state,comm | grep -w "named" | grep -q "Z"; then
        echo "⚠️  Zombie named process detected"
        ((zombies++))
    fi
    
    if ps -eo pid,state,comm | grep -w "unbound" | grep -q "Z"; then
        echo "⚠️  Zombie unbound process detected"
        ((zombies++))
    fi
    
    if [ $zombies -eq 0 ]; then
        echo "✅ No zombie DNS processes"
    fi
}

h "Checking DNS Services"

# Check for zombie processes first
check_zombie_processes

# Check BIND
bind_installed=false
bind_running=false
if is_package_installed "bind9" || command -v named >/dev/null 2>&1; then
    bind_installed=true
fi
if is_service_running "bind9" || is_process_running "named"; then
    bind_running=true
fi
echo "BIND (bind9): installed=$bind_installed, running=$bind_running"

# Check Unbound
unbound_installed=false
unbound_running=false
if is_package_installed "unbound" || command -v unbound >/dev/null 2>&1; then
    unbound_installed=true
fi
if is_service_running "unbound" || is_process_running "unbound"; then
    unbound_running=true
fi
echo "Unbound: installed=$unbound_installed, running=$unbound_running"

# Check if services are managed by service command
h "Service Command Status"
for service in bind9 unbound; do
    if $HAVE_SERVICE; then
        echo -n "$service: "
        if service "$service" status >/dev/null 2>&1; then
            service "$service" status 2>/dev/null | head -1 || echo "service exists but status unavailable"
        else
            echo "not managed by service command"
        fi
    fi
done

h "Determining Server IP Address"
SERVER_IP=""

# Method 1: Use ip command to find private IP
if $HAVE_IP; then
    SERVER_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1)
    if [ -n "$SERVER_IP" ]; then
        echo "Found via ip route: $SERVER_IP"
    fi
fi

# Method 2: Find first private IP from ip addr
if [ -z "$SERVER_IP" ] && $HAVE_IP; then
    SERVER_IP=$(ip -4 addr show scope global 2>/dev/null | grep -E "inet (10\.|172\.|192\.168)" | awk '{print $2}' | head -n1 | cut -d/ -f1)
    if [ -n "$SERVER_IP" ]; then
        echo "Found private IP via ip addr: $SERVER_IP"
    fi
fi

# Method 3: Fallback to ifconfig
if [ -z "$SERVER_IP" ] && $HAVE_IFCONFIG; then
    SERVER_IP=$(ifconfig 2>/dev/null | grep -E "inet (addr:)?(10\.|172\.|192\.168)" | awk '{print $2}' | head -n1 | sed 's/addr://')
    if [ -n "$SERVER_IP" ]; then
        echo "Found via ifconfig: $SERVER_IP"
    fi
fi

# Final fallback: ask user
if [ -z "$SERVER_IP" ]; then
    echo "❌ Could not automatically determine server IP address"
    echo ""
    echo "Please provide your server's IP address (not 127.0.0.1):"
    read -r SERVER_IP
    if [[ ! $SERVER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address format"
        exit 1
    fi
else
    echo "✅ Detected server IP: $SERVER_IP"
fi

# Allow IP override via command line
if [ $# -ge 1 ] && [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    SERVER_IP="$1"
    echo "Using command line IP: $SERVER_IP"
fi

h "Checking Port 53 Listeners"
echo "UDP listeners on port 53:"
if command -v ss >/dev/null 2>&1; then
    ss -ulpn | grep ':53' | head -10 || echo "No UDP listeners on port 53"
else
    netstat -ulnp 2>/dev/null | grep ':53' | head -10 || echo "No UDP listeners on port 53 found"
fi

echo ""
echo "TCP listeners on port 53:"
if command -v ss >/dev/null 2>&1; then
    ss -tlnp | grep ':53' | head -10 || echo "No TCP listeners on port 53"
else
    netstat -tlnp 2>/dev/null | grep ':53' | head -10 || echo "No TCP listeners on port 53 found"
fi

h "Testing DNS Resolution"
test_dns_resolution() {
    local dns_server=$1
    local domain="google.com"

    echo ""
    echo "Testing: dig @$dns_server $domain"
    
    if ! $HAVE_DIG; then
        echo "❌ dig command not found. Install with: sudo apt update && sudo apt install -y dnsutils"
        return 2
    fi

    # Run dig and capture output
    local dig_output
    dig_output=$(dig @"$dns_server" "$domain" +time=3 +tries=2 2>&1)
    
    # Check if we got a response
    if echo "$dig_output" | grep -q "status: NOERROR"; then
        echo "✅ DNS Status: NOERROR"
        
        # Extract and show answer section
        local answers
        answers=$(echo "$dig_output" | awk '/ANSWER SECTION:/{flag=1; next} /^$/{flag=0} flag')
        if [ -n "$answers" ]; then
            echo "✅ Answer Section:"
            echo "$answers" | sed 's/^/  /'
            return 0
        else
            echo "❌ No answers in response"
            return 1
        fi
    else
        echo "❌ DNS query failed"
        echo "Full dig output:"
        echo "$dig_output"
        return 1
    fi
}

# Run the DNS test
if test_dns_resolution "$SERVER_IP"; then
    DNS_RESULT=0
    echo "✅ DNS resolution test PASSED"
else
    DNS_RESULT=1
    echo "❌ DNS resolution test FAILED"
fi

h "Service Status Summary"
echo "BIND running: $bind_running"
echo "Unbound running: $unbound_running"

# Count running DNS services
running_count=0
[[ $bind_running == true ]] && ((running_count++))
[[ $unbound_running == true ]] && ((running_count++))

h "Final Validation Result"

if [ $DNS_RESULT -eq 0 ]; then
    if [ $running_count -eq 1 ]; then
        echo "🎉 SUCCESS: Assignment completed correctly!"
        echo ""
        echo "✅ DNS server at $SERVER_IP is responding to queries"
        echo "✅ Status: NOERROR (successful resolution)"
        echo "✅ Only one DNS service running"
        if [[ $bind_running == true ]]; then
            echo "✅ BIND is running as caching DNS server"
        else
            echo "✅ Unbound is running as caching DNS server"
        fi
        echo ""
        echo "=== Final verification output ==="
        dig @"$SERVER_IP" google.com +noall +answer +comments
        exit 0
    elif [ $running_count -eq 0 ]; then
        echo "⚠️  WARNING: DNS responds but no main DNS service detected"
        echo "   - Another process might be handling DNS queries"
        exit 2
    else
        echo "⚠️  WARNING: DNS works but multiple services detected"
        echo "   - Stop all but one DNS service (BIND OR Unbound)"
        exit 3
    fi
else
    echo "❌ FAILED: DNS server not working correctly"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check if DNS service is actually running (not zombie):"
    echo "   ps -eo pid,state,comm | grep -E '(named|unbound)'"
    echo "2. Install and configure a DNS server:"
    echo "   sudo apt update && sudo apt install -y unbound"
    echo "3. Check service status:"
    echo "   sudo service unbound status"
    echo "4. Verify service is listening on $SERVER_IP:53"
    echo "5. Check logs:"
    echo "   sudo tail -20 /var/log/syslog"
    exit 1
fi 
